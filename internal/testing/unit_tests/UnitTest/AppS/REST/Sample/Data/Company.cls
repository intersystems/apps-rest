/// Use or operation of this code is subject to acceptance of the license available in the code repository for this code.
/// This sample persistent class represents a company.<br>
Class UnitTest.AppS.REST.Sample.Data.Company Extends (%Persistent, %Populate, %XML.Adaptor, %JSON.Adaptor)
{

/// Define an index for <property>Name</property>.
Index NameIdx On Name [ Type = index ];

/// Define a unique index for <property>TaxID</property>.
Index TaxIDIdx On TaxID [ Type = index, Unique ];

/// The company's name.
Property Name As %String(MAXLEN = 80, POPSPEC = "Company()") [ Required ];

/// The company's mission statement.
Property Mission As %String(MAXLEN = 200, POPSPEC = "Mission()");

/// The unique Tax ID number for the company.
Property TaxID As %String [ Required ];

/// The last reported revenue for the company.
Property Revenue As %Integer;

/// The <class>Employee</class> objects associated with this <class>Company</class>.
Relationship Employees As UnitTest.AppS.REST.Sample.Data.Employee [ Cardinality = many, Inverse = Company ];

Storage Default
{
<Data name="CompanyDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Mission</Value>
</Value>
<Value name="4">
<Value>TaxID</Value>
</Value>
<Value name="5">
<Value>Revenue</Value>
</Value>
</Data>
<DataLocation>^UnitTest.AppS.REST3D03.CompanyD</DataLocation>
<DefaultData>CompanyDefaultData</DefaultData>
<IdLocation>^UnitTest.AppS.REST3D03.CompanyD</IdLocation>
<IndexLocation>^UnitTest.AppS.REST3D03.CompanyI</IndexLocation>
<StreamLocation>^UnitTest.AppS.REST3D03.CompanyS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
