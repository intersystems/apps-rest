Include %occErrors

/// Base REST handler for APIs built on AppS.REST.
/// Consumers should extend this, override <method>GetUserResource</method> and <method>AuthenticationStrategy</method> appropriately, and
/// should *NOT* override the UrlMap XData block.
Class AppS.REST.Handler Extends %CSP.REST [ System = 4 ]
{

/// Subclasses may override this method to provide information about the logged-in user.
/// <ul>
/// <li> pFullUserInfo: dynamic object with full user info provided by the authentication strategy
/// <ul>
ClassMethod GetUserResource(pFullUserInfo As %DynamicObject) As AppS.REST.Model.ISerializable
{
	Quit $$$NULLOREF
}

/// Specifies the default character set for the page.  This can be overriden using the
/// &lt;CSP:CONTENT CHARSET=&gt; tag, or by setting the <b>%response</b>.CharSet property
/// in the <method>OnPreHTTP</method> method.  If this parameter is not specified, then
/// for the default charset is utf-8.
Parameter CHARSET = "utf-8";

/// Specifies if input %request.Content or %request.MimeData values are converted from their
/// original character set on input. By default (0) we do not modify these and receive them
/// as a binary stream which may need to be converted manually later. If 1 then if there
/// is a 'charset' value in the request Content-Type or mime section we will convert from this
/// charset when the input data is text based. For either json or xml data with no charset
/// this will convert from utf-8 or honor the BOM if one is present.
Parameter CONVERTINPUTSTREAM = 1;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<!-- Authentication routes -->
<Route Url="/auth/status" Method="GET" Call="GetUserInfo" />
<Route Url="/auth/logout" Method="POST" Call="LogOut" />

<!-- Resource "class methods" -->
<Route Url="/:resource" Method="GET" Call="CollectionQuery" />
<Route Url="/:resource" Method="POST" Call="Create" />
<Route Url="/:resource/\$new" Method="GET" Call="Construct" />

<!-- "class actions" (GET/PUT/POST/DELETE) -->
<Route Url="/:resource/\$([^/]+)" Method="GET" Call="DispatchClassAction" />
<Route Url="/:resource/\$([^/]+)" Method="PUT" Call="DispatchClassAction" />
<Route Url="/:resource/\$([^/]+)" Method="POST" Call="DispatchClassAction" />
<Route Url="/:resource/\$([^/]+)" Method="DELETE" Call="DispatchClassAction" />

<!-- Resource "instance methods" -->
<Route Url="/:resource/:id" Method="GET" Call="Retrieve" />
<Route Url="/:resource/:id" Method="PUT" Call="Update" />
<Route Url="/:resource/:id" Method="DELETE" Call="Delete" />

<!-- "instance actions" (GET/PUT/POST/DELETE) -->
<Route Url="/:resource/:id/\$([^/]+)" Method="GET" Call="DispatchInstanceAction" />
<Route Url="/:resource/:id/\$([^/]+)" Method="PUT" Call="DispatchInstanceAction" />
<Route Url="/:resource/:id/\$([^/]+)" Method="POST" Call="DispatchInstanceAction" />
<Route Url="/:resource/:id/\$([^/]+)" Method="DELETE" Call="DispatchInstanceAction" />
</Routes>
}

/// Subclasses must override this to define a custom authentication strategy class.
ClassMethod AuthenticationStrategy() As %Dictionary.CacheClassname [ Abstract ]
{
}

/// This method Gets called prior to dispatch of the request. Put any common code here
/// that you want to be executed for EVERY request. If pContinue is set to 0, the
/// request will NOT be dispatched according to the UrlMap. If this case it's the
/// responsibility of the user to return a response.
ClassMethod OnPreDispatch(pUrl As %String, pMethod As %String, ByRef pContinue As %Boolean) As %Status
{
	#dim %response As %CSP.Response
	Set sc = $$$OK
	If pMethod '= "OPTIONS" { // OPTIONS requests are never authenticated
		Set sc = $classmethod(..AuthenticationStrategy(),"Authenticate",pUrl,.pContinue)
	}
	Do:'pContinue ..OnHandleCorsRequest(pUrl)
	Quit sc
}

