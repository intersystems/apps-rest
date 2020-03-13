Class UnitTest.AppS.REST.SampleUnprotectedClass Extends (%UnitTest.TestCase, AppS.REST.Model.Resource)
{

/// Name of the resource at the REST level
/// Subclasses MUST override this
Parameter RESOURCENAME As STRING = "unittest-fake-resource";

/// This is very bad in any other case, though there is no business logic for this class, so it's fine.
ClassMethod CheckPermission(pID As %String, pOperation As %String, pUserContext As %RegisteredObject) As %Boolean
{
	Quit 1
}

/// Asserts that the implementation of CheckPermission for this class is located correctly.
Method TestListImplementations()
{
	Do ##class(AppS.REST.Auditor).ListSecurityImplementations(.impl,1)
	Do $$$AssertEquals(impl($classname(),1),$c(9)_"Quit 1")
}

/// Asserts that this class is the only non-whitelisted, non-security-protected class.
Method TestThatIAmUnprotected()
{
	Set list = ##class(AppS.REST.Auditor).ListUnprotectedClasses(1)
	Do $$$AssertEquals($ListLength(list),1,"Only one class was recognized as unprotected.")
	Set pointer = 0
	Set found = 0
	While $ListNext(list,pointer,class) {
		If (class '= $classname()) {
			Do $$$AssertFailure()
		} Else {
			Set found = 1
			Do $$$AssertEquals(class,$classname(),$classname()_" was treated as an unprotected class.")
		}
	}
	If 'found {
		Do $$$AssertFailure($classname()_" was not recgonized as an unprotected class.")
	}
}

/// Tests whitelist behavior.
Method TestWhitelist()
{
	Do ##class(AppS.REST.Auditor).WhiteListClass($classname())
	Set list = ##class(AppS.REST.Auditor).ListUnprotectedClasses()
	Do $$$AssertEquals(list,"")
	Do $$$AssertEquals(##class(AppS.REST.Auditor).IsClassWhiteListed($classname()),1)
	Do ##class(AppS.REST.Auditor).RemoveClassFromWhiteList($classname())
	Do $$$AssertEquals(##class(AppS.REST.Auditor).IsClassWhiteListed($classname()),0)
}

Method TestCompilation()
{
	// Gets a bit of test coverage credit for code generation for this class.
	Do $System.OBJ.Compile($classname(),"ck-d/nomulticompile")
}

}

