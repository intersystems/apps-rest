Class AppS.REST.Exception.ParameterParsingException Extends QueryGenerationException [ System = 3 ]
{

Parameter ExceptionName = "<Parameter Syntax Incorrect>";

Method DisplayMessage() As %String
{
	Return "The parameter value '" _ ..Content _ "' could not be parsed."
}

}