ClassMethod GetUserInfo() As %Status
{
	#dim %response As %CSP.Response
	Set userContext = ..GetUserContext()
	If $IsObject(userContext) {
		Set %response.ContentType = userContext.#MEDIATYPE
		$$$ThrowOnError(userContext.JSONExport())
	} Else {
		Set %response.Status = ..#HTTP204NOCONTENT
	}
	Quit $$$OK
}

ClassMethod GetUserContext() As AppS.REST.Model.Resource
{
	$$$ThrowOnError($classmethod(..AuthenticationStrategy(),"UserInfo",.userInfo))
	Quit ..GetUserResource(.userInfo)
}

ClassMethod LogOut() As %Status
{
	Quit $classmethod(..AuthenticationStrategy(),"Logout")
}

/// Creates a new instance of the resource (handling a POST request to the resource's endpoint)
ClassMethod Create(resource As %String) As %Status
{
	#dim %request As %CSP.Request
	#dim %response As %CSP.Response
	
	// Grab the json body from the incoming reqeust
	Set json = {}.%FromJSON(%request.Content)
	
	// Get proxy class based on the request's content type header and the resource
	Set resourceClass = ..FindContentClass(resource, .tSkip)
	If tSkip {
		Return $$$OK
	}
	
	Set userContext = ..GetUserContext()
	If '$classmethod(resourceClass, "CheckPermission", "", "CREATE", userContext) {
		Do ..ReportHttpStatusCode(..#HTTP403FORBIDDEN, $$$ERROR($$$GeneralError,"Access denied: class "_resourceClass_", CREATE"))
		Return $$$OK
	}
	
	// Instantiate a proxy without passing an id; this will give us an empty one
	Set resourceToUse = $classmethod(resourceClass, "GetModelInstance")
	$$$ThrowOnError(resourceToUse.JSONImport(json))
	Do resourceToUse.SaveModelInstance(userContext)
	
	// Respond with a json block representing the newly posted resource
	Set %response.ContentType = $parameter(resourceClass, "MEDIATYPE")
	Do resourceToUse.JSONExport()

	return $$$OK
}

ClassMethod CollectionQuery(resource As %String) As %Status
{
	// Grab the parameters that define the filters for the query
	// These come in as URL parameters via the request
	Kill params
	Merge params = %request.Data
	
	// Use the request's content type and resource name to determine which proxy class to use
	Set resourceClass = ..FindAcceptedClass(resource, .tSkip)
	If tSkip {
		Return 1
	}
	
	Set userContext = ..GetUserContext()
	If '$classmethod(resourceClass, "CheckPermission", "", "QUERY", userContext) {
		Do ..ReportHttpStatusCode(..#HTTP403FORBIDDEN, $$$ERROR($$$GeneralError,"Access denied: class "_resourceClass_", QUERY"))
		Return 1
	}
	
	Set %response.ContentType = $parameter(resourceClass, "MEDIATYPE")
	
	Try {
		Do $classmethod(resourceClass, "GetCollection", .params)
	} Catch e {
		// For well-defined exception types, report appropriately.
		If e.%IsA("AppS.REST.Exception.QueryGenerationException") {
			Do ..ReportHttpStatusCode(e.ErrorStatus, $$$ERROR($$$GeneralError,e.DisplayString()))
			Quit
		}
		// Otherwise, re-throw.
		Throw e
	}
	
	Return 1
}

ClassMethod Retrieve(resourceName As %String, id As %String) As %Status
{
	#dim %response As %CSP.Response
	#dim resource As AppS.REST.Model.Resource
	
	Set resourceClass = ..FindAcceptedClass(resourceName, .tSkip)
	If tSkip {
		Return 1
	}
	
	If '$classmethod(resourceClass, "CheckPermission", id, "READ", ..GetUserContext()) {
		Do ..ReportHttpStatusCode(..#HTTP403FORBIDDEN, $$$ERROR($$$GeneralError,"Access denied: class "_resourceClass_", ID: "_id_", READ"))
		Return 1
	}
	
	Set %response.ContentType = $parameter(resourceClass, "MEDIATYPE")
	Set resource = $classmethod(resourceClass, "GetModelInstance", id)
	Quit resource.JSONExport()
}

