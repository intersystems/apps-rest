Class UnitTest.AppS.REST.Sample.Handler Extends AppS.REST.Handler
{

Parameter UseSession = 1;

ClassMethod AuthenticationStrategy() As %Dictionary.CacheClassname
{
    Quit "UnitTest.AppS.REST.Sample.Authentication"
}

ClassMethod GetUserResource(pFullUserInfo As %DynamicObject) As AppS.REST.Model.Resource
{
	Quit ##class(UnitTest.AppS.REST.Sample.UserContext).%New()
}

}
