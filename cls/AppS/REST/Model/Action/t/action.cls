Include %occClassname

/// This class is internal to AppS.REST; consumers should not use or reference it directly.
Class AppS.REST.Model.Action.t.action Extends (%RegisteredObject, %XML.Adaptor) [ System = 2 ]
{

Parameter XMLIGNOREINVALIDATTRIBUTE As BOOLEAN = 0;

Parameter NAMESPACE As STRING = "http://www.intersystems.com/apps/rest/action";

Property arguments As list Of AppS.REST.Model.Action.t.argument(XMLNAME = "argument", XMLPROJECTION = "element");

/// Name of the action (used in URLs)
Property name As %String(MAXLEN = 255, XMLPROJECTION = "attribute") [ Required ];

/// Whether the action targets the class or instance. Default is "class".
Property target As %String(VALUELIST = ",class,instance", XMLPROJECTION = "attribute") [ InitialExpression = "class", Required ];

/// The method to call - either the name of a class/instance method, or (if in another class) may take the format <code>classname:methodname</code>
Property call As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// The class query to wrap. May just be the query name if the query is in the current class, or <code>classname:queryname</code> if in a different class.
Property query As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// The method to use for the action. Defaults to POST, as this will be most common.
Property method As %String(VALUELIST = ",GET,POST,PUT,DELETE", XMLPROJECTION = "attribute") [ InitialExpression = "POST", Required ];

/// For queries, the model class of result instances (if different from the source class)
Property modelClass As %Dictionary.CacheClassname(XMLPROJECTION = "attribute");

/// This callback method is invoked by the <METHOD>%ValidateObject</METHOD> method to 
/// provide notification that the current object is being validated.
/// 
/// <P>If this method returns an error then <METHOD>%ValidateObject</METHOD> will fail.
Method %OnValidateObject() As %Status [ Private, ServerOnly = 1 ]
{
	If (..call = "") = (..query = "") {
		// If call and query are both empty or both nonempty, we have a problem.
		Set msg = $$$FormatText("Action %1: must specify either a call or a query to use.",..name)
		Quit $$$ERROR($$$GeneralError,msg)
	}
	
	If (..query '= "") {
		If (..method = "POST") {
			Set msg = $$$FormatText("Action %1: must use GET method with a query.",..name)
			Quit $$$ERROR($$$GeneralError,msg)
		}
	} Else {
		If (..modelClass '= "") {
			Set msg = $$$FormatText("Action %1: modelClass may only be defined for query actions",..name)
			Quit $$$ERROR($$$GeneralError,msg)
		}
	}
	
    Set sc = $$$OK
	For i=1:1:..arguments.Count() {
        Set sc = $$$ADDSC(sc,..arguments.GetAt(i).%ValidateObject())
    }
	Quit sc
}

Method GetDependencies(pSourceClass As %String, ByRef pClassArray)
{
	// Always depends on the source class.
	Set pClassArray(pSourceClass) = ""
	
	If (..modelClass '= "") {
		Set pClassArray(..modelClass) = ""
	}
	
	// Other dependencies
	If (..query '= "") {
		If $Length(..query,":") > 1 {
			Set pClassArray($Piece(..query,":")) = ""
		}
	} Else {
		If $Length(..call,":") > 1 {
			Set class = $Piece(..call,":")
			Set method = $Piece(..call,":",2)
			Set pClassArray(class) = ""
		} Else {
			Set class = pSourceClass
			Set method = ..call
		}
		Set formalspec = $$$comMemberKeyGet(class,$$$cCLASSmethod,method,$$$cMETHformalspecparsed)
		Set pointer = 0
		While $ListNext(formalspec, pointer, argument) {
			If $Data(argument)#2 && ($ListGet(argument,2) '= "") {
				Set pClassArray($$$NormalizeClassname($ListGet(argument,2))) = ""
			}
		}
		Set returnType = $$$comMemberKeyGet(class,$$$cCLASSmethod,method,$$$cMETHreturntype)
		If (returnType '= "") {
			Set pClassArray($$$NormalizeClassname(returnType)) = ""
		}
	}
}