ClassMethod Construct(resourceName As %String) As %Status
{
	#dim %response As %CSP.Response
	#dim resource As AppS.REST.Model.Resource
	
	Set resourceClass = ..FindAcceptedClass(resourceName, .tSkip)
	If tSkip {
		Return 1
	}
	
	// READ with no ID, or ACTION:new, is usable as a permission for this special case.
	If '($classmethod(resourceClass, "CheckPermission", "", "READ", ..GetUserContext())
		|| $classmethod(resourceClass, "CheckPermission", "", "ACTION:new", ..GetUserContext())) {
		Do ..ReportHttpStatusCode(..#HTTP403FORBIDDEN, $$$ERROR($$$GeneralError,"Access denied: class "_resourceClass_", ACTION:new"))
		Return 1
	}
	
	Set %response.ContentType = $parameter(resourceClass,"MEDIATYPE")
	Set resource = $classmethod(resourceClass, "GetModelInstance")
	Quit resource.JSONExport()
}

ClassMethod Update(resourceName As %String, id As %String) As %Status
{
	#dim resourceToUse As AppS.REST.Model.Resource
	
	// Grab the json body from the incoming reqeust
	Set json = {}.%FromJSON(%request.Content)
	
	// Get proxy class based on the request's content type header and the resource
	Set resourceClass = ..FindContentClass(resourceName, .tSkip)
	If tSkip {
		Return $$$OK
	}
	
	Set userContext = ..GetUserContext()
	If '$classmethod(resourceClass, "CheckPermission", id, "UPDATE", userContext) {
		Do ..ReportHttpStatusCode(..#HTTP403FORBIDDEN, $$$ERROR($$$GeneralError,"Access denied: class "_resourceClass_", ID "_id_", UPDATE"))
		Return $$$OK
	}
	
	Set resourceToUse = $classmethod(resourceClass, "GetModelInstance", id)
	$$$ThrowOnError(resourceToUse.JSONImport(json))
	Do resourceToUse.SaveModelInstance(userContext)
	
	Set %response.ContentType = $parameter(resourceClass,"MEDIATYPE")
	Do resourceToUse.JSONExport()
	Return $$$OK
}

ClassMethod Delete(resourceName As %String, id As %String) As %Status
{
	#dim %response As %CSP.Response
	#dim resource As AppS.REST.Model.Resource
	
	Set resourceClass = ..FindContentClass(resourceName, .tSkip)
	If tSkip {
		Return 1
	}
	
	If '$classmethod(resourceClass, "CheckPermission", id, "DELETE", ..GetUserContext()) {
		Set %response.Status = ..#HTTP403FORBIDDEN
		Return 1
	}
	
	Set deleted = $classmethod(resourceClass, "DeleteModelInstance", id)
	If deleted {
		Set %response.Status = ..#HTTP204NOCONTENT
	} Else {
		Set %response.Status = ..#HTTP404NOTFOUND
	}
	Quit $$$OK
}

ClassMethod DispatchClassAction(resourceName As %String, action As %String) As %Status
{
	#dim %response As %CSP.Response
	#dim resource As AppS.REST.Model.Resource
	
	Set actionClass = ..FindActionClass(resourceName, action, "class", .tSkip, .resourceClass)
	If tSkip {
		Return 1
	}
	
	If '$classmethod(resourceClass, "CheckPermission", "", "ACTION:"_action, ..GetUserContext()) {
		Do ..ReportHttpStatusCode(..#HTTP403FORBIDDEN, $$$ERROR($$$GeneralError,"Access denied: class "_resourceClass_", ACTION:"_action))
		Return 1
	}
	
	Do $classmethod(actionClass,"HandleInvokeClassAction", %request.Method, action, ..GetUserContext())
	
	Quit $$$OK
}

