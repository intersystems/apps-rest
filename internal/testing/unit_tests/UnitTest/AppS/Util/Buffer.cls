Include %callout

/// Note: assertions are generally made *after* tests involving output capture to avoid unit test assertions being written to the string buffer.
Class UnitTest.AppS.Util.Buffer Extends %UnitTest.TestCase
{

Method TestReadToString()
{
	Set tStringBuffer = ##class(AppS.Util.Buffer).%New()
	Do $$$AssertStatusOK(tStringBuffer.ReadToString(.tEmptyString))
	Do $$$AssertEquals(tEmptyString, "")
	Set tSC1 = tStringBuffer.BeginCaptureOutput()
	Write "This is a test string."
	Set tSC2 = tStringBuffer.EndCaptureOutput(.tOutput)
	
	Do $$$AssertStatusOK(tSC1)
	Do $$$AssertStatusOK(tSC2)
	Do $$$AssertEquals(tOutput,"This is a test string.")
}

Method TestReadToStringException()
{
	// Error case: exception thrown
	Set tStringBuffer = ##class(AppS.Util.Buffer).%New()
	Set tSC1 = tStringBuffer.BeginCaptureOutput()
	Do ..UtilCloseStringBufferDevice(tStringBuffer)
	Set tSC2 = tStringBuffer.EndCaptureOutput(.tOutput)
	Do $$$AssertStatusOK(tSC1)
	Do $$$AssertStatusNotOK(tSC2)
	Do $$$AssertTrue($System.Status.Equals(tSC2,$$$ERRORCODE($$$CacheError)))
}

Method TestReadToStream()
{
	// Normal cases: temp binary stream, file character stream
	For tOutput = ##class(%Stream.TmpBinary).%New(),##class(%Stream.FileCharacter).%New() {
		Set tStringBuffer = ##class(AppS.Util.Buffer).%New()
		Do $$$AssertStatusOK(tStringBuffer.ReadToStream(.tEmptyStream))
		Do $$$AssertEquals(tEmptyStream.Read(), "")
		Set tSC1 = tStringBuffer.BeginCaptureOutput()
		Write "This is a test string."
		Set tSC2 = tStringBuffer.EndCaptureOutput(.tOutput)
		
		Do $$$AssertStatusOK(tSC1)
		Do $$$AssertStatusOK(tSC2)
		Do $$$AssertEquals(tOutput.Read(),"This is a test string.")
	}
}

