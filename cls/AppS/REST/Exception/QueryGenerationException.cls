Class AppS.REST.Exception.QueryGenerationException Extends %Exception.AbstractException [ Abstract, System = 3 ]
{

Parameter ExceptionName [ Abstract ];

Parameter HTTPErrorCode = "400 Bad Request";

Property Content As %String [ Private ];

Property ErrorStatus As %String;

Method DisplayString() As %String
{
  	Quit "Invalid query. " _ ..DisplayMessage()
}

/// Appended to the end of DisplayString(); should be overwritten by subclasses to showcase information about the failure
Method DisplayMessage() As %String
{
	Quit ""
}

ClassMethod New(content As %String, errorStatus As %String = {..#HTTPErrorCode}) As QueryGenerationException
{
	Set e = ..%New($Parameter($This,"ExceptionName"))
	Set e.Content = content
	Set e.ErrorStatus = errorStatus
	Quit e
}

}
