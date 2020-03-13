/// To keep the web application around after the test runs (for manual debugging):
/// <code>
/// zpm
/// apps.rest test -only -DUnitTest.Case=UnitTest.AppS.REST.DriveSample -DUnitTest.UserParam.KeepApplication=1 -verbose
/// </code>
Class UnitTest.AppS.REST.DriveSample Extends %UnitTest.TestCase
{

Property ForgeryInstalled As %Boolean [ InitialExpression = {$$$comClassDefined("Forgery.Agent")} ];

Property WebAppName As %String [ InitialExpression = {"/csp/"_$ZConvert($Namespace,"L")_"/unit-test/sample"} ];

Property Agent As %RegisteredObject;

Property Person As %DynamicAbstractObject;

Property Vendor As %DynamicAbstractObject;

Method OnBeforeAllTests() As %Status
{
    Set sc = $$$OK
    Set oldNamespace = $Namespace
    Try {
        // Generate data for tests
        Do ##class(UnitTest.AppS.REST.Sample.Data.Utils).Generate()

        New $Namespace
        Set $Namespace = "%SYS"
        Set props("NameSpace") = oldNamespace
        Set props("DispatchClass") = "UnitTest.AppS.REST.Sample.Handler"
        Set props("CookiePath") = ..WebAppName_"/"
        Set props("Recurse") = 1
        Set props("IsNameSpaceDefault") = 0
        Set props("AutheEnabled") = 32 // Password
        If ##class(Security.Applications).Exists(..WebAppName) {
            $$$ThrowOnError(##class(Security.Applications).Modify(..WebAppName, .props))
        } Else {
            $$$ThrowOnError(##class(Security.Applications).Create(..WebAppName, .props))
        }
    } Catch e {
        Set sc = e.AsStatus()
    }
    Quit sc
}

Method OnBeforeOneTest(testname As %String) As %Status
{
    Set ..SkipTest = (testname '= "TestCompiling") && '..ForgeryInstalled
    If ..SkipTest {
        Do $$$AssertSkipped("Must install the Forgery project from the Open Exchange to support running certain REST tests.")
    } Else {
        Set ..Agent = ##class(Forgery.Agent).%New(..WebAppName_"/", {
            "Content-Type": "application/json; charset=utf-8",
            "Accept": "application/json"
        })
    }
    Quit $$$OK
}

Method OnAfterAllTests() As %Status
{
    Set sc = $$$OK
    Set oldNamespace = $Namespace
    Try {
        If '..Manager.UserFields.GetAt("KeepApplication") {
            New $Namespace
            Set $Namespace = "%SYS"
            $$$ThrowOnError(##class(Security.Applications).Delete(..WebAppName))
        }
    } Catch e {
        Set sc = e.AsStatus()
    }
    Quit sc
}

Method TestAuthStatus()
{
    Do $$$AssertStatusOK(..Agent.Get({"url": "auth/status"}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "200 OK")
    Do $$$AssertEquals(response.ContentType, "application/json")
    Set object = {}.%FromJSON(jsonStream)
    Do $$$AssertEquals(object.Username,$Username)
    Do $$$AssertEquals(object.IsAdmin,(","_$Roles_",") [ ",%All,")
}

Method TestCompiling()
{
    Do $$$AssertStatusOK($System.OBJ.CompilePackage("UnitTest.AppS.REST.Sample", "ck/nomulticompile"))
}

Method TestPerson01Query()
{
    Do $$$AssertStatusOK(..Agent.Get({"url": "person?$orderBy=name"}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "200 OK")
    Do $$$AssertEquals(response.ContentType, "application/json")
    Set object = {}.%FromJSON(jsonStream)
    If '$$$AssertEquals(object.%Size(), 200) {
        Do $$$LogMessage("Response: "_object.%ToJSON())
    }
}

Method TestPerson02Get()
{
    Do $$$AssertStatusOK(..Agent.Get({"url": "person/1"}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "200 OK")
    Do $$$AssertEquals(response.ContentType, "application/json")
    Set object = {}.%FromJSON(jsonStream)
    Set ..Person = object
}

Method TestPerson03Put()
{
    Set ..Person.name = "Rubble, Barney"
    Do $$$AssertStatusOK(..Agent.Put({"url": "person/1", "data": (..Person)}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "200 OK")
    Do $$$AssertEquals(response.ContentType, "application/json")
    Set object = {}.%FromJSON(jsonStream)
    Do $$$AssertEquals(object.name, "Rubble, Barney")
}

Method TestPerson04Post()
{
    Do $$$AssertStatusOK(..Agent.Post({"url": "person", "data": {"name": "Flintstone, Fred"}}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "200 OK")
    Do $$$AssertEquals(response.ContentType, "application/json")
    Set object = {}.%FromJSON(jsonStream)
    Do $$$AssertEquals(object.name, "Flintstone, Fred")
}

Method TestPerson05ListByName()
{
    Do $$$AssertStatusOK(..Agent.Get({"url": "person/$list-by-name?name=Flintstone"}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "200 OK")
    Set object = {}.%FromJSON(jsonStream)
    Do $$$LogMessage("Response: "_object.%ToJSON())
    Do $$$AssertEquals(object.%Size(), 1)
}

Method TestPerson06UpdateHomeAddress()
{
    Do $$$AssertStatusOK(..Agent.Put({"url": "person/201/$update-home-address","data":{"Zip":"12345"}}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "200 OK")
    Set object = {}.%FromJSON(jsonStream)
    Do $$$LogMessage("Response: "_object.%ToJSON())
    Do $$$AssertEquals(object.Zip,"12345")
}

Method TestPerson07UpdateOfficeAddress()
{
    Do $$$AssertStatusOK(..Agent.Post({"url": "person/201/$update-office-address","data":{"Zip":"12345"}}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "200 OK")
    Set object = {}.%FromJSON(jsonStream)
    Do $$$LogMessage("Response: "_object.%ToJSON())
    Do $$$AssertEquals(object.name, "Flintstone, Fred")
    Do $$$AssertEquals(object."office_address".Zip, "12345")
}

Method TestPerson08Ping()
{
    Do $$$AssertStatusOK(..Agent.Post({"url": "person/$ping", "data": {"foo":"bar"}}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "200 OK")
    Set object = {}.%FromJSON(jsonStream)
    Do $$$LogMessage("Response: "_object.%ToJSON())
    Do $$$AssertEquals(object.foo, "bar")
}

Method TestPerson09Delete()
{
    Do $$$AssertStatusOK(..Agent.Delete({"url": "person/201"}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "204 No Content")
    Do $$$AssertStatusOK(..Agent.Delete({"url": "person/201"}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "404 Not Found")
}

Method TestVendor1Query()
{
    Do $$$AssertStatusOK(..Agent.Get({"url": "vendor"}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "200 OK")
    Do $$$AssertEquals(response.ContentType, "application/json")
    Set object = {}.%FromJSON(jsonStream)
    Do $$$AssertEquals(object.%Size(), 100)
}

Method TestVendor2Get()
{
    Do $$$AssertStatusOK(..Agent.Get({"url": "vendor/1"}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "200 OK")
    Do $$$AssertEquals(response.ContentType, "application/json")
    Set object = {}.%FromJSON(jsonStream)
    Set ..Vendor = object
}

Method TestVendor3Put()
{
    Set ..Vendor.Name = "Acme Pharmaceuticals"
    Do $$$AssertStatusOK(..Agent.Put({"url": "vendor/1", "data": (..Vendor)}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "200 OK")
    Do $$$AssertEquals(response.ContentType, "application/json")
    Set object = {}.%FromJSON(jsonStream)
    Do $$$AssertEquals(object.Name, "Acme Pharmaceuticals")
}

Method TestVendor4Post()
{
    Set ..Vendor.Name = "Acme Robotics"
    Do $$$AssertStatusOK(..Agent.Post({"url": "vendor", "data": (..Vendor)}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "200 OK")
    Do $$$AssertEquals(response.ContentType, "application/json")
    Set object = {}.%FromJSON(jsonStream)
    Do $$$AssertEquals(object.Name, "Acme Robotics")
}

Method TestVendor5Delete()
{
    Do $$$AssertStatusOK(..Agent.Delete({"url": "vendor/101"}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "204 No Content")
    Do $$$AssertStatusOK(..Agent.Delete({"url": "vendor/101"}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "404 Not Found")
}

Method TestVendor6Construct()
{
    Do $$$AssertStatusOK(..Agent.Get({"url": "vendor/$new"}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "200 OK")
    Set object = {}.%FromJSON(jsonStream)
    Do $$$LogMessage("Response: "_object.%ToJSON())
    Do $$$AssertEquals(object.%Size(),1)
}

Method TestBad01InvalidOrderBy()
{
    Do $$$AssertStatusOK(..Agent.Get({"url": "person?$orderBy=-SSN"}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "403 Unauthorized")
    Do $$$AssertEquals(response.ContentType, "application/json")
    Set object = {}.%FromJSON(jsonStream)
    Do $$$LogMessage("Response: "_object.%ToJSON())
    Do $$$AssertEquals(object.errors.%Get(0).params.%Get(0), "Invalid query. Access to column 'SSN' is not permitted.")
}

Method TestBad02MalformedFilter()
{
    Do $$$AssertStatusOK(..Agent.Get({"url": "person?name[foo]=Fred"}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "400 Bad Request")
    Do $$$AssertEquals(response.ContentType, "application/json")
    Set object = {}.%FromJSON(jsonStream)
    Do $$$LogMessage("Response: "_object.%ToJSON())
    Do $$$AssertEquals(object.errors.%Get(0).params.%Get(0), "Invalid query. The parameter value 'name[foo]=Fred' could not be parsed.")
}

Method TestBad03NoResource()
{
    Do $$$AssertStatusOK(..Agent.Get({"url": "vehicle"}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "406 Not Acceptable")
    Do $$$AssertEquals(response.ContentType, "application/json")

    Do $$$AssertStatusOK(..Agent.Get({"url": "vehicle/1"}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "406 Not Acceptable")
    Do $$$AssertEquals(response.ContentType, "application/json")

    Do $$$AssertStatusOK(..Agent.Put({"url": "vehicle/1", "data":{}}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "415 Unsupported Media Type")
    Do $$$AssertEquals(response.ContentType, "application/json")

    Do $$$AssertStatusOK(..Agent.Post({"url": "vehicle", "data":{}}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "415 Unsupported Media Type")
    Do $$$AssertEquals(response.ContentType, "application/json")

    Do $$$AssertStatusOK(..Agent.Delete({"url": "vehicle/1"}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "415 Unsupported Media Type")
    Do $$$AssertEquals(response.ContentType, "application/json")
}

Method TestBad04NoAction()
{
    Do $$$AssertStatusOK(..Agent.Get({"url": "person/1/$promote"}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "406 Not Acceptable")
}

Method TestBad05WrongActionMethod()
{
    Do $$$AssertStatusOK(..Agent.Post({"url": "person/1/$update-home-address","data":{"Zip":"12345"}}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "405 Method Not Allowed")
}

Method TestBad06MalformedJSON()
{
    // No "data"
    Do $$$AssertStatusNotOK(..Agent.Put({"url": "person/1"}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "400 Bad Request")
}

Method TestBad07NoObject()
{
    // No person with this ID
    Do $$$AssertStatusNotOK(..Agent.Get({"url": "person/42000"}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "404 Not Found")

    // For a PUT it should be 409 Conflict
    Do $$$AssertStatusNotOK(..Agent.Put({"url": "person/42000", "data":{}}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "409 Conflict")
}

Method TestBad08NonJSONTypes()
{
    Do $$$AssertStatusOK(..Agent.Get({"url": "person/1", "headers":{"Accept":"application/xml"}}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "406 Not Acceptable")

    Do $$$AssertStatusOK(..Agent.Put({"url": "person/1/$update-home-address", "headers":{"Content-Type":"application/xml"}, "data":(##class(%Stream.FileCharacter).%New())}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "415 Unsupported Media Type")

    Do $$$AssertStatusOK(..Agent.Put({"url": "person/1/$update-home-address", "headers":{"Accept":"application/xml"}, "data":{}}, .jsonStream))
    Set response = ..Agent.GetLastResponse()
    Do $$$AssertEquals(response.Status, "406 Not Acceptable")
}

}
