/// This class provides methods for detecting unprotected classes on the current system.
/// It's good to build this into a unit test to make sure you're enforcing security correctly.
Class AppS.REST.Auditor
{

/// Returns a $ListBuild list of non-whitelisted, non-protected classes. <br />
/// @API.Method
ClassMethod ListUnprotectedClasses(pVerbose As %Boolean = 0) As %List
{
	Set list = ""
	Set result = ..GetAllResourceClasses()
	While result.%Next(.sc) {
		$$$ThrowOnError(sc)
		Try {
			Set class = result.%GetData(1)
			If ..IsClassWhiteListed(class) {
				Continue
			}
			
			// Simple way to detect implementations that always return true:
			// Define no parameters and see if we return 1.
			If $classmethod(class,"CheckPermission") {
				Set list = list_$lb(class)
				If pVerbose {
					Write "Unprotected REST model class: ",class,!
				}
			}
		} Catch e {
			// This is actually good - probably an <UNDEFINED>
		}
	}
	$$$ThrowOnError(sc)
	Quit list
}

/// Lists all security implementations for resources defined in this environment. <br />
/// Outputs them to the current device if <var>pVerbose</var> is true. <br />
/// Also returns implementation details in <var>pImplementations</var>. <br />
/// @API.Method
ClassMethod ListSecurityImplementations(Output pImplementations, pVerbose As %Boolean = 0)
{
	Set result = ..GetAllResourceClasses()
	If pVerbose {	
		Write !
	}
	While result.%Next(.sc) {
		$$$ThrowOnError(sc)
		Set class = result.%GetData(1)
		Set implOrigin = $$$comMemberKeyGet(class,$$$cCLASSmethod,"CheckPermission",$$$cMETHorigin)
		If (implOrigin = "") {
			Set implOrigin = class
		}
		Merge pImplementations(class) = ^oddDEF(implOrigin,$$$cCLASSmethod,"CheckPermission",$$$cMETHimplementation)
		If pVerbose {
			Write class," (",$parameter(class,"RESOURCENAME"),")",!
			Write "CheckPermission implementation"
			If (implOrigin '= class) {
				Write ", inherited from ",implOrigin
			}
			Write ": ",!
			For line=1:1:$Get(pImplementations(class)) {
				Write pImplementations(class,line),!
			}
			Write !
		}
	}
	$$$ThrowOnError(sc)
}

/// Adds a class to the whitelist of classes that may have security unimplemented <br />
/// @API.Method
ClassMethod WhiteListClass(pClass As %Dictionary.CacheClassname)
{
	Set ^Config("AppS.REST","WhiteList",pClass) = $ListBuild($username)
}

/// Removes a class from the whitelist of classes that may have security unimplemented <br />
/// @API.Method
ClassMethod RemoveClassFromWhiteList(pClass As %Dictionary.CacheClassname)
{
	Kill ^Config("AppS.REST","WhiteList",pClass)
}

/// Returns true if a class is whitelisted <br />
/// @API.Method
ClassMethod IsClassWhiteListed(pClass As %Dictionary.CacheClassname) As %Boolean
{
	Quit $Data(^Config("AppS.REST","WhiteList",pClass))#2
}

ClassMethod GetAllResourceClasses() As %SQL.StatementResult [ Internal, Private ]
{
	Set tResult = ##class(%SQL.Statement).%ExecDirect(,"select distinct %exact ModelClass from AppS_REST.ResourceMap")
	If (tResult.%SQLCODE < 0) {
		Throw ##class(%Exception.SQL).CreateFromSQLCODE(tResult.%SQLCODE,tResult.%Message)
	}
	Quit tResult
}

}

