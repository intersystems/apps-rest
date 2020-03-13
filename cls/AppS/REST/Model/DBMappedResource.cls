/// Base class for all models that directly correspond to data from the database (e.g., AppS.REST.Model.Proxy and AppS.REST.Model.Adaptor)
Class AppS.REST.Model.DBMappedResource Extends (AppS.REST.Model.Resource, %JSON.Adaptor) [ Abstract, System = 3 ]
{

/// The class to which this class provides REST access. It must extend %Persistent and have its %JSONENABLED class parameter set to 1 (e.g., by extending %JSON.Adaptor).
/// Subclasses must override this parameter.
Parameter SOURCECLASS As STRING [ Abstract ];

/// The JSON mapping of the related JSON-enabled class to use.
/// Defaults to empty (the default mapping for the associated class).
Parameter JSONMAPPING As STRING [ Abstract ];

/// Override to use an alternative JSON generator
Parameter JSONGENERATOR As CLASSNAME = "%JSON.Generator";

/// Override to use an alternative unique index name
Parameter IndexToUse As STRING = "ID";

/// If true, the whole SQL result row is passed to GetModelInstance rather than just the ID.
/// If true, <method>GetModelFromResultRow</method> must be overridden and implemented.
Parameter ConstructFromResultRow As BOOLEAN = 0;

/// Returns an existing instance of this model, based on the identifier <var>index</var>, or a new instance if <var>index</var> is not supplied.
ClassMethod GetModelInstance(index As %String) As AppS.REST.Model.DBMappedResource
{
	// We might want to pass in an entire row (an object) instead of just an index to look up
	// If that happens, use this method instead
	If $IsObject($Get(index)) {
		Return ..GetModelFromResultRow(index)
	} Else {
		If $Data(index)#2 {
			Set method = "%OpenId"
			If (..#IndexToUse '= "ID") {
				Set method = ..#IndexToUse _ "Open"
			}
			Set object = $classmethod(..#SOURCECLASS, method, index, , .tSC)
			$$$ThrowOnError(tSC)
		} Else {
			Set object = $classmethod(..#SOURCECLASS, "%New")
		}
		
		Return ..GetModelFromObject(object)
	}
}

/// May be overridden to get an instance of this class from a result set row instead of an object.
/// This is particularly useful for loading data from a linked table, where individual reads are expensive.
ClassMethod GetModelFromResultRow(pResultRow As %Library.IResultSet) As AppS.REST.Model.DBMappedResource
{
	$$$ThrowStatus($$$ERROR($$$NotImplemented))
}

/// Uses the data from a persistent object to populate the properties of this model.<br><br>
/// The <b>object</b> argument is a %Persistent object of whatever class is specified by <parameter>SOURCECLASS</parameter>.
/// It was either opened with %OpenId, opened with an IndexOpen method, or created with %New().<br><br>
/// This method should instantiate an instance of this model with ..%New(), populate its properties
/// using <b>object</b>, and then return the model.  For example, a subclass implementation might look something like: <pre>
/// set myModel = ..%New()
/// set myModel.name = object.DisplayName
/// set myModel.alive = 'object.isDead()
/// set myModel.age = object.age
/// return myModel
/// </pre>
/// This method must be overwritten by subclasses.
ClassMethod GetModelFromObject(object As %Persistent) As AppS.REST.Model.DBMappedResource [ Abstract ]
{
}

/// Saves the model instance
Method SaveModelInstance(pUserContext As %RegisteredObject) [ Abstract ]
{
}

/// Deletes an instance of this model, based on the identifier <var>pID</var>
ClassMethod DeleteModelInstance(pID As %String) As %Boolean [ Abstract ]
{
}

/// Since a proxy connects directly to a %persistent class, getting a collection constitutes
/// building and running a query, and then printing out the result set in a json format.
ClassMethod GetCollection(ByRef URLParams)
{
	Set resultSet = ..ConstructAndRunQuery(.URLParams)
    Write "["
	
    Set useResultRow = ..#ConstructFromResultRow
    While resultSet.%Next(.sc) {
		$$$ThrowOnError(sc)
		Set tProxy = ..GetModelInstance($Select(useResultRow:resultSet,
			1:resultSet.%Get(..#IndexToUse)))
		If ($Increment(count) > 1) {
			Write ","
		}
		Do tProxy.JSONExport()
	}
	$$$ThrowOnError(sc)
	
    Write "]"
}

ClassMethod ConstructAndRunQuery(ByRef URLParams) [ Internal, Private ]
{
	Set query = ##class(AppS.REST.QueryGenerator).GetQuery(..#SOURCECLASS, ..GetProxyColumnList(), ..#IndexToUse, .URLParams, .queryParams)
	
	Set tStatement = ##class(%SQL.Statement).%New()
	Set qStatus = tStatement.%Prepare(query)
	$$$ThrowOnError(qStatus)
	
    Set rset = tStatement.%Execute(queryParams...)
    If (rset.%SQLCODE < 0) {
	    Throw ##class(%Exception.SQL).CreateFromSQLCODE(rset.%SQLCODE,rset.%Message)
    }
    Return rset
}

/// JSONImport imports JSON or dynamic object input into this object.<br />
/// The input argument is either JSON as a string or stream, or a subclass of %DynamicAbstractObject.
Method JSONImport(input) As %Status
{
	Quit ..%JSONImport(.input, ..#JSONMAPPING)
}

/// Serialize a JSON enabled class as a JSON document and write it to the current device.
Method JSONExport() As %Status
{
	Quit ..%JSONExport(..#JSONMAPPING)
}

/// Serialize a JSON enabled class as a JSON document and write it to a stream.
Method JSONExportToStream(ByRef export As %Stream.Object) As %Status
{
	Quit ..%JSONExportToStream(.export, ..#JSONMAPPING)
}

/// Serialize a JSON enabled class as a JSON document and return it as a string.
Method JSONExportToString(ByRef %export As %String) As %Status
{
	Quit ..%JSONExportToString(.%export, ..#JSONMAPPING)
}

/// Subclasses should not need to override this method. Instead, implement <method>OnGetProxyColumnList</method>.
ClassMethod GetProxyColumnList() As %DynamicObject [ CodeMode = objectgenerator, Internal ]
{
	Set sc = $$$OK
	Try {
		If $$$comClassKeyGet(%compiledclass.Name,$$$cCLASSabstract) {
			// Don't generate.
			Quit
		}

		Set class = %parameter("SOURCECLASS")
		If (class = "$classname()") {
			// Special case, replace with current class name.
			// TODO: More generic COSEXPRESSION handling?
			Set class = %compiledclass.Name
		}
		If '$$$comMemberKeyGet(class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
			$$$ThrowStatus($$$ERROR($$$GeneralError,"Class '" _ class _ "' must be JSON-enabled."))
		}
		Set mapping = $lb() // Key of default mapping in %JSON.Generator:GenerateMapping*
		Set mappingParam = $Case(%parameter("JSONMAPPING"), "":$lb() /*default mapping subscript*/, :%parameter("JSONMAPPING"))
		Set jsonGenerator = %parameter("JSONGENERATOR")

		If (jsonGenerator = "") {
			Do %code.WriteLine(" Quit {}")
			Quit
		}

		// Call JSON generator methods
		$$$ThrowOnError($ClassMethod(jsonGenerator,"GenerateMapping",class,.mapping))
		$$$ThrowOnError($ClassMethod(jsonGenerator,"GenerateMappingFromXdata",class,.mapping))

		If '$Data(mapping(mappingParam)) {
			Do %code.WriteLine(" Quit {}")
			Quit
		}

		// Build map of JSON mapping column name -> SQL field name
		// Sample value from mapping variable:
		// mapping("FooBarMapping",1)=$lb("Foo","Foo","inout","someField",0,0,"",0,"string","LITERAL","%Library.String",)
		Set fieldIndex = 0 // SKip 0 subscript
		For {
			Set fieldIndex = $Order(mapping(mappingParam,fieldIndex),1,fieldInfo)
			If (fieldIndex = "") {
				Quit
			}

			// Skip properties with projection "none" or non-"LITERAL" types.
			If ($ListGet(fieldInfo,3) = "none") {
				Continue
			}
			If ($ListGet(fieldInfo,10) '= "LITERAL") {
				Continue
			}

			Set fields($ListGet(fieldInfo,2)) = $ListGet(fieldInfo,4)
		}

		Set compiledClass = ##class(%Dictionary.CompiledClass).%OpenId(class,,.sc)
		$$$ThrowOnError(sc)

		Do %code.WriteLine(" Set columns = {}")
		Set propKey = ""
		For {
			#dim prop As %Dictionary.CompiledProperty
			Set prop = compiledClass.Properties.GetNext(.propKey)
			Quit:(prop = "")
			Continue:(prop.Name = "%%OID")
			Continue:(prop.Name = "%Concurrency")
			Continue:(prop.Relationship)
			Continue:(prop.Collection '= "")
			Continue:(prop.Transient)
			Continue:(prop.MultiDimensional)
			
			If $Data(fields(prop.Name),propInfo) {
				Set name = $Case(prop.SqlFieldName,"":prop.Name,:prop.SqlFieldName)
				Do %code.WriteLine(" Do columns.%Set(" _ $$$QUOTE(propInfo) _ "," _ $$$QUOTE(name) _ ")")
			}
		}
		Do %code.WriteLine(" Do ..OnGetProxyColumnList(columns)")
		Do %code.WriteLine(" Return columns")
	} Catch e {
		Set sc = e.AsStatus()
	}
	Quit sc
}

/// Subclasses may override this method to modify the permitted set of columns/aliases for use in queries
/// (by default, this is the full set of exposed properties in the model with their JSON aliases)
ClassMethod OnGetProxyColumnList(pColumnList As %DynamicObject)
{
}

/// Subclasses  may override this method to do additional security checks or otherwise make changes to the model before it is saved.
/// Primarily relevant for subclasses of AppS.REST.Model.Proxy and AppS.REST.Model.Adaptor.
/// Should throw an exception if an error occurs - e.g., $$$ThrowStatus($$$ERROR($$$AccessDenied))
Method OnBeforeSaveModel(pUserContext As %RegisteredObject)
{
}

/// Subclasses  may override this method to do additional security checks or otherwise make changes to the model before it is saved.
/// Primarily relevant for subclasses of AppS.REST.Model.Proxy and AppS.REST.Model.Adaptor.
/// Should throw an exception if an error occurs - e.g., $$$ThrowStatus($$$ERROR($$$AccessDenied))
Method OnAfterSaveModel(pUserContext As %RegisteredObject)
{
}

}
