/// Interface for authentication methods used in subclasses of <class>AppS.REST.Handler</class>
Class AppS.REST.Authentication Extends %RegisteredObject [ Abstract ]
{

/// Implement to define custom authentication logic that will be run OnPreDispatch.
/// If pContinue is set to false, the request will not be dispatched.
ClassMethod Authenticate(pUrl As %String, ByRef pContinue As %Boolean) As %Status [ Abstract ]
{
}

/// Returns authenticated user information for the request or session
ClassMethod UserInfo(Output pUserInfo As %DynamicObject) As %Status [ Abstract ]
{
}

ClassMethod Logout() As %Status [ Abstract ]
{
}

}
