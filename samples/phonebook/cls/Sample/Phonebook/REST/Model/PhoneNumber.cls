Class Sample.Phonebook.REST.Model.PhoneNumber Extends AppS.REST.Model.Proxy [ DependsOn = Sample.Phonebook.Model.PhoneNumber ]
{

Parameter RESOURCENAME = "phone-number";

Parameter SOURCECLASS = "Sample.Phonebook.Model.PhoneNumber";

Parameter JSONMAPPING = "PhoneNumberWithPerson";

ClassMethod CheckPermission(pID As %String, pOperation As %String, pUserContext As AppS.REST.Authentication.PlatformUser) As %Boolean
{
	Quit (pOperation = "CREATE") || (pOperation = "UPDATE") || (pOperation = "DELETE")
}

}
