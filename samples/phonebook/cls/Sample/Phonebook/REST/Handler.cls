Class Sample.Phonebook.REST.Handler Extends AppS.REST.Handler
{

ClassMethod AuthenticationStrategy() As %Dictionary.CacheClassname
{
    Quit ##class(AppS.REST.Authentication.PlatformBased).%ClassName(1)
}

ClassMethod GetUserResource(pFullUserInfo As %DynamicObject) As AppS.REST.Authentication.PlatformUser
{
    Quit ##class(AppS.REST.Authentication.PlatformUser).%New()
}

}
