/// This class is internal to AppS.REST; consumers should not use or reference it directly.
Class AppS.REST.Model.Action.SASchema Extends AppS.Util.SASchemaClass
{

/// This is the namespace value used to identify this SA schema.
/// This corresponds to the XMLNamespace keyword of a Studio XData block.
Parameter XMLNAMESPACE As STRING = "http://www.intersystems.com/apps/rest/action";

/// This is comma-separated list of the classes whose xml elements
/// can be used as the root level element of a document.
Parameter ROOTCLASSES As STRING = "AppS.REST.Model.Action.t.actions:actions";

}
