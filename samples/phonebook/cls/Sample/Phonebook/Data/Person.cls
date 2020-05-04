Class Sample.Phonebook.Data.Person Extends (%Persistent, %Populate, %JSON.Adaptor, AppS.REST.Model.Adaptor)
{

Parameter RESOURCENAME = "contact";

Property RowID As %String(%JSONFIELDNAME = "_id", %JSONINCLUDE = "outputonly") [ Calculated, SqlComputeCode = {Set {*} = {%%ID}}, SqlComputed, Transient ];

Property Name As %String(%JSONFIELDNAME = "name");

Relationship PhoneNumbers As Sample.Phonebook.Data.PhoneNumber(%JSONFIELDNAME = "phones", %JSONINCLUDE = "outputonly", %JSONREFERENCE = "object") [ Cardinality = children, Inverse = Person ];

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
	Quit (pOperation = "QUERY") || (pOperation = "READ") || (pOperation = "CREATE") || (pOperation = "UPDATE") ||
        (pOperation = "ACTION:add-phone") || (pOperation = "ACTION:find-by-phone")
}

Method AddPhoneNumber(phoneNumber As Sample.Phonebook.Data.PhoneNumber) As Sample.Phonebook.Data.Person
{
    Set phoneNumber.Person = $This
    $$$ThrowOnError(phoneNumber.%Save())
    Quit $This
}

Query FindByPhone(phoneFragment As %String) As %SQLQuery
{
select distinct Person
from Sample_Phonebook_Data.PhoneNumber
where $Translate(PhoneNumber,' -+()') [ $Translate(:phoneFragment,' -+()')
}

XData ActionMap [ XMLNamespace = "http://www.intersystems.com/apps/rest/action" ]
{
<actions xmlns="http://www.intersystems.com/apps/rest/action">
<action name="add-phone" target="instance" method="POST" call="AddPhoneNumber">
<argument name="phoneNumber" target="phoneNumber" source="body" />
</action>

<action name="find-by-phone" target="class" method="GET" query="FindByPhone">
<argument name="phoneFragment" target="phoneFragment" source="url" />
</action>
</actions>
}

Storage Default
{
<Data name="PersonDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
</Data>
<DataLocation>^Sample.Phonebook.Data.PersonD</DataLocation>
<DefaultData>PersonDefaultData</DefaultData>
<IdLocation>^Sample.Phonebook.Data.PersonD</IdLocation>
<IndexLocation>^Sample.Phonebook.Data.PersonI</IndexLocation>
<StreamLocation>^Sample.Phonebook.Data.PersonS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
