/// Base class for all REST resources
Class AppS.REST.Model.Resource Extends (%RegisteredObject, AppS.REST.Model.ISerializable) [ Abstract, System = 3 ]
{

/// Name of the resource at the REST level
/// Subclasses MUST override this
Parameter RESOURCENAME As STRING [ Abstract ];

/// Name of the parent resource, if any (defaults to empty string)
/// Subclasses MAY override this
Parameter PARENT As STRING;

/// Content-Type implemented in this class
/// Subclasses MAY override this
Parameter MEDIATYPE As STRING = "application/json";

/// Maintains data in <class>AppS.REST.ResourceMap</class> for this class.
Projection ResourceMap As AppS.REST.Model.ResourceMapProjection;

/// Returns an instance of this model, based on the arguments supplied.
ClassMethod GetModelInstance(args...) As AppS.REST.Model.Resource [ Abstract ]
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

/// Invokes a specified action on this model
ClassMethod InvokeModelAction(pAction As %String, pArgs...) [ Abstract ]
{
}

/// Invokes a specified action on an instance of this model
Method InvokeInstanceAction(pAction As %String, pArgs...) [ Abstract ]
{
}

/// Called by the handler when serving plural get requests. <br><br>
/// In the simplest case, the Resrouce is a Proxy and params are just query parameters for querying a table.
ClassMethod GetCollection(ByRef params) [ Abstract ]
{
}

/// Checks the user's permission for a particular operation on a particular record.
/// <var>pOperation</var> may be one of:
/// CREATE
/// READ
/// UPDATE
/// DELETE
/// QUERY
/// ACTION:<action name>
/// <var>pUserContext</var> is supplied by <method>GetUserContext</method>
ClassMethod CheckPermission(pID As %String, pOperation As %String, pUserContext As %RegisteredObject) As %Boolean
{
	Quit 0
}

/// Defines a mapping of actions available for this model class to the associated methods and arguments.
XData ActionMap [ XMLNamespace = "http://www.intersystems.com/apps/rest/action" ]
{
<Actions>
</Actions>
}

Projection Actions As AppS.REST.Model.Action.Projection;

}
