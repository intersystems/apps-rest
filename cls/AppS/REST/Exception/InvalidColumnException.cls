Class AppS.REST.Exception.InvalidColumnException Extends QueryGenerationException [ System = 3 ]
{

Parameter ExceptionName = "<Invalid Column>";

Parameter HTTPErrorCode = "403 Unauthorized";

Method DisplayMessage() As %String
{
	Return "Access to column '"_..Content_"' is not permitted."
}

}
