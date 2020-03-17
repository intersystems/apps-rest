Class AppS.REST.Documentation.Generator
{

ClassMethod GetSwagger(pVersion As %String = "2.0", pRequest As %CSP.Request = {$Get(%request)}) As %Status
{
	Set sc = $$$OK
	Try {
		If (pVersion = "2.0") {
			Set obj = ..GetSwagger2(pRequest)
		} Else {
			$$$ThrowStatus($$$ERROR($$$GeneralError,"Unsupported Swagger/OpenAPI Version: "_pVersion))
		}
		Set %response.ContentType = "application/json"
		Do obj.%ToJSON()
	} Catch e {
		Set sc = e.AsStatus()
	}
	Quit sc
}

ClassMethod GetSwagger2(pRequest As %CSP.Request) As %DynamicObject [ Internal ]
{
	Set restApplication = ##class(%SYS.REST).GetRESTApplication(pRequest.Application)
	If '$IsObject(restApplication) {
		$$$ThrowStatus($$$ERROR($$$GeneralError,"Application '"_pRequest.Application_"' is not REST-enabled."))
	}
	Set dispatchClass = restApplication.dispatchClass
	
	// TODO: Get info from request's application by dispatch class; for now, boilerplate.
	Set info = {
		"version": "1.0.0",
		"title": "AppS.REST Application",
		"description": ("AppS.REST-based application for "_pRequest.Application),
		"termsOfService": "You can't use this API.",
		"contact": {
			"name": "System Administrator"
		},
		"license": {
			"name": "MIT"
		}
	}
	
	// Basic info based on request.
	Set host = pRequest.GetCgiEnv("HTTP_HOST")
	Set basePath = pRequest.Application
	Set scheme = $Select(pRequest.Secure:"https",1:"http")
	
	Set paths = ..EnumeratePathsV2(.modelClasses)
	Set definitions = ..EnumerateDefinitionsV2(.modelClasses)
	
	Quit {
		"swagger": "2.0",
		"info": (info),
		"host": (host),
		"basePath": (basePath),
		"schemes": [(scheme)],
		"consumes": ["application/json"],
		"produces": ["application/json"],
		"paths": (paths),
		"definitions": (definitions)
	}
}

ClassMethod EnumeratePathsV2(Output modelClasses) As %DynamicObject [ Internal ]
{
	Set result = {}
	Do ..EnumerateBasicPathsV2(result, .modelClasses)
	Do ..EnumerateActionPathsV2(result, .modelClasses)
	Quit result
	
	// For reference:
	Quit {
	    "/pets": {
	      "get": {
	        "description": "Returns all pets from the system that the user has access to",
	        "operationId": "findPets",
	        "produces": [
	          "application/json",
	          "application/xml",
	          "text/xml",
	          "text/html"
	        ],
	        "parameters": [
	          {
	            "name": "tags",
	            "in": "query",
	            "description": "tags to filter by",
	            "required": false,
	            "type": "array",
	            "items": {
	              "type": "string"
	            },
	            "collectionFormat": "csv"
	          },
	          {
	            "name": "limit",
	            "in": "query",
	            "description": "maximum number of results to return",
	            "required": false,
	            "type": "integer",
	            "format": "int32"
	          }
	        ],
	        "responses": {
	          "200": {
	            "description": "pet response",
	            "schema": {
	              "type": "array",
	              "items": {
	                "$ref": "#/definitions/Pet"
	              }
	            }
	          },
	          "default": {
	            "description": "unexpected error",
	            "schema": {
	              "$ref": "#/definitions/ErrorModel"
	            }
	          }
	        }
	      },
	      "post": {
	        "description": "Creates a new pet in the store.  Duplicates are allowed",
	        "operationId": "addPet",
	        "produces": [
	          "application/json"
	        ],
	        "parameters": [
	          {
	            "name": "pet",
	            "in": "body",
	            "description": "Pet to add to the store",
	            "required": true,
	            "schema": {
	              "$ref": "#/definitions/NewPet"
	            }
	          }
	        ],
	        "responses": {
	          "200": {
	            "description": "pet response",
	            "schema": {
	              "$ref": "#/definitions/Pet"
	            }
	          },
	          "default": {
	            "description": "unexpected error",
	            "schema": {
	              "$ref": "#/definitions/ErrorModel"
	            }
	          }
	        }
	      }
	    },
	    "/pets/{id}": {
	      "get": {
	        "description": "Returns a user based on a single ID, if the user does not have access to the pet",
	        "operationId": "findPetById",
	        "produces": [
	          "application/json",
	          "application/xml",
	          "text/xml",
	          "text/html"
	        ],
	        "parameters": [
	          {
	            "name": "id",
	            "in": "path",
	            "description": "ID of pet to fetch",
	            "required": true,
	            "type": "integer",
	            "format": "int64"
	          }
	        ],
	        "responses": {
	          "200": {
	            "description": "pet response",
	            "schema": {
	              "$ref": "#/definitions/Pet"
	            }
	          },
	          "default": {
	            "description": "unexpected error",
	            "schema": {
	              "$ref": "#/definitions/ErrorModel"
	            }
	          }
	        }
	      },
	      "delete": {
	        "description": "deletes a single pet based on the ID supplied",
	        "operationId": "deletePet",
	        "parameters": [
	          {
	            "name": "id",
	            "in": "path",
	            "description": "ID of pet to delete",
	            "required": true,
	            "type": "integer",
	            "format": "int64"
	          }
	        ],
	        "responses": {
	          "204": {
	            "description": "pet deleted"
	          },
	          "default": {
	            "description": "unexpected error",
	            "schema": {
	              "$ref": "#/definitions/ErrorModel"
	            }
	          }
	        }
	      }
	    }
	  }
}

