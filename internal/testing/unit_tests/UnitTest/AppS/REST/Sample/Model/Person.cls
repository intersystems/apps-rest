Class UnitTest.AppS.REST.Sample.Model.Person Extends AppS.REST.Model.Proxy [ DependsOn = UnitTest.AppS.REST.Sample.Data.Person ]
{

/// The class to which this class provides REST access. It must extend %Persistent and have its %JSONENABLED class parameter set to 1 (e.g., by extending %JSON.Adaptor).
/// Subclasses must override this parameter.
Parameter SOURCECLASS As STRING = "UnitTest.AppS.REST.Sample.Data.Person";

/// The JSON mapping of the related JSON-enabled class to use.
/// Defaults to empty (the default mapping for the associated class).
Parameter JSONMAPPING As STRING = "LimitedInfo";

/// Name of the resource at the REST level
/// Subclasses MUST override this
Parameter RESOURCENAME As STRING = "person";

/// Permits READ and QUERY access only.
ClassMethod CheckPermission(pID As %String, pOperation As %String, pUserContext As UnitTest.AppS.REST.Sample.UserContext) As %Boolean
{
	If pUserContext.IsAdmin {
		// An admin can do anything.
		Quit 1
	}	
	If (pUserContext.Username = ##class(UnitTest.AppS.REST.Sample.Data.Person).UsernameGetStored(pID)) {
		// The current user can do anything to their own record except delete it.
		Quit (pOperation '= "DELETE")
	}
	Quit (pOperation = "READ") || (pOperation = "QUERY")
}

/// Defines a mapping of actions available for this model class to the associated methods and arguments.
XData ActionMap [ XMLNamespace = "http://www.intersystems.com/apps/rest/action" ]
{
<actions xmlns="http://www.intersystems.com/apps/rest/action">
<!-- Class query ByName in UnitTest.AppS.REST.Sample.Data.Person, but projected as this model class (LimitedInfo). -->
<action name="list-by-name" target="class" method="GET" query="UnitTest.AppS.REST.Sample.Data.Person:ByName"
modelClass="UnitTest.AppS.REST.Sample.Model.Person">
<argument name="name" target="name" />
</action>

<!-- Could also make name required: -->
<action name="alt-list-by-name" method="GET" query="UnitTest.AppS.REST.Sample.Data.Person:ByName"
modelClass="UnitTest.AppS.REST.Sample.Model.Person">
<argument name="name" target="name" required="true" />
</action>

<!-- Updates a person's home address -->
<action name="update-home-address" method="PUT" target="instance" call="UpdateHomeAddress">
<argument name="id" target="pID" source="id" />
<argument name="address" target="pAddress" source="body" />
</action>

<!-- Updates a person's office address -->
<action name="update-office-address" method="POST" target="instance"
call="UnitTest.AppS.REST.Sample.Model.Person:UpdateOfficeAddress">
<!-- Note above, can also include class name in call attribute. -->
<argument name="id" target="pID" source="id" />
<argument name="address" target="pAddress" source="body" />
</action>

<!-- Can also use raw dynamic objects for automatic serialization/deserialization, but types are recommended. -->
<action name="ping" method="POST" call="Ping">
<argument name="whatever" source="body" target="pObject" />
</action>
</actions>
}

ClassMethod UpdateHomeAddress(pID As %String, pAddress As UnitTest.AppS.REST.Sample.Data.Address) As UnitTest.AppS.REST.Sample.Data.Address
{
	Set person = ##class(UnitTest.AppS.REST.Sample.Data.Person).%OpenId(pID,,.sc)
	$$$ThrowOnError(sc)
	Set person.Home = pAddress
	$$$ThrowOnError(person.%Save())
	Quit person.Home
}

ClassMethod UpdateOfficeAddress(pID As %String, pAddress As UnitTest.AppS.REST.Sample.Data.Address) As UnitTest.AppS.REST.Sample.Model.Person
{
	Set person = ##class(UnitTest.AppS.REST.Sample.Data.Person).%OpenId(pID,,.sc)
	$$$ThrowOnError(sc)
	Set person.Office = pAddress
	$$$ThrowOnError(person.%Save())
	Quit ..GetModelInstance(pID)
}

ClassMethod Ping(pObject As %DynamicAbstractObject) As %DynamicAbstractObject
{
	Quit pObject
}

Method %Id()
{
	// Workaround for needing more generic source="id" support.
	Quit ..%instance.%Id()
}

}
