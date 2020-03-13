/// This class is internal to AppS.REST; consumers should not use or reference it directly.
Class AppS.REST.Model.Action.Generator [ System = 2 ]
{

ClassMethod GenerateClassActions(pCode As %Stream.Object, pActionClassName As %Dictionary.CacheClassname)
{
	Do ..GenerateActions(pCode, pActionClassName, "class")
}

ClassMethod GenerateInstanceActions(pCode As %Stream.Object, pActionClassName As %Dictionary.CacheClassname)
{
	Do ..GenerateActions(pCode, pActionClassName, "instance")
}

ClassMethod GenerateActions(pCode, pActionClassName, pType) [ Private ]
{
	#dim metadata As AppS.REST.Model.Action.t.actions
	#dim action As AppS.REST.Model.Action.t.action
	
	Set initTLevel = $TLevel

	Try {
		
		Set sourceClass = ..GetSourceClass(pActionClassName)
		If (sourceClass = "") {
			Quit
		}
		
		Set metadata = ..GetActionMetadata(sourceClass)
		Set resourceName = $Parameter(sourceClass,"RESOURCENAME")
		
		TSTART
		For index=1:1:metadata.actions.Count() {
			Set action = metadata.actions.GetAt(index)
			If (action.target '= pType) {
				Continue
			}
			Do action.Generate(sourceClass, .actionCode, .accepts, .contentType)
			
			// Register newly-created actions.
			&sql(insert or update into AppS_REST.ActionMap
				(ResourceName, ActionName, ActionTarget, HTTPVerb, MediaType, Accepts, ModelClass, ImplementationClass) values
				(:resourceName, :action.name, :action.target, :action.method, :contentType, :accepts, :sourceClass, :pActionClassName))
			If (SQLCODE < 0) {
				Throw ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE,%msg)
			}
			
			Merge generateMap($ListBuild(action.name,action.method)) = actionCode
		}
		
		Do %code.WriteLine($c(9)_"Set tAction = $ZConvert(pAction,""L"")")
		
		Set key = ""
		For {
			Set key = $Order(generateMap(key),1,lineCount)
			Quit:key=""
			
			Set $ListBuild(actionName,httpMethod) = key
			
			If $Increment(counter) = 1 {
				Set prefix = $c(9)_"If "
			} Else {
				Set prefix = $c(9)_"} ElseIf "
			}
			Set prefix = prefix _ "(tAction = "_$$$QUOTE($ZConvert(actionName,"L"))_") && (pHTTPMethod = "_$$$QUOTE(httpMethod)_") {"
			
			Do %code.WriteLine(prefix)
			
			For line=1:1:lineCount {
				Do %code.WriteLine($c(9)_generateMap(key,line))
			}
		}
		
		If $Get(counter,0) {
			Do %code.WriteLine($c(9)_"}")
		}
		
		TCOMMIT
	} Catch e {
	} // Finally:
	
	While $TLevel > initTLevel {
		TROLLBACK 1
	}
	
	If $IsObject($Get(e)) {
		Throw e
	}
}

ClassMethod GetActionMetadata(pSourceClass As %Dictionary.CacheClassname) As AppS.REST.Model.Action.t.actions
{
	Set emptyActions = ##class(AppS.REST.Model.Action.t.actions).%New()
	If (pSourceClass = "") || $$$comClassKeyGet(pSourceClass,$$$cCLASSabstract) {
		Return emptyActions
	}
	
	Set origin = $$$comMemberKeyGet(pSourceClass,$$$cCLASSxdata,"ActionMap",$$$cXDATAorigin)
	Set xData = ##class(%Dictionary.XDataDefinition).IDKEYOpen(origin,"ActionMap",,.sc)
	$$$ThrowOnError(sc)
	
	If (xData.Data.Size = 0) {
		Return emptyActions
	}
	
	Set reader = ##class(%XML.Reader).%New()
	Do reader.CorrelateRoot("AppS.REST.Model.Action.t.actions")
	$$$ThrowOnError(reader.OpenStream(xData.Data))
	While reader.Next(.actions,.sc) {
		$$$ThrowOnError(sc)
		$$$ThrowOnError(actions.%ValidateObject())
		Return actions
	}
	$$$ThrowOnError(sc)
	
	Return emptyActions
}

ClassMethod GetSourceClass(pActionClassName As %Dictionary.CacheClassname) As %Dictionary.CacheClassname
{
	If $$$comClassKeyGet(pActionClassName,$$$cCLASSabstract) {
		Quit ""
	}
	
	Set sourceClass = $$$comMemberKeyGet(pActionClassName,$$$cCLASSparameter,"SOURCECLASS",$$$cPARAMdefault)
	If (sourceClass = "") {
		Set sc = $$$ERROR($$$GeneralError,$$$FormatText("SOURCELCASS parameter not defined in class %1",pActionClassName))
		$$$ThrowStatus(sc)
	}
	Quit sourceClass
}

ClassMethod GetClassDependencies(pSourceClass As %Dictionary.CacheClassname) As %List
{
	#dim metadata As AppS.REST.Model.Action.t.actions
	#dim action As AppS.REST.Model.Action.t.action
	
	Set metadata = ..GetActionMetadata(pSourceClass)
	Set list = ""
	For index=1:1:metadata.actions.Count() {
		Set action = metadata.actions.GetAt(index)
		Do action.GetDependencies(pSourceClass,.dependencies)
	}
	
	Set class = ""
	For {
		Set class = $Order(dependencies(class))
		Quit:class=""
		
		Set list = list_$ListBuild(class)
	}
	
	Quit list
}

}

