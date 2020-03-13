/// This class is internal to AppS.REST; consumers should not use or reference it directly.
Class AppS.REST.ResourceMap Extends %Persistent [ System = 3 ]
{

Index IDKEY On (ResourceName, MediaType) [ IdKey ];

Index ModelClass On ModelClass [ Unique ];

Property ResourceName As %String(MAXLEN = 128);

Property MediaType As %String(MAXLEN = 128);

Property ModelClass As %Dictionary.CacheClassname;

Storage Default
{
<Data name="ResourceMapDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ModelClass</Value>
</Value>
</Data>
<DataLocation>^AppS.REST.ResourceMapD</DataLocation>
<DefaultData>ResourceMapDefaultData</DefaultData>
<IdLocation>^AppS.REST.ResourceMapD</IdLocation>
<IndexLocation>^AppS.REST.ResourceMapI</IndexLocation>
<StreamLocation>^AppS.REST.ResourceMapS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
