/// Use or operation of this code is subject to acceptance of the license available in the code repository for this code.
/// This is a sample embeddable class representing an address.
Class UnitTest.AppS.REST.Sample.Data.Address Extends (%SerialObject, %Populate, %XML.Adaptor, %JSON.Adaptor)
{

/// The street address.
Property Street As %String(MAXLEN = 80, POPSPEC = "Street()");

/// The city name.
Property City As %String(MAXLEN = 80, POPSPEC = "City()");

/// The 2-letter state abbreviation.
Property State As %String(MAXLEN = 2, POPSPEC = "USState()");

/// The 5-digit U.S. Zone Improvement Plan (ZIP) code.
Property Zip As %String(MAXLEN = 5, POPSPEC = "USZip()");

Storage Default
{
<Data name="AddressState">
<Value name="1">
<Value>Street</Value>
</Value>
<Value name="2">
<Value>City</Value>
</Value>
<Value name="3">
<Value>State</Value>
</Value>
<Value name="4">
<Value>Zip</Value>
</Value>
</Data>
<State>AddressState</State>
<StreamLocation>^UnitTest.AppS.REST3D03.AddressS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
