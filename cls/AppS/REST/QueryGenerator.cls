/// This class is internal to AppS.REST; consumers should not use or reference it directly.
Class AppS.REST.QueryGenerator [ System = 3 ]
{

ClassMethod GetQuery(className As %Dictionary.CacheClassname, columns As %DynamicObject, index As %String, ByRef URLParams, Output queryParams) As %String
{
	Set schemaName = $$$comClassKeyGet(className,$$$cCLASSsqlschemaname)
	Set tableName = $$$comClassKeyGet(className,$$$cCLASSsqltablename)
	If $System.SQL.IsReservedWord(tableName) {
		Set tableName = $$$QUOTE(tableName)
	}
	If (index = "ID") {
		// Allow SqlRowIdName to override default of "ID"
		Set columnName = $$$comClassKeyGet(className,$$$cCLASSsqlrowidname)
		If (columnName '= "") {
			Set index = columnName
		}
	}
	Set query = ..BuildQuery(schemaName _ "." _ tableName, columns, index, .URLParams, .queryParams)
	Return query
}

/// Takes the tableName and the params from the url.
/// Returns the text of a query selecting ID from the table according to the filters specified by params.
/// queryParams is an output of the array which needs to be passed to %Execute when running the query,
/// since the where clause of this query will be assembled with terms like "property > ?"
ClassMethod BuildQuery(tableName As %String, columns As %DynamicObject, index As %String, ByRef params, Output queryParams, pIDQuery As %Boolean = 0)
{
	// creates a query that looks something like:
	//      select ID from sample.person where 1=1 and age>?
	
	// If we're given an index other than ID to use, we need to select that instead of ID (we could do it in addition to ID)
	Set indexColumn = "ID"
	If $Data(index, indexColumn) {}
	If (indexColumn '= "ID") {
		Set indexColumn = indexColumn _ " as ID"
	}	
	Set query = "select " _ indexColumn _ " from " _ tableName _ " where 1=1"
	
	// loop over the params to assemble the where clause and corresponding params array
	Kill queryParams
	Set orderBy = ""
	Set ascOrDesc = "asc"
	Set propName = $Order(params(""))
	While (propName '= "") {
		Set param = params(propName, 1)
		// if the property is $orderBy, then we store the order by string
		// for appending at the end of the where clause building
		If (propName = "$orderBy") {
			Set orderBy = param
			Set propName = $Order(params(propName))
			Continue
		}
		// the queryParams output gets assembled with what we need to pass to %Execute
		Set query = query _ " and " _ ..GetWhereSegment(propName, param, .queryParams, columns)
		Set propName = $Order(params(propName))
	}
	
	// append the order by clause if it exists
	If (orderBy '= "") {
		If ($Extract(orderBy, 1) = "-") {
			Set ascOrDesc = "desc"
			Set orderBy = $Extract(orderBy, 2, *)	
		}
		Set orderColName = columns.%Get(orderBy)
		If (orderColName = "") {
			Throw ##class(AppS.REST.Exception.InvalidColumnException).New(orderBy)
		}
		Set query = query _ " order by " _ orderColName _ " " _ ascOrDesc
	}
	
	Return query
}

/// examples:
/// age[lte]=50
/// age[gte]=20
/// age[eq]=30
/// age[noteq]=30
/// age[notgeq]=40
/// age[isnull]
/// etc.
/// can prepend "not" onto these comparators:
/// e.g. notlte, noteq
ClassMethod GetWhereSegment(paramBeforeEquals As %String, paramAfterEquals As %String, ByRef queryParams, legalColumns As %DynamicObject) [ Private ]
{
	//map of the text of the comparator in the URL to its sql symbol
	Set comparatorMap = {
		"lte": " < ",
		"gte": " > ",
		"eq": " = ",
		"leq": " <= ",
		"geq": " >= ",
		"stwith": " %startswith ",
		"isnull": " is null"
	}
	
	If '..ValidateSyntax(paramBeforeEquals, paramAfterEquals, comparatorMap) {
		Throw ##class(AppS.REST.Exception.ParameterParsingException).New(paramBeforeEquals_"="_paramAfterEquals)
	}
	
	Set paramName = $Piece(paramBeforeEquals, "[", 1)
	
	// check if this column is available for filtering
	// if you set a displayname to a column name you'll be able to search on it probably
	Set columnName = legalColumns.%Get(paramName)
	
	If (columnName = "") {
		Throw ##class(AppS.REST.Exception.InvalidColumnException).New(paramName)
	}
	
	Set comparatorCode = $piece($piece(paramBeforeEquals, "[", 2), "]", 1)
	Set paramValue = paramAfterEquals
	
	// see if the comparator starts with "not", and If it does, we'll start the clause with a "not"
	Set not = ""
	If ($Extract(comparatorCode, 1, 3) = "not") {
		Set not = "not "
		Set comparatorCode = $Extract(comparatorCode, 4, *)
	}
	
	Set comparator = comparatorMap.%Get(comparatorCode)
	
	If (comparatorCode [ "isnull") {
		Return not _ columnName _ comparator
	}
	
	// put the value of this param in a subscripted array which will eventually be passed to %Execute
	Set queryParams($Increment(queryParams)) = paramValue
	Return not _ columnName _ comparator _ "?"
}

ClassMethod ValidateSyntax(paramBeforeEquals, paramAfterEquals, comparatorMap) [ Private ]
{
	// loop over the comparators we have and create an or'ed regex segement with them
	Set legalOpString = "("
	Set iter = comparatorMap.%GetIterator()			
	While iter.%GetNext(.operatorCode) {
		Set legalOpString = legalOpString _ operatorCode _ "|"
	}
	Set legalOpString = $extract(legalOpString, 1, *-1)_")"
	
	// regex for acceptable formats for URL query parameters	
	// e.g.: "[^\[\]]+\[(not)?(stwith|lte|gte|eq|leq|geq)\]"
	Set correctFormat = "[^\[\]]+\[(not)?" _ legalOpString _ "\]"
	Return $match(paramBeforeEquals, correctFormat)
}

}