ClassMethod EnumerateBasicPathsV2(target As %DynamicObject, Output modelClasses) [ Internal ]
{
	// Boilerplate paths:
	
	// /auth/status
	
	// /auth/logout
	
	// Resources:
	Set query = "select MediaType, ModelClass, ResourceName from AppS_REST.ResourceMap"
	Set result = ##class(%SQL.Statement).%ExecDirect(,query)
	If (result.%SQLCODE < 0) {
		Throw ##class(%Exception.SQL).CreateFromSQLCODE(result.%SQLCODE,result.%Message)
	}
	While result.%Next(.sc) {
		$$$ThrowOnError(sc)
		
		Set resource = result.ResourceName
		Set mediaType = result.MediaType
		Set modelClass = result.ModelClass
		
		// GET /:resource (QUERY)
		Set query = {}
		
		// POST /:resource (CREATE)
		Set create = {}
		
		Set $Property(target,"/"_resource) = {
			"get": (query),
			"post": (create)
		}
		
		// GET /:resource/$new (CONSTRUCT)
		Set construct = {}
		Set $Property(target,"/"_resource_"/$new") = {
			"get": (construct)
		}
		
		// GET /:resource/:id (READ)
		Set read = {}
		
		// PUT /:resource/:id (UPDATE)
		Set update = {}
		
		// DELETE /:resource/:id (DELETE)
		Set delete = {}
		
		Set $Property(target,"/"_resource_"/{id}") = {
			"get": (read),
			"put": (update),
			"delete": (delete)
		}
	}
	$$$ThrowOnError(sc)
}

ClassMethod EnumerateActionPathsV2(target As %DynamicObject, Output modelClasses) [ Internal ]
{
	// TODO!
}

ClassMethod EnumerateDefinitionsV2(ByRef modelClasses) [ Internal ]
{
	Quit {
	    "Pet": {
	      "type": "object",
	      "allOf": [
	        {
	          "$ref": "#/definitions/NewPet"
	        },
	        {
	          "required": [
	            "id"
	          ],
	          "properties": {
	            "id": {
	              "type": "integer",
	              "format": "int64"
	            }
	          }
	        }
	      ]
	    },
	    "NewPet": {
	      "type": "object",
	      "required": [
	        "name"
	      ],
	      "properties": {
	        "name": {
	          "type": "string"
	        },
	        "tag": {
	          "type": "string"
	        }
	      }
	    },
	    "ErrorModel": {
	      "type": "object",
	      "required": [
	        "code",
	        "message"
	      ],
	      "properties": {
	        "code": {
	          "type": "integer",
	          "format": "int32"
	        },
	        "message": {
	          "type": "string"
	        }
	      }
	    }
	  }
}

}
