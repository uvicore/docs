---
title: API Authentication
---

# API Authentication

Authentication answers one question: **who is making this request?**  In Uvicore it's a clean two-stage process:

1. The global API authentication middleware runs on every request and loads the user.
2. Route guards and scopes then [authorize](authorization.md) that already-loaded user.

This page covers stage one, *authentication*.  The next page covers stage two, *authorization*.

!!! note
    The Authentication middleware is shared by both Web and API routers.  For the full mechanics, authenticators, user providers, the anonymous fallback, see [Authentication Middleware](../middleware/authentication.md).  This page focuses on the API specifics.

---

## Enabling Authentication

Add the global `Authentication` middleware to your API stack and tell it which route type it is serving.

```python
# acme/wiki/config/http.py
'Authentication': {
    'module': 'uvicore.http.middleware.Authentication',
    'options': {
        'route_type': 'api',
    }
},
```

The middleware loads the `api` auth config, runs one or more authenticators, and stores the resolved user in `request.user` (also available as `request.scope['user']`).

---

## request.user Always Exists

This is a deliberate and important design choice in Uvicore:

> **`request.user` is never `None`.**

- If authentication **succeeds**, it's an authenticated `UserInfo`.
- If authentication **does not** succeed, it becomes the configured **anonymous** user, still a real `UserInfo`.

Because public routes still receive a real user object, you can run permission checks against anonymous roles and permissions without special-casing "is anyone logged in?" everywhere.

```python
@route.get('/welcome')
async def welcome(request: Request):
    user = request.user
    return {'welcome': user.email}
```

---

## Configuring API Auth

API authentication is configured in your `config/auth.py` under the `api` block.

```python
# acme/wiki/config/auth.py
'api': {
    # How anonymous and default users are resolved
    'default_provider': 'user_model',

    # Which auth mechanisms to attempt, in order
    'authenticators': {
        'jwt':   {'default_options': 'jwt'},
        'basic': {'default_options': 'basic'},
    },
},
```

The pieces in play:

- **`default_provider`** - how anonymous users and default lookups are resolved.
- **`authenticators`** - which mechanisms are attempted (JWT, Basic, ...), tried in order.
- **`providers`** - how a validated identity is turned into a `UserInfo` (defined elsewhere in `config/auth.py`).
- **`default_options`** - shared settings for each authenticator type.

!!! tip
    An **authenticator** validates the credentials on the request (a JWT bearer token, Basic auth header).  A **user provider** turns that identity into a `UserInfo`, either by loading a real user (and their roles and permissions) from the database via the ORM provider, or by mapping JWT claims straight into a user with the JWT provider.

---

## The Flow

On each API request, the Authentication middleware:

1. Loads the auth config for `route_type='api'`.
2. Tries each configured authenticator in order.
3. Stops at the first one that returns a valid `UserInfo`.
4. Falls back to the anonymous user if none succeed.
5. Injects `user`, `route_type` and `authenticator` into `request.scope`.

When a user *is* authenticated, Uvicore also makes sure the `authenticated` permission is present in their permissions list, which is what makes `scopes=['authenticated']` such a convenient "any logged-in user" guard.

---

## OAuth2 and the OpenAPI Docs

The `oauth2` settings in `config/auth.py` are used mainly to power the "Authorize" button in your interactive [OpenAPI docs](openapi.md) when `oauth2_enabled` is true.

```python
# acme/wiki/config/auth.py
'oauth2': {
    'client_id': 'xyz',
    'base_url': 'https://idp.example.com',
    'authorize_path': '/oauth2/authorize',
    'token_path': '/oauth2/token',
    'jwks_path': '/.well-known/jwks.json',
}
```

!!! warning
    OAuth2 docs settings are a Swagger UI convenience for trying out your API interactively.  They are **not** a substitute for the actual authentication middleware, that is what truly secures your endpoints.

---

## Putting It Together

A public endpoint that still reads the (possibly anonymous) user:

```python
@route.get('/welcome')
async def welcome(request: Request):
    user = request.user
    return {'welcome': user.email}
```

An authenticated endpoint, JWT middleware plus a route scope:

```python
@route.get('/userinfo', scopes=['authenticated'])
async def userinfo(request: Request):
    return request.user
```

Ready to lock specific endpoints down to specific permissions?  Head to [Authorization](authorization.md).
