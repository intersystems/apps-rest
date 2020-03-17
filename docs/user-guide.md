# AppS.REST User Guide

## Prerequisites

AppS.REST requires InterSystems IRIS Data Platform 2018.1 or later.

Installation is done via the [Community Package Manager](https://github.com/intersystems-community/zpm):

    zpm "install apps.rest"

## Getting Started

### Create and Configure a REST Handler

Create a subclass of `AppS.REST.Handler`. AppS.REST extends %CSP.REST, and for the most part this subclass may include overrides the same as a subclass of %CSP.REST.

For example, a user may add overrides to use the following %CSP.REST features:
* The `UseSession` class parameter if CSP sessions should be used (by default, they are not, as they are not stateless).
* CORS-related parameters and methods if CORS support is required.

However, **do not override the UrlMap XData block**; the routes are standardized and you should not need to edit/amend them.

To augment an existing REST API with AppS.REST features, forward a URL from your existing REST handler to this subclass of AppS.REST.Handler.

To create a new AppS.REST-based REST API, configure the subclass of AppS.REST.Handler as the Dispatch Class for a new web application.

### Define an Authentication Strategy

If the web application uses password or delegated authentication, simply override the AuthenticationStrategy() method in the REST handler class as follows:

    ClassMethod AuthenticationStrategy() As %Dictionary.CacheClassname
    {
        Quit "AppS.REST.Authentication.PlatformBased"
    }

If not (for example, because of a more complex token-based approach such as OAuth that does not use delegated authentication/authorization), create a subclass of `AppS.REST.Authentication` and override the `Authenticate`, `UserInfo`, and `Logout` methods as appropriate.
For example, `Authenticate` might check for a bearer token and set `pContinue` to false if one is not present; `UserInfo` may return an OpenID Connect "userinfo" object, and `Logout` may invalidate/revoke an access token. In this case, the `AuthenticationStrategy` method in the `AppS.REST.Handler` subclass should return the name of the class implementing the authentication strategy.

### Define a User Resource

If the application already has a class representing the user model, preferences, etc., consider providing a REST model for it as described below. Alternatively, for simple use cases, you may find it helpful to wrap platform security features in a registered object; see [UnitTest.AppS.REST.Sample.UserContext.cls](https://github.com/intersystems/apps-rest/blob/master/internal/testing/unit_tests/UnitTest/AppS/REST/Sample/UserContext.cls) for an example of this.

In either approach, the `GetUserResource` method in the application's `AppS.REST.Handler` subclass should be overridden to return a new instance of this user model. For example:

    ClassMethod GetUserResource(pFullUserInfo As %DynamicObject) As UnitTest.AppS.REST.Sample.UserContext
    {
      Quit ##class(UnitTest.AppS.REST.Sample.UserContext).%New()
    }

## Defining REST Models

### Adaptor vs. Proxy

### Permissions

### CRUD and Query Support

### Actions

## Related Topics in InterSystems Documentation

(Using the JSON Adaptor)[https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GJSON_adaptor]
(Introduction to Creating REST Services)[https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GREST_intro]
(Supporting CORS in REST Services)[https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GREST_cors]
(Securing REST Services)[https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GREST_securing]
