/// This class is internal to AppS.REST; consumers should not need to use it directly.
Class AppS.REST.Model.QueryResult Extends (%RegisteredObject, AppS.REST.Model.ISerializable) [ System = 4 ]
{

Property rows As list Of AppS.REST.Model.Resource;

ClassMethod FromClassQuery(pModelClass As %Dictionary.CacheClassname, pQueryClass As %Dictionary.CacheClassname, pQueryName As %Dictionary.CacheIdentifier, pArgs...) As AppS.REST.Model.QueryResult [ Internal ]
{
	Set instance = ..%New()
	// Use ResultSet rather than %SQL.Statement to support non-SQLProc class queries
	Set result = ##class(%Library.ResultSet).%New(pQueryClass _ ":" _ pQueryName)
	$$$ThrowOnError(result.%Execute(pArgs...))
	If (result.%SQLCODE < 0) {
		Throw ##class(%Exception.SQL).CreateFromSQLCODE(result.%SQLCODE, result.%Message)
	}
	Set useResult = +$Parameter(pModelClass, "ConstructFromResultRow")
	While result.%Next(.sc) {
		$$$ThrowOnError(sc)
		Set resource = $classmethod(pModelClass, "GetModelInstance", $Select(useResult:result, 1:result.%GetData(1)))
		If $IsObject(resource) {
			Do instance.rows.Insert(resource)
		}
	}
	$$$ThrowOnError(sc)
	Quit instance
}

/// Serialize a JSON enabled class as a JSON document and write it to the current device.
Method JSONExport() As %Status
{
	Set sc = ..JSONExportToStream(.stream)
	If $$$ISOK(sc) {
		Do stream.OutputToDevice()
	}
	Quit sc
}

/// Serialize a JSON enabled class as a JSON document and write it to a stream.
Method JSONExportToStream(ByRef export As %Stream.Object) As %Status
{
	Quit ..JSONExportInternal(1,.export)
}

/// Serialize a JSON enabled class as a JSON document and return it as a string.
Method JSONExportToString(ByRef export As %String) As %Status
{
	Quit ..JSONExportInternal(0,.export)
}

Method JSONExportInternal(pStreamMode As %Boolean = 1, Output export) As %Status
{
	Try {
		Set buffer = ##class(AppS.Util.Buffer).%New()
		$$$ThrowOnError(buffer.BeginCaptureOutput())
		Write "["
		For index=1:1:..rows.Count() {
			If (index > 1) {
				Write ","
			}
			$$$ThrowOnError(..rows.GetAt(index).JSONExport())
		}
		Write "]"
		If (pStreamMode) {
			$$$ThrowOnError(buffer.ReadToStream(.export))
		} Else {
			$$$ThrowOnError(buffer.ReadToString(.export))
		}
		$$$ThrowOnError(buffer.EndCaptureOutput())
	} Catch e {
		Kill export
		Set sc = e.AsStatus()
	}
	Quit sc
}

}
