/// Use or operation of this code is subject to acceptance of the license available in the code repository for this code.
/// The Vendor class is a persistent class 
/// containing vendor information.<br>
/// This class demonstrates how to use the %CacheSQLStorage storage 
/// class to provide custom storage for a persistent class. Typically the 
/// %CacheSQLStorage storage class is used to provide object access 
/// to previously existing storage structures.
Class UnitTest.AppS.REST.Sample.Data.Vendor Extends (%Persistent, %Populate, %XML.Adaptor, AppS.REST.Model.Adaptor) [ SqlRowIdName = Vendor, StorageStrategy = SQLStorage ]
{

/// REST resource name
Parameter RESOURCENAME = "vendor";

/// REST permissions: admins can create/delete/edit, anyone can query/read.
ClassMethod CheckPermission(pID As %String, pOperation As %String, pUserContext As UnitTest.AppS.REST.Sample.UserContext) As %Boolean
{
    If pUserContext.IsAdmin {
        Quit 1
    } Else {
	    Quit ((pOperation = "QUERY") || (pOperation = "READ"))
    }
}

/// Name Index
Index IndexNName On Name;

/// Vendor name.
Property Name As %String(POPSPEC = "Company()");

/// Vendor address.
Property Address As UnitTest.AppS.REST.Sample.Data.Address(POPSPEC = "##class(Address).PopulateSerial()");

/// Name of primary vendor contact.
Property Contact As %String(POPSPEC = "Name()");

/// Discount rate.
Property DiscRate As %Float(MAXVAL = 100, MINVAL = 0);

/// Discount days.
Property DiscDays As %Integer(MAXVAL = 999, MINVAL = 0);

/// Net days.
Property NetDays As %Integer(MAXVAL = 999, MINVAL = 0);

/// Days clear.
Property DaysClear As %Integer(MAXVAL = 999, MINVAL = 0);

/// Payment Flag
Property PayFlag As %String(DISPLAYLIST = ",Never,Minimum", VALUELIST = ",N,M");

/// Minimum Payment.
Property MinPayment As %Float(MAXVAL = 999999, MINVAL = 0);

/// Last Invoice Date.
Property LastInvDate As %Date(MAXVAL = "", MINVAL = "");

/// Last Payment Date.
Property LastPayDate As %Date(MAXVAL = "", MINVAL = "");

/// Balance.
Property Balance As %Float(MAXVAL = 999999999, MINVAL = -999999999) [ InitialExpression = 0 ];

/// Vendor tax reporting status.
Property TaxReporting As %String(DISPLAYLIST = ",Exempt,Required", VALUELIST = ",E,");

Storage SQLStorage
{
<ExtentSize>200</ExtentSize>
<Property name="%%ID">
<AverageFieldSize>2.46</AverageFieldSize>
<Selectivity>1</Selectivity>
</Property>
<Property name="Address">
<AverageFieldSize>36.42,City:7.26,State:2,Street:16.75,Zip:5</AverageFieldSize>
<Selectivity>0.5000%,City:3.8462%,State:2.0000%,Street:0.5000%,Zip:0.5000%</Selectivity>
</Property>
<Property name="Balance">
<AverageFieldSize>9.37</AverageFieldSize>
<Selectivity>0.5000%</Selectivity>
</Property>
<Property name="Contact">
<AverageFieldSize>15.99</AverageFieldSize>
<Selectivity>0.5000%</Selectivity>
</Property>
<Property name="DaysClear">
<AverageFieldSize>2.88</AverageFieldSize>
<Selectivity>0.5495%</Selectivity>
</Property>
<Property name="DiscDays">
<AverageFieldSize>2.93</AverageFieldSize>
<Selectivity>0.5464%</Selectivity>
</Property>
<Property name="DiscRate">
<AverageFieldSize>1.92</AverageFieldSize>
<Selectivity>1.0753%</Selectivity>
</Property>
<Property name="LastInvDate">
<AverageFieldSize>5</AverageFieldSize>
<Selectivity>0.5000%</Selectivity>
</Property>
<Property name="LastPayDate">
<AverageFieldSize>5</AverageFieldSize>
<Selectivity>0.5025%</Selectivity>
</Property>
<Property name="MinPayment">
<AverageFieldSize>5.92</AverageFieldSize>
<Selectivity>0.5000%</Selectivity>
</Property>
<Property name="Name">
<AverageFieldSize>17.22</AverageFieldSize>
<Selectivity>0.5076%</Selectivity>
</Property>
<Property name="NetDays">
<AverageFieldSize>2.86</AverageFieldSize>
<Selectivity>0.5618%</Selectivity>
</Property>
<Property name="PayFlag">
<AverageFieldSize>1</AverageFieldSize>
<Selectivity>50.0000%</Selectivity>
</Property>
<Property name="TaxReporting">
<AverageFieldSize>.54</AverageFieldSize>
<Selectivity>50.0000%</Selectivity>
</Property>
<SqlIdExpression>$i(^Sample.VendorD)</SqlIdExpression>
<SQLMap name="DataMasterMap">
<BlockCount>-16</BlockCount>
<Data name="Address">
<Piece>2</Piece>
</Data>
<Data name="Balance">
<Node>1</Node>
<Piece>3</Piece>
</Data>
<Data name="Contact">
<Piece>3</Piece>
</Data>
<Data name="DaysClear">
<Piece>7</Piece>
</Data>
<Data name="DiscDays">
<Piece>5</Piece>
</Data>
<Data name="DiscRate">
<Piece>4</Piece>
</Data>
<Data name="LastInvDate">
<Node>1</Node>
<Piece>1</Piece>
</Data>
<Data name="LastPayDate">
<Node>1</Node>
<Piece>2</Piece>
</Data>
<Data name="MinPayment">
<Piece>9</Piece>
</Data>
<Data name="Name">
<Piece>1</Piece>
</Data>
<Data name="NetDays">
<Piece>6</Piece>
</Data>
<Data name="PayFlag">
<Piece>8</Piece>
</Data>
<Data name="TaxReporting">
<Piece>10</Piece>
</Data>
<Global>^Sample.DataD</Global>
<Structure>list</Structure>
<Subscript name="1">
<Expression>{Vendor}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<SQLMap name="IndexNName">
<BlockCount>-4</BlockCount>
<Global>^Sample.VendorI</Global>
<Structure>list</Structure>
<Subscript name="1">
<Expression>"N"</Expression>
</Subscript>
<Subscript name="2">
<Expression>$$SQLUPPER({Name})</Expression>
</Subscript>
<Subscript name="3">
<Expression>{Vendor}</Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<StreamLocation>^Sample.VendorS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
