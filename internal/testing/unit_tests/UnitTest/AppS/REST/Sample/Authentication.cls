Class UnitTest.AppS.REST.Sample.Authentication Extends AppS.REST.Authentication
{

/// Implement to define custom authentication logic that will be run OnPreDispatch.
/// If pContinue is set to false, the request will not be dispatched.
ClassMethod Authenticate(pUrl As %String, ByRef pContinue As %Boolean) As %Status
{
    /// Uses password authentication, so nothing to do here.
    Set pContinue = 1
    Quit $$$OK
}

/// Returns no information at all; user info is determined entirely in the resource class instead.
ClassMethod UserInfo(Output pUserInfo As %DynamicObject) As %Status
{
    Set pUserInfo = {}
    Quit $$$OK
}

/// Implements logout in an appropriate way for the mode of authentication (e.g., revoking tokens or ending the session)
ClassMethod Logout() As %Status
{
    // For this example (with UseSession = 1), simply ends the session.
    Set %session.EndSession = 1
    Quit $$$OK
}

}