Method TestReadToStreamWriteFails()
{
	// Error case: file can't be written to (we'll delete it)
	Set tOutput = ##class(%Stream.FileCharacter).%New()
	Do tOutput.Write("")
	Set tStringBuffer = ##class(AppS.Util.Buffer).%New()
	Set tOutput.%Location = tOutput.Filename
	If ##class(%Library.File).Exists(tOutput.%Location) {
		Do $$$AssertTrue(##class(%Library.File).Delete(tOutput.%Location))
	}
	Do $$$AssertTrue(##class(%Library.File).CreateDirectory(tOutput.%Location))
	Set tOutput.Filename = ##class(%Library.File).NormalizeFilename("foo.txt",tOutput.%Location)
	Do $$$AssertTrue(##class(%Library.File).RemoveDirectory(tOutput.%Location))
	Set tSC1 = tStringBuffer.BeginCaptureOutput()
	Set tSC2 = tStringBuffer.ReadToStream(.tOutput)
	Set tSC3 = tStringBuffer.EndCaptureOutput()
	Do $$$AssertStatusOK(tSC1)
	Do $$$AssertStatusOK(tSC3)
	Do $$$AssertStatusNotOK(tSC2)
	Do $$$AssertTrue($System.Status.Equals(tSC2,$$$ERRORCODE($$$FileCanNotOpen)))
}

Method TestReadToStreamException()
{
	// Error case: exception thrown
	Set tOutput = ##class(%Stream.FileCharacter).%New()
	Set tStringBuffer = ##class(AppS.Util.Buffer).%New()
	Set tSC1 = tStringBuffer.BeginCaptureOutput()
	Do ..UtilCloseStringBufferDevice(tStringBuffer)
	Set tSC2 = tStringBuffer.EndCaptureOutput(.tOutput)
	Do $$$AssertStatusOK(tSC1)
	Do $$$AssertStatusNotOK(tSC2)
	Do $$$AssertTrue($System.Status.Equals(tSC2,$$$ERRORCODE($$$CacheError)))
}

Method TestBeginCaptureOutputBadTranslateTable()
{
	Set tStringBuffer = ##class(AppS.Util.Buffer).%New()
	Set tStringBuffer.TranslateTable = "SomethingBad"
	Set tSC = tStringBuffer.BeginCaptureOutput()
	Do $$$AssertStatusNotOK(tSC)
	Do $$$AssertTrue($System.Status.Equals(tSC,$$$ERRORCODE($$$CacheError)))
}

Method TestEndCaptureOutputException()
{
	// TODO: Fix for IRIS
	/*
	Set tFile = ##class(%Library.File).TempFilename()
	Open tFile:"WNS"
	Use tFile
	Set tStringBuffer = ##class(AppS.Util.Buffer).%New()
	Set tSC1 = tStringBuffer.BeginCaptureOutput()
	Close tFile:"D"
	Set tSC2 = tStringBuffer.EndCaptureOutput()
	Do $$$AssertStatusOK(tSC1)
	Do $$$AssertStatusNotOK(tSC2)
	Do $$$AssertTrue($System.Status.Equals(tSC2,$$$ERRORCODE($$$CacheError)))
	*/
}

Method TestOnClose()
{
	Set tSC = $$$OK
	Try {
		Set tOldDevice = $io
		Set tStringBuffer = ##class(AppS.Util.Buffer).%New()
		Set tSC1 = tStringBuffer.BeginCaptureOutput()
		Kill tStringBuffer
		Set tAfterDevice = $io
		Do $$$AssertStatusOK(tSC1)
		Do $$$AssertEquals(tAfterDevice,tOldDevice)
	} Catch e {
		Set tSC = e.AsStatus()
	}
	Do $$$AssertStatusOK(tSC,"No exceptions occurred.")
}

Method TestChangeCarriageReturnMode()
{
	Set tStringBuffer = ##class(AppS.Util.Buffer).%New()
	Do $$$AssertEquals(tStringBuffer.CarriageReturnMode,1)
	Set tSC1 = tStringBuffer.BeginCaptureOutput()
	Set tStringBuffer.CarriageReturnMode = 0
	Set tSC2 = tStringBuffer.EndCaptureOutput()
	Do $$$AssertEquals(tStringBuffer.CarriageReturnMode,0)
	Do $$$AssertStatusOK(tSC1)
	Do $$$AssertStatusOK(tSC2)
}

Method TestChangeCarriageReturnModeException()
{
	Set tStringBuffer = ##class(AppS.Util.Buffer).%New()
	Do $$$AssertEquals(tStringBuffer.CarriageReturnMode,1)
	Set tSC1 = tStringBuffer.BeginCaptureOutput()
	Do ..UtilCloseStringBufferDevice(tStringBuffer)
	Set tStringBuffer.CarriageReturnMode = 0
	Do $$$AssertStatusOK(tSC1)
	Do $$$AssertEquals(tStringBuffer.CarriageReturnMode,1)
}

Method TestChangeTranslateTable()
{
	Set tStringBuffer = ##class(AppS.Util.Buffer).%New()
	Do $$$AssertEquals(tStringBuffer.TranslateTable,"UTF8")
	Set tSC1 = tStringBuffer.BeginCaptureOutput()
	Set tStringBuffer.TranslateTable = "RAW"
	Set tSC2 = tStringBuffer.EndCaptureOutput()
	Do $$$AssertEquals(tStringBuffer.TranslateTable,"RAW")
	Do $$$AssertStatusOK(tSC1)
	Do $$$AssertStatusOK(tSC2)
}

Method TestChangeTranslateTableInvalid()
{
	Set tStringBuffer = ##class(AppS.Util.Buffer).%New()
	Do $$$AssertEquals(tStringBuffer.TranslateTable,"UTF8")
	Set tSC1 = tStringBuffer.BeginCaptureOutput()
	Set tStringBuffer.TranslateTable = "SomethingBad"
	Set tSC2 = tStringBuffer.EndCaptureOutput()
	Do $$$AssertEquals(tStringBuffer.TranslateTable,"UTF8")
	Do $$$AssertStatusOK(tSC1)
	Do $$$AssertStatusOK(tSC2)
}

/// Called to close the device the string buffer is trying to use.
/// This is useful to trigger various error conditions
Method UtilCloseStringBufferDevice(pStringBuffer As AppS.Util.Buffer)
{
	// This should match the device name set in AppS.Util.Buffer:%OnNew
	Close "|XDEV|"_(+pStringBuffer)
}

}
