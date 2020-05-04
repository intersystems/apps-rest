Class Sample.Phonebook.REST.Model.PhoneNumber Extends AppS.REST.Model.Proxy
{

Parameter RESOURCENAME = "phone-number";

Parameter SOURCECLASS = "Sample.Phonebook.Data.PhoneNumber";

Parameter JSONMAPPING = "PhoneNumberWithPerson";

ClassMethod CheckPermission(pID As %String, pOperation As %String, pUserContext As AppS.REST.Authentication.PlatformUser) As %Boolean
{
	Quit (pOperation = "CREATE") || (pOperation = "UPDATE") || (pOperation = "DELETE")
}

}
