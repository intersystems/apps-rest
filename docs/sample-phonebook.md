# AppS.REST Tutorial and Sample Application: Contact List

This document describes how to build a sample application with AppS.REST using a list of contacts and phone numbers as a motivating example.

## Installing the Sample

The final version of the sample described here is in /samples/phonebook under the repository root. To install this sample using the [Community Package Manager](https://github.com/intersystems-community/zpm), clone the apps-rest repo, note the path to /samples/phonebook on your local filesystem, then run via IRIS terminal / iris session:

```bash
zpm "load -dev -verbose /path/to/samples/phonebook"
```

This automatically configures a REST-enabled web application with the sample dispatch class and password authentication enabled. It also sets up some sample data.

## The Contact List Data Model

Suppose as a starting point the following data model in two simple ObjectScript classes, with storage definitions omitted for simplicity:

```ObjectScript
Class Sample.Phonebook.Model.Person Extends %Persistent
{

Property Name As %String;

Relationship PhoneNumbers As Sample.Phonebook.Model.PhoneNumber [ Cardinality = children, Inverse = Person ];

}

Class Sample.Phonebook.Model.PhoneNumber Extends %Persistent
{

Relationship Person As Sample.Phonebook.Model.Person [ Cardinality = parent, Inverse = PhoneNumbers ];

Property PhoneNumber As %String;

Property Type As %String(VALUELIST = ",Mobile,Home,Office");

}
```

That is: a person has a name and some number of phone numbers (which aren't much use independent of the related contact - hence a parent-child relationship). Each phone number has a type - either Mobile, Home, or Office.

We want to enable the following behavior against this data model via REST:

* A user should be able to list all contacts and their phone numbers.
* A user should be able to create a new contact or update a contact's name.
* A user should be able to add, remove, and update phone numbers for a contact.
* A user should be able to search by a string and find all contacts whose phone numbers contain that string (along with their phone numbers).

## Defining our REST Handler

The starting point for any REST API in InterSystems IRIS Data Platform is a "dispatch class" - a subclass of `%CSP.REST` that defines all of the available endpoints and associates them to their behavior. When using AppS.REST, this class instead extends `AppS.REST.Handler`. The simplest possible such class, assuming a REST API protected by IRIS password authentication, is:

```ObjectScript
Class Sample.Phonebook.REST.Handler Extends AppS.REST.Handler
{

ClassMethod AuthenticationStrategy() As %Dictionary.CacheClassname
{
    Quit ##class(AppS.REST.Authentication.PlatformBased).%ClassName(1)
}

ClassMethod GetUserResource(pFullUserInfo As %DynamicObject) As AppS.REST.Authentication.PlatformUser
{
    Quit ##class(AppS.REST.Authentication.PlatformUser).%New()
}

}
```

`AppS.REST.Authentication.PlatformUser` is just an object wrapper around `$Username` - an application with a more complex concept of the current user might extend this class and add more properties, such as the user's name or any application-specific user characteristics. An authentication strategy `AppS.REST.Authentication.PlatformBased` indicates that platform-level authentication options such as IRIS Password or Delegated authentication are used.

### Automating REST Application Configuration

It's easy to set up a REST application via the Management Portal > System Administration > Security > Web Applications, as described in the [IRIS documentation](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GREST_intro). If you're using the ObjectScript package manager, it's even easier - just add a CSPApplication element in your module.xml. For example [(full context here)](../samples/phonebook/module.xml):

```xml
<CSPApplication Name="/csp/phonebook-sample/api"
    Url="/csp/${namespace}/phonebook-sample/api"
    DispatchClass="Sample.Phonebook.REST.Handler"
    CookiePath="/csp/${namespace}/phonebook-sample"
    PasswordAuthEnabled="1"
    Path="/csp/phonebook-sample/api"
    Recurse="1"
    UnauthenticatedEnabled="0"
    Generated="true"/>
```

This creates a new web application, /csp/(namespace in which the module is installed)/phonebook-sample/api, with `Sample.Phonebook.REST.Handler` as its dispatch class. Throughout this demo we'll assume the USER namespace.

## JSON-enabling the Data Model

The first step in REST-enabling the data model is to extend `%JSON.Adaptor` in all relevant registered/persistent classes. For projection as JSON, our PascalCase property names look a little strange, and we can use `%JSON.Adaptor` features (property parameters) to make them better.

The JSON projection via %JSON.Adaptor doesn't include the Row ID, and that's handy to have, so we'll add it via some transient, calculated properties.

At this stage, the classes will look like:

```ObjectScript
Class Sample.Phonebook.Model.Person Extends (%Persistent, %JSON.Adaptor)
{

Parameter RESOURCENAME = "contact";

Property RowID As %String(%JSONFIELDNAME = "_id", %JSONINCLUDE = "outputonly") [ Calculated, SqlComputeCode = {Set {*} = {%%ID}}, SqlComputed, Transient ];

Property Name As %String(%JSONFIELDNAME = "name");

Relationship PhoneNumbers As Sample.Phonebook.Model.PhoneNumber(%JSONFIELDNAME = "phones", %JSONINCLUDE="outputonly", %JSONREFERENCE = "object") [ Cardinality = children, Inverse = Person ];

}


Class Sample.Phonebook.Model.PhoneNumber Extends (%Persistent, %JSON.Adaptor)
{

Relationship Person As Sample.Phonebook.Model.Person(%JSONINCLUDE = "none") [ Cardinality = parent, Inverse = PhoneNumbers ];

Property RowID As %String(%JSONFIELDNAME = "_id", %JSONINCLUDE = "outputonly") [ Calculated, SqlComputeCode = {Set {*} = {%%ID}}, SqlComputed, Transient ];

Property PhoneNumber As %String(%JSONFIELDNAME = "number");

Property Type As %String(%JSONFIELDNAME = "type", VALUELIST = ",Mobile,Home,Office");

}
```

The `%JSONFIELDNAME` value overrides the name of the property when projected to and from JSON. For contacts, `RowID` becomes `_id`, `Name` becomes `name`, and `PhoneNumbers` becomes `phones`. For phone numbers, `PhoneNumber` becomes `number` in JSON inputs and outputs, `Type` becomes `type`, and `RowID` becomes `_id`.

The `%JSONINCLUDE` value specifies how the property will be handled when projecting to and from JSON. `Name`, `PhoneNumbers`, `PhoneNumber` and `Type` have no `%JSONINCLUDE`, so they are projected normally. In the case of `RowID`, the value is "outputonly", meaning it can't be changed. In the case of `Person`, which is a relationship, we won't allow editing via the top-level object so we specify a value of "none".

Putting it all together, an instance of Person with one PhoneNumber will look like this when projected to JSON:

```JSON
{
    "_id": "1",
    "name": "Semmens,Valery X.",
    "phones": [{
        "_id": "1||199",
        "number": "965-226-3942",
        "type": "Home"
    }]
}
```

## REST-enabling the Contact Listing

Before getting started with REST, it's handy to have a REST client. There are lots of these out there - [Postman](https://www.postman.com/) and [Advanced REST Client](https://install.advancedrestclient.com/install) are perhaps some of the more well-known.

> Note: You can't just paste requests into your web browser because you need to set "Accepts" HTTP header to "application/json" before sending a request.

We have a data model that defines how to store data in the database, and how to project it into JSON format. Now we need to expose it via a REST API. There are 3 steps for each class that is REST-enabled:

1. Extend `AppS.REST.Model.Adaptor`
2. Define its REST endpoint via the `RESOURCENAME` parameter
3. Set permissions for the endpoint

### Extend `AppS.REST.Model.Adaptor`

To REST-enable the Person class to allow listing all of the people, first extend `AppS.REST.Model.Adaptor`:

```ObjectScript
Class Sample.Phonebook.Model.Person Extends (%Persistent, %Populate, %JSON.Adaptor, AppS.REST.Model.Adaptor)
```

### Define the REST endpoint

Next, override the `RESOURCENAME` parameter, specifying a name that, together with the base URL, will become the REST endpoint for the resource.

```ObjectScript
Parameter RESOURCENAME = "contact";
```

### Set permissions for the endpoint

Add a `CheckPermission` method to the class. For `Sample.Phonebook.REST.Model.PhoneNumber` we will only allow the QUERY operation.

`CheckPermission` takes the following input parameters:

* pID: an instance of String...
* pOperation: an instance of String...
* pUserContext: an instance of `AppS.REST.Authentication.PlatformUser` (the type returned by the `GetUserResource` method in `Sample.Phonebook.REST.Handler` - you can override this in the method in your model class (instead of leaving it as the default %RegisteredObject) to make your IDE more helpful.

```ObjectScript
/// Checks the user's permission for a particular operation on a particular record.
/// <var>pOperation</var> may be one of:
/// CREATE
/// READ
/// UPDATE
/// DELETE
/// QUERY
/// ACTION:<action name>
/// <var>pUserContext</var> is supplied by <method>GetUserContext</method>
ClassMethod CheckPermission(pID As %String, pOperation As %String, pUserContext As AppS.REST.Authentication.PlatformUser) As %Boolean
{
    Quit (pOperation = "QUERY")
}
```

Using your REST client (and the appropriate web server port for your IRIS instance), you can now make a GET request to /csp/user/phonebook-sample/api/contact to retrieve the full list of contacts.

> Important: Be sure to set "Accepts" header to "application/json" before sending the request.

## REST-enabling CRUD Operations

What about allowing *update* of contact names? From a coding perspective, all you need to do to allow contact creation and updates is to allow the CREATE and UPDATE actions. While we're at it, let's allow the READ operation as well. `CheckPermission` now looks like this:

```ObjectScript
ClassMethod CheckPermission(pID As %String, pOperation As %String, pUserContext As AppS.REST.Authentication.PlatformUser) As %Boolean
{
    Quit (pOperation = "QUERY") || (pOperation = "READ") || (pOperation = "CREATE") || (pOperation = "UPDATE")
}
```

Remember that the `%JSONINCLUDE` property parameters on `Sample.Phonebook.Model.Person` are set to `"outputonly"` on all but the `Name` property. In other words, if you specify `_id` and `phones` in JSON and pass it to `%JSONImport()` on an instance of `Sample.Phonebook.Model.Person`, those properties will just be ignored.

This is a feature - and it provides for security within the REST tooling provided by the Apps.REST framework. It is important to think about security in this way up-front, to make sure that there is no exposure for modification of data outside of the desired scope.

Our REST model is ready to accept updates.

### Try out the CRUD operations

From your REST client, try the following:

* Set the "Accept" header to "application/json"
* Set the "Content-Type" header to "application/json"
* `POST` a JSON body of `{"name":"Flintstone,Fred"}` to /csp/user/phonebook-sample/api/contact
* `PUT` a JSON body of `{"name":"Rubble,Barney"}` to /csp/user/phonebook-sample/api/contact/1
* `GET` /csp/user/phonebook-sample/api/contact/1 - you should see the result of the change you just made.

## REST-enabling Phone Number Operations

Extending `AppS.REST.Model.Adaptor` like we did on `Sample.Phonebook.Model.Person` is one of two ways to REST-enable access to data; it operates by inheritance (that is, you extend it to enable REST access to the class that extends it).

The other approach is to use `AppS.REST.Model.Proxy`. A Proxy implementation stands separately from the class of data being accessed. This is necessary if you need to provide multiple representations of the same data, and also may be preferable if you want to keep the REST aspects of permissions, actions, etc. separate from the persistent class. `RESOURCENAME` and `CheckPermission` are overridden as before, but the `SOURCECLASS` parameter must also be specified, pointing to a JSON-enabled persistent class. For example, to enable creation, update and deletion of phone numbers without making any further changes to `Sample.Phonebook.Model.PhoneNumber`, a proxy may be defined as follows:

```ObjectScript
Class Sample.Phonebook.REST.Model.PhoneNumber Extends AppS.REST.Model.Proxy
{

Parameter RESOURCENAME = "phone-number";

Parameter SOURCECLASS = "Sample.Phonebook.Model.PhoneNumber";

ClassMethod CheckPermission(pID As %String, pOperation As %String, pUserContext As AppS.REST.Authentication.PlatformUser) As %Boolean
{
    Quit (pOperation = "UPDATE") || (pOperation = "DELETE")
}

}
```

For example, this will allow a `PUT` of `{"number":"123-456-7890","type":"Office"}` to /csp/user/phonebook-sample/api/phone-number/1||199 (assuming 1||199 is a valid PhoneNumber ID), or a `DELETE` of that same URI.

Adding a new phone number is more complicated, though; the REST projection for phone numbers has `%JSONINCLUDE="none"` on the related `Person`. This is necessary to avoid infinite loops trying to project the set of objects to JSON for the main listing. There are two different approaches to solving this problem in the AppS.REST framework: "actions" and alternative JSON mappings.

### Adding a Phone Number via an Alternative JSON Mapping

`%JSON.Adaptor` supports creation of multiple JSON mappings, and AppS.REST can use this feature to handle multiple representations of the same resource. To start out, create an XData block in `Sample.Phonebook.Model.PhoneNumber` as follows:

```xml
XData PhoneNumberWithPerson [ XMLNamespace = "http://www.intersystems.com/jsonmapping" ]
{
<Mapping xmlns="http://www.intersystems.com/jsonmapping">
<Property Name="Person" FieldName="person" Include="inputonly" Reference="ID" />
<Property Name="RowID" FieldName="_id" Include="outputonly" />
<Property Name="PhoneNumber" FieldName="number" />
<Property Name="Type" FieldName="type" />
</Mapping>
}
```

The attribute names map to the property parameter names noted previously. The field names are the same as the basic mapping, with the addition of a "person" field mapping to the ID of the referenced person.

With this in place, and updating `CheckPermission` to also allow the `"CREATE"` operation, a JSON body like `{"number":"123-456-7890","type":"Office","person":1}` can be posted to /csp/user/phonebook-sample/api/phone-number to add a new phone number.

### Adding a Phone Number via an Action

Suppose a multi-tenant environment where each person only has access to a subset of contacts. In such a case, a user should not be allowed to update or delete phone numbers associated with another person's contacts. This is enforceable in `CheckPermissions` on the phone number model. But when adding a new contact, the validity of the data would depend on the JSON payload. While such checking is possible through more complicated mechanisms outside the scope of this tutorial, doing security checks there decentralizes the security checking and opens up the possibility of vulnerabilities.

Instead of viewing `"CREATE"` of a phone number for a contact as an action on the phone-number resource, it could be reimagined as an action that is taken on the contact. Security checking could live alongside that of the contact, and would be the same as for other operations on that contact. (The same could also apply for other operations on phone numbers.)

First, we'll create an instance method in `Sample.Phonebook.Model.Person` that takes an instance of `Sample.Phonebook.Model.PhoneNumber`, sets the Person for that phone number to the current instance, saves the phone number, and returns the current Person instance. This is very simple with ObjectScript:

```ObjectScript
Method AddPhoneNumber(phoneNumber As Sample.Phonebook.Model.PhoneNumber) As Sample.Phonebook.Model.Person
{
    Set phoneNumber.Person = $This
    $$$ThrowOnError(phoneNumber.%Save())
    Quit $This
}
```

Next, we'll define a new XData block called "ActionMap" in `Sample.Phonebook.Model.Person`, as follows:

```xml
XData ActionMap [ XMLNamespace = "http://www.intersystems.com/apps/rest/action" ]
{
<actions xmlns="http://www.intersystems.com/apps/rest/action">
<action name="add-phone" target="instance" method="POST" call="AddPhoneNumber">
<argument name="phoneNumber" target="phoneNumber" source="body" />
</action>
</actions>
}
```

This says that a POST request to /contact/(contact ID)/$add-phone will call the AddPhoneNumber of that instance, providing the automatically-deserialized phoneNumber object from the body (based on the argument type in the method signature) and responding with a JSON export of the updated instance of `Sample.Phonebook.Model.Person` (based on the return type in the method signature).

Now that the "add-phone" action has been defined, we must also enable access to it in CheckPermission:

```ObjectScript
ClassMethod CheckPermission(pID As %String, pOperation As %String, pUserContext As AppS.REST.Authentication.PlatformUser) As %Boolean
{
    Quit (pOperation = "QUERY") || (pOperation = "READ") || (pOperation = "CREATE") || (pOperation = "UPDATE") ||
        (pOperation = "ACTION:add-phone")
}
```

With all of this in place, a POST of `{"number":"123-456-7890","type":"Office"}` to /csp/user/phonebook-sample/api/contact/1/$add-phone will add that phone number to contact ID 1 and respond with the full contact details (including name and all phone numbers) for that contact.

## Query via REST

The final thing we want to expose in our REST API is a class query to search by phone number for a contact. This will again use an action in the `Person` class, along with a custom class query.

Let's define the class query first:

```ObjectScript
Query FindByPhone(phoneFragment As %String) As %SQLQuery
{
select distinct Person
from Sample_Phonebook_Model.PhoneNumber
where $Translate(PhoneNumber,' -+()') [ $Translate(:phoneFragment,' -+()')
}
```

This selects IDs of Person records (important!) that have an associated phone number containing some value, removing all punctuation characters on both the input fragment and the stored phone numbers.

This class query can be exposed via an action as follows:

```xml
<action name="find-by-phone" target="class" method="GET" query="FindByPhone">
    <argument name="phoneFragment" target="phoneFragment" source="url" />
</action>
```

This says that the "phoneFragment" URL parameter's value will be passed to the phoneFragment argument of the class query. The action name and target attach it to a `GET` request to /csp/user/phonebook-sample/api/contact/$find-by-phone. Of course, this also must be enabled in `CheckPermission`:

```ObjectScript
ClassMethod CheckPermission(pID As %String, pOperation As %String, pUserContext As AppS.REST.Authentication.PlatformUser) As %Boolean
{
    Quit (pOperation = "QUERY") || (pOperation = "READ") || (pOperation = "CREATE") || (pOperation = "UPDATE") ||
        (pOperation = "ACTION:add-phone") || (pOperation = "ACTION:find-by-phone")
}
```

And that's it! We now have a fully-functional REST API.

* A user can list all contacts and their phone numbers.
* A user can create a new contact or update a contact's name.
* A user can add, remove, and update phone numbers for a contact.
* A user can search by a string and find all contacts whose phone numbers contain that string (along with their phone numbers).

## Further reading

For a different perspective on AppS.REST, check out the [User Guide](user-guide.md).