Method Generate(pSourceClass As %String, Output pCodeArray, Output pAccepts As %String, Output pContentType As %String)
{
	#define GENERATE(%line) Set pCodeArray($i(pCodeArray)) = $c(9)_%line
	
	Kill pCodeArray
	Set pAccepts = ""
	Set pContentType = ""
	Set tResultClass = pSourceClass
	Do ..GetFormalSpecMap(.tResultClass, .class, .method, .argArray, .nameMap, .returnType)
	
	$$$GENERATE("// "_..method_" $"_..name)
	
	Set pCodeArray($i(pCodeArray)) = $c(9)_"Set args = "_$Get(argArray,0)
	
	For argIndex = 1:1:..arguments.Count() {
		Set argument = ..arguments.GetAt(argIndex)
		Set position = nameMap(argument.target)
		Set argType = $ListGet(argArray(position),2)
		If (argument.source = "url") {
			If (argument.required) {
				$$$GENERATE("Set args("_position_") = %request.Get("_$$$QUOTE(argument.name)_")")
				$$$GENERATE("If (args("_position_") = """") {")
				$$$GENERATE("	Set %response.Status = "_$$$QUOTE(##class(%CSP.REST).#HTTP400BADREQUEST))
				$$$GENERATE("	Return")
				$$$GENERATE("}")
			} Else {
				$$$GENERATE("Merge args("_position_") = %request.Data("_$$$QUOTE(argument.name)_",1)")
			}
		} ElseIf (argument.source = "body") {
			If ('argument.required) {
				$$$GENERATE("If %request.Content.Size = 0 {")
				$$$GENERATE("	Set args("_position_") = $$$NULLOREF")
				$$$GENERATE("} Else {")
			}
			If $ClassMethod(argType,"%Extends","%Library.DynamicAbstractObject") {
				Set pAccepts = "application/json"
				$$$GENERATE("Set args("_position_") = {}.%FromJSON(%request.Content)")
			} ElseIf $ClassMethod(argType,"%Extends","AppS.REST.Model.Resource") {
				Set pAccepts = $Parameter(argType,"MEDIATYPE")
				$$$GENERATE("Set model = ##class("_argType_").GetModelInstance()")
				$$$GENERATE("$$$ThrowOnError(model.%JSONImport(%request.Content))")
				$$$GENERATE("Set args("_position_") = model")
			} ElseIf $Parameter(argType,"%JSONENABLED") {
				Set pAccepts = "application/json"
				$$$GENERATE("Set model = ##class("_argType_").%New()")
				$$$GENERATE("$$$ThrowOnError(model.%JSONImport(%request.Content))")
				$$$GENERATE("Set args("_position_") = model")
			}
			If ('argument.required) {
				$$$GENERATE("}")
			}
		} ElseIf (argument.source = "id") {
			// TODO: support alternative ID fields / method in AppS.REST.Model.Resource to get the ID of an instance
			// This approach is lazy and assumes %Persistent/AppS.REST.Model.Adaptor
			$$$GENERATE("	Set args("_position_") = pInstance.%Id()")
		}
	}
	
	If (..query '= "") {
		Set methodCall = "set result = ##class(AppS.REST.Model.QueryResult).FromClassQuery("_$$$QUOTE(tResultClass)_","_$$$QUOTE(class)_","_$$$QUOTE(method)_",args...)"
	} Else {
		If (returnType = "") {
			Set methodCall = "Do "
		} Else {
			Set methodCall = "Set result = "
		}
		Set methodCall = methodCall_$Case(..target,
			"instance":"pInstance.",
			"class":"##class("_class_").")_method_"(args...)"
	}
	$$$GENERATE(methodCall)
	If (returnType = "%Library.Status") {
		$$$GENERATE("$$$ThrowOnError(result)")
	} ElseIf (returnType '= "") {
		If $ClassMethod(returnType,"%Extends","%Library.DynamicAbstractObject") {
			Set pContentType = "application/json"
			Set exportCommand = "Write result.%ToJSON()"
		} ElseIf $ClassMethod(returnType,"%Extends","AppS.REST.Model.Resource") {
			Set pContentType = $Parameter(returnType,"MEDIATYPE")
			Set exportCommand = "Do result.JSONExport()"
		} ElseIf $ClassMethod(returnType,"%Extends","AppS.REST.Model.QueryResult") {
			Set pContentType = $Parameter(tResultClass,"MEDIATYPE")
			Set exportCommand = "Do result.JSONExport()"
		} ElseIf $Parameter(returnType,"%JSONENABLED") {
			Set pContentType = "application/json"
			Set exportCommand = "Do result.%JSONExport()"
		} Else {
			$$$GENERATE("// Unknown handling for return type: "_returnType)
			$$$GENERATE("Set %response.Status = "_$$$QUOTE(##class(%CSP.REST).#HTTP204NOCONTENT))
			Quit
		}
		$$$GENERATE("Set %response.ContentType = "_$$$QUOTE(pContentType))
		$$$GENERATE("If $IsObject(result) {")
		$$$GENERATE("	"_exportCommand)
		$$$GENERATE("} Else {")
		$$$GENERATE("	Set %response.Status = "_$$$QUOTE(##class(%CSP.REST).#HTTP204NOCONTENT))
		$$$GENERATE("}")
	}
}

Method GetFormalSpecMap(ByRef pModelClass As %String, Output pClass, Output pMethod, Output pArgArray, Output pNameMap, Output pReturnType)
{
	Kill pClass,pMethod,pArgArray,pNameMap,returnType
	
	If (..query '= "") {
		// Class Query - method = query name
		If $Length(..query,":") > 1 {
			Set pClass = $Piece(..query,":")
			Set pMethod = $Piece(..query,":",2)
		} Else {
			Set pClass = pModelClass
			Set pMethod = ..query
		}
		
		Set formalspec = $$$comMemberKeyGet(pClass,$$$cCLASSquery,pMethod,$$$cQUERYformalspecparsed)
		Set pointer = 0
		While $ListNext(formalspec, pointer, argument) {
			Set pArgArray($Increment(pArgArray)) = $List(argument,1,2)
			Set pNameMap($ListGet(argument)) = pArgArray
		}
		If (..modelClass '= "") {
			Set pModelClass = ..modelClass
		}
		Set pReturnType = "AppS.REST.Model.QueryResult"
	} Else {
		// Normal method call
		If $Length(..call,":") > 1 {
			Set pClass = $Piece(..call,":")
			Set pMethod = $Piece(..call,":",2)
		} Else {
			Set pClass = pModelClass
			Set pMethod = ..call
		}
		
		Set formalspec = $$$comMemberKeyGet(pClass,$$$cCLASSmethod,pMethod,$$$cMETHformalspecparsed)
		Set pointer = 0
		While $ListNext(formalspec, pointer, argument) {
			Set pArgArray($Increment(pArgArray)) = $List(argument,1,2)
			Set pNameMap($ListGet(argument)) = pArgArray
		}
		Set pReturnType = $$$NormalizeClassname($$$comMemberKeyGet(pClass,$$$cCLASSmethod,pMethod,$$$cMETHreturntype))
	}
}

}
