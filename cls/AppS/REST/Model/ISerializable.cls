/// Interface for JSON-serializable/deserializable objects.
Class AppS.REST.Model.ISerializable [ Abstract, System = 3 ]
{

Parameter MEDIATYPE = "application/json";

/// JSONImport imports JSON or dynamic object input into this object.<br />
/// The input argument is either JSON as a string or stream, or a subclass of %DynamicAbstractObject.
Method JSONImport(input) As %Status [ Abstract ]
{
}

/// Serialize a JSON enabled class as a JSON document and write it to the current device.
Method JSONExport() As %Status [ Abstract ]
{
}

/// Serialize a JSON enabled class as a JSON document and write it to a stream.
Method JSONExportToStream(ByRef export As %Stream.Object) As %Status [ Abstract ]
{
}

/// Serialize a JSON enabled class as a JSON document and return it as a string.
Method JSONExportToString(ByRef %export As %String) As %Status [ Abstract ]
{
}

}
