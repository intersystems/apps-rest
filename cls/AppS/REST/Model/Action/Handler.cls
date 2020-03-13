/// This class is internal to AppS.REST; consumers should not use or reference it directly.
Class AppS.REST.Model.Action.Handler [ Abstract, System = 3 ]
{

/// The class for which action handlers will be generated.
Parameter SOURCECLASS As CLASSNAME;

ClassMethod HandleInvokeClassAction(pHTTPMethod As %String, pAction As %String, pUserContext As AppS.REST.Model.Resource) [ CodeMode = objectgenerator ]
{
	Set sc = $$$OK
	Try {
		Do ##class(AppS.REST.Model.Action.Generator).GenerateClassActions(%code, %compiledclass.Name)
	} Catch e {
		Set sc = e.AsStatus()
	}
	Quit sc
}

ClassMethod HandleInvokeInstanceAction(pHTTPMethod As %String, pInstance As AppS.REST.Model.Resource, pAction As %String, pUserContext As AppS.REST.Model.Resource) [ CodeMode = objectgenerator ]
{
	Set sc = $$$OK
	Try {
		Do ##class(AppS.REST.Model.Action.Generator).GenerateInstanceActions(%code, %compiledclass.Name)
	} Catch e {
		Set sc = e.AsStatus()
	}
	Quit sc
}

}
