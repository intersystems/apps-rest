Class Sample.Phonebook.Data.PhoneNumber Extends (%Persistent, %Populate, %JSON.Adaptor)
{

Relationship Person As Sample.Phonebook.Data.Person(%JSONINCLUDE = "none") [ Cardinality = parent, Inverse = PhoneNumbers ];

Property RowID As %String(%JSONFIELDNAME = "_id", %JSONINCLUDE = "outputonly") [ Calculated, SqlComputeCode = {Set {*} = {%%ID}}, SqlComputed, Transient ];

Property PhoneNumber As %String(%JSONFIELDNAME = "number", POPSPEC = "USPhone()");

Property Type As %String(%JSONFIELDNAME = "type", VALUELIST = ",Mobile,Home,Office");

XData PhoneNumberWithPerson [ XMLNamespace = "http://www.intersystems.com/jsonmapping" ]
{
<Mapping xmlns="http://www.intersystems.com/jsonmapping">
<Property Name="Person" FieldName="person" Include="inputonly" Reference="ID" />
<Property Name="RowID" FieldName="_id" Include="outputonly" />
<Property Name="PhoneNumber" FieldName="number" />
<Property Name="Type" FieldName="type" />
</Mapping>
}

Storage Default
{
<Data name="PhoneNumberDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>PhoneNumber</Value>
</Value>
<Value name="3">
<Value>Type</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("PhoneNumbers")</DataLocation>
<DefaultData>PhoneNumberDefaultData</DefaultData>
<IdLocation>^Sample.Phonebook.Data.PersonC("PhoneNumbers")</IdLocation>
<IndexLocation>^Sample.Phonebo6771.PhoneNumberI</IndexLocation>
<StreamLocation>^Sample.Phonebo6771.PhoneNumberS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
