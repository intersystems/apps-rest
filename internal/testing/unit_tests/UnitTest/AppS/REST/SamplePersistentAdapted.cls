Class UnitTest.AppS.REST.SamplePersistentAdapted Extends (%Persistent, AppS.REST.Model.Adaptor)
{

/// Name of the resource at the REST level
/// Subclasses MUST override this
Parameter RESOURCENAME As STRING = "unittest-sample-persistent-adapted";

Parameter JSONMAPPING As STRING = "FooBarMapping";

XData FooBarMapping [ XMLNamespace = "http://www.intersystems.com/jsonmapping" ]
{
<Mapping xmlns="http://www.intersystems.com/jsonmapping">
 <Property Name="Foo" FieldName="someField" />
 <Property Name="Bar" />
 <!-- Baz intentionally omitted. -->
 <Property Name="Another" Include="none" />
</Mapping>
}

Property Foo As %String [ SqlFieldName = FOO_NAME ];

Property Bar As %String;

Property Baz As %String;

Property Another As %String;

Storage Default
{
<Data name="SamplePersistentAdaptedDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Foo</Value>
</Value>
<Value name="3">
<Value>Bar</Value>
</Value>
<Value name="4">
<Value>Baz</Value>
</Value>
<Value name="5">
<Value>Another</Value>
</Value>
</Data>
<DataLocation>^UnitTest.A6B07.SamplePersiBF32D</DataLocation>
<DefaultData>SamplePersistentAdaptedDefaultData</DefaultData>
<IdLocation>^UnitTest.A6B07.SamplePersiBF32D</IdLocation>
<IndexLocation>^UnitTest.A6B07.SamplePersiBF32I</IndexLocation>
<StreamLocation>^UnitTest.A6B07.SamplePersiBF32S</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}
