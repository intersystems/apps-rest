/// This class is internal to AppS.REST; consumers should not use or reference it directly.
Class AppS.REST.ActionMap Extends %Persistent [ System = 2 ]
{

Index UniqueByRequest On (ResourceName, ActionName, ActionTarget, HTTPVerb, MediaTypeOrNUL, AcceptsOrNUL) [ Unique ];

Index ModelClass On ModelClass;

Index ImplementationClass On ImplementationClass;

Property ResourceName As %String(MAXLEN = 128) [ Required ];

Property ActionName As %String(MAXLEN = 50) [ Required ];

Property ActionTarget As %String(MAXLEN = 8, VALUELIST = ",class,instance") [ Required ];

Property HTTPVerb As %String(VALUELIST = ",GET,POST,PUT,DELETE") [ Required ];

Property MediaType As %String(MAXLEN = 128);

Property MediaTypeOrNUL As %String [ Calculated, Required, SqlComputeCode = {Set {*} = $Case({MediaType},"":$c(0),:{MediaType})}, SqlComputed ];

Property Accepts As %String(MAXLEN = 128);

Property AcceptsOrNUL As %String [ Calculated, Required, SqlComputeCode = {Set {*} = $Case({Accepts},"":$c(0),:{Accepts})}, SqlComputed ];

Property ModelClass As %Dictionary.CacheClassname [ Required ];

Property ImplementationClass As %Dictionary.CacheClassname [ Required ];

Storage Default
{
<Data name="ActionMapDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ResourceName</Value>
</Value>
<Value name="3">
<Value>ActionName</Value>
</Value>
<Value name="4">
<Value>ActionTarget</Value>
</Value>
<Value name="5">
<Value>HTTPVerb</Value>
</Value>
<Value name="6">
<Value>MediaType</Value>
</Value>
<Value name="7">
<Value>Accepts</Value>
</Value>
<Value name="8">
<Value>ModelClass</Value>
</Value>
<Value name="9">
<Value>ImplementationClass</Value>
</Value>
</Data>
<DataLocation>^AppS.REST.ActionMapD</DataLocation>
<DefaultData>ActionMapDefaultData</DefaultData>
<IdLocation>^AppS.REST.ActionMapD</IdLocation>
<IndexLocation>^AppS.REST.ActionMapI</IndexLocation>
<StreamLocation>^AppS.REST.ActionMapS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