ClassMethod DispatchInstanceAction(resourceName As %String, id As %String, action As %String) As %Status
{
	#dim %response As %CSP.Response
	#dim resource As AppS.REST.Model.Resource
	
	Set actionClass = ..FindActionClass(resourceName, action, "instance", .tSkip, .resourceClass)
	If tSkip {
		Return 1
	}
	
	If '$classmethod(resourceClass, "CheckPermission", id, "ACTION:"_action, ..GetUserContext()) {
		Do ..ReportHttpStatusCode(..#HTTP403FORBIDDEN, $$$ERROR($$$GeneralError,"Access denied: class "_resourceClass_", ID "_id_", ACTION:"_action))
		Return 1
	}
	
	Set resourceInstance = $classmethod(resourceClass, "GetModelInstance", id)
	Do $classmethod(actionClass,"HandleInvokeInstanceAction", %request.Method, resourceInstance, action, ..GetUserContext())
	
	Quit $$$OK
}

ClassMethod FindActionClass(pResource As %String, pAction As %String, pTarget As %String, Output pSkipProcessing As %Boolean = 0, Output pResourceClass As %Dictionary.CacheClassname) As %Dictionary.CacheClassname [ Private ]
{
	#dim %response As %CSP.Response
	#dim %request As %CSP.Request
	
	Set accepts = $Piece(%request.GetCgiEnv("HTTP_ACCEPT"),";")
	If (accepts '= "") && (accepts '= "*/*") {
		If '$Match(accepts,"application/(.*\+)?json") {
			Set pSkipProcessing = 1
			Do ..ReportHttpStatusCode(..#HTTP406NOTACCEPTABLE, $$$ERROR($$$GeneralError,"Only JSON-based media types are supported."))
			Quit ""
		}
	} Else {
		Set accepts = $c(0)
	}
	
	Set mediaType = $Piece(%request.ContentType,";")
	If (mediaType '= "") {
		If '$Match(mediaType,"application/(.*\+)?json") {
			Set pSkipProcessing = 1
			Do ..ReportHttpStatusCode(..#HTTP415UNSUPPORTEDMEDIATYPE, $$$ERROR($$$GeneralError,"Only JSON-based media types are supported."))
			Quit ""
		}
	} Else {
		Set mediaType = $c(0)
	}
	
	// Try mediaType = $c(0) as well as the specified media type if the request content is empty
	For tryMediaType = mediaType,$c(0) {
		If (tryMediaType = $c(0)) && %request.Content.Size {
			// Per HTTP spec, this is the default.
			Set tryMediaType = "application/octet-stream"
		}
		Set sc = $$$OK
		/// (ResourceName, ActionName, ActionTarget, HTTPVerb, MediaTypeOrNUL, AcceptsOrNUL)
		Set map = ##class(AppS.REST.ActionMap).UniqueByRequestOpen(pResource,pAction,pTarget,%request.Method,accepts,tryMediaType,,.sc)
		If $$$ISOK(sc) {
			Quit
		}
	}
	If $System.Status.Equals(sc,$$$KeyValueNotFoundOpen) {
		// See if method is the only thing that's wrong:
		Set methodFound = 0
		For otherMethod = "PUT","POST","GET","DELETE" {
			If ##class(AppS.REST.ActionMap).UniqueByRequestExists(pResource,pAction,pTarget,otherMethod,accepts,mediaType) {
				Set methodFound = 1
				Do ..ReportHttpStatusCode(..#HTTP405METHODNOTALLOWED)
				Quit
			}
		}
		
		If 'methodFound {
			// Naive approach: complain about HTTP_ACCEPT if media type is empty, media type if not.
			Do ..ReportHttpStatusCode($Case(mediaType,$c(0):..#HTTP415UNSUPPORTEDMEDIATYPE,:..#HTTP406NOTACCEPTABLE))
			// TODO: Descriptive info about media types available for the specified resource/action
		}
		Set pSkipProcessing = 1
		Quit ""
	}
	$$$ThrowOnError(sc)
	
	Set pResourceClass = map.ModelClass
	Quit map.ImplementationClass
}

ClassMethod FindAcceptedClass(pResource As %String, Output pSkipProcessing As %Boolean = 0) As %Dictionary.CacheClassname [ Private ]
{
	#dim %request As %CSP.Request
	Quit ..FindClass(%request.GetCgiEnv("HTTP_ACCEPT"),pResource,.pSkipProcessing,..#HTTP406NOTACCEPTABLE)
}

ClassMethod FindContentClass(pResource As %String, Output pSkipProcessing As %Boolean = 0) As %Dictionary.CacheClassname [ Private ]
{
	#dim %request As %CSP.Request
	Quit ..FindClass(%request.ContentType,pResource,.pSkipProcessing,..#HTTP415UNSUPPORTEDMEDIATYPE)
}

ClassMethod FindClass(pMediaType As %String, pResource As %String, Output pSkipProcessing As %Boolean = 0, pStatusWhenInvalid As %String) As %Dictionary.CacheClassname [ Private ]
{
	#Dim %response As %CSP.Response
	Set pMediaType = $Piece(pMediaType,";")
	If '$Match(pMediaType,"application/(.*\+)?json") {
		Set pSkipProcessing = 1
		Do ..ReportHttpStatusCode(pStatusWhenInvalid, $$$ERROR($$$GeneralError,"Only JSON is supported."))
		Quit ""
	}
	
	Set map = ##class(AppS.REST.ResourceMap).IDKEYOpen(pResource,pMediaType,,.sc)
	If $System.Status.Equals(sc,$$$LoadObjectNotFound) {
		Do ..ReportHttpStatusCode(pStatusWhenInvalid, sc)
		Set pSkipProcessing = 1
		Quit ""
	}
	$$$ThrowOnError(sc)
	
	Quit map.ModelClass
}

/// Subclasses may override to customize logging. <br />
/// To suppress error logging, set ^Config("AppS","REST","SuppressLogging") = 1
ClassMethod LogErrorStatus(pStatus As %Status)
{
	If '$Get(^Config("AppS","REST","SuppressLogging"),0) {
		Set e = ##class(%Exception.StatusException).CreateFromStatus(pStatus)
		Do e.Log()
	}
}

/// Issue an 'Http' error
ClassMethod ReportHttpStatusCode(pHttpStatus, pSC As %Status = {$$$OK}) As %Status
{
	#dim %request As %CSP.Request
	If $$$ISERR(pSC) {
		Do ..LogErrorStatus(pSC)
	}
	
	// If a default HTTP status is supplied, try to be more descriptive.
	If (pHttpStatus = ..#HTTP500INTERNALSERVERERROR) {
		// Special cases for pSC:
		If $System.Status.Equals(pSC,$$$AccessDenied) {
			// $$$AccessDenied -> 403 Forbidden
			Set %response.Status = ..#HTTP403FORBIDDEN
			Quit $$$OK
		} ElseIf $System.Status.Equals(pSC,$$$GeneralException) {
			// JSON parsing exception
			Set %response.Status = ..#HTTP400BADREQUEST
			Quit $$$OK
		} ElseIf $System.Status.Equals(pSC,$$$LoadObjectNotFound)
			|| $System.Status.Equals(pSC,$$$KeyValueNotFoundOpen) {
			// $$$LoadObjectNotFound -> 404 (GET) or 409 (PUT)
			If (%request.Method = "GET") {
				Quit ##super(..#HTTP404NOTFOUND,pSC)
			} Else /* PUT */ {
				Quit ##super(..#HTTP409CONFLICT,pSC)
			}
		}
	} ElseIf (pHttpStatus = ..#HTTP403FORBIDDEN) && $$$ISERR(pSC) {
		// Don't be too descriptive, though full details of the violation are logged.
		Set %response.Status = ..#HTTP403FORBIDDEN
		Quit $$$OK
	}
    Quit ##super(pHttpStatus,pSC)
}

/// Overridden to use StatusToJSON() for proper escaping
ClassMethod outputStatus(pSC As %Status) As %Status [ Internal ]
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    Try {
        #dim tJSON As %ZEN.proxyObject
        If ..AcceptsContentType("application/json") {
            Set %response.ContentType = ..#CONTENTTYPEJSON
            // Convert the exception to a status and render to JSON
            Set tSC = ..StatusToJSON(pSC, .tJSON)
            If $$$ISERR(tSC) Quit
            // Write the JSON to the output device
           	Write tJSON.%ToJSON()
        } else {
            // Set plain text
            Set %response.ContentType = ..#CONTENTTYPETEXT
            // Write out a simple text message
            Do ##class(%Exception.StatusException).CreateFromStatus(pSC).OutputToDevice()
        }
    } Catch (e) {
        Set tSC = e.AsStatus()
    }
    Quit $$$OK
}

}
