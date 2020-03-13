/// This class is internal to AppS.REST; consumers should not use or reference it directly.
Class AppS.REST.Model.Action.t.argument Extends (%RegisteredObject, %XML.Adaptor) [ System = 2 ]
{

Parameter XMLIGNOREINVALIDATTRIBUTE As BOOLEAN = 0;

Parameter NAMESPACE As STRING = "http://www.intersystems.com/apps/rest/action";

/// Name of the parameter (used in URLs)
Property name As %String(XMLPROJECTION = "attribute");

/// Whether the the parameter value comes from the body, the URL, or (for instance actions) the ID of the object in question; default is 'url'
Property source As %String(VALUELIST = ",body,url,id", XMLPROJECTION = "attribute") [ InitialExpression = "url", Required ];

/// Target parameter in the method/query
Property target As %String(XMLPROJECTION = "attribute") [ Required ];

/// True if the argument is required (if not specified, it's a problem with the client)
Property required As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0, Required ];

}
