---
title: Authentication Middleware
---

# Authentication Middleware

The `Authentication` middleware is the piece of Uvicore that figures out *who is making the request*.  It runs early in the [middleware](concepts.md) stack on every request, identifies the user, and makes that user available to the rest of your application as `request.user`.

It is the **authentication** half of HTTP security (who are you?).  The **authorization** half (what are you allowed to do?) is handled separately by route guards and scopes, covered in the [API Authorization](../api/authorization.md) and [Web Authorization](../web/authorization.md) pages.

!!! note
    This page explains how the middleware works in general.  For route-type specifics, see [API Authentication](../api/authentication.md) and [Web Authentication](../web/authentication.md).

---

## Enabling

Authentication is enabled by adding the middleware to your `config/http.py` stack, once for the `web` router and/or once for the `api` router.  The only required option is the `route_type`, which tells the middleware which `auth` config block to load.

```python
# config/http.py
'Authentication': {
    'module': 'uvicore.http.middleware.Authentication',
    'options': {
        'route_type': 'api',   # 'web' or 'api'
    }
},
```

If you don't need user-aware behavior, simply leave this middleware commented out.

---

## request.user Always Exists

This is an important and deliberate design choice in Uvicore:

> **`request.user` is never `None`.**

- If authentication **succeeds**, `request.user` is the authenticated `UserInfo`.
- If authentication **does not** succeed, `request.user` becomes the configured **anonymous** user, still a real `UserInfo` object.

```python
@route.get('/welcome')
async def welcome(request: Request):
    user = request.user          # always a UserInfo, even for anonymous visitors
    return {'welcome': user.email}
```

Because anonymous visitors are still real users (with their own roles and permissions), your public routes behave consistently and your [authorization](../api/authorization.md) checks work the same whether someone is logged in or not.

---

## Authenticators & User Providers

The middleware delegates the actual work to two pluggable pieces, both configured in your `config/auth.py`:

**Authenticators** validate the credentials on the incoming request.  Uvicore ships with:

- **Basic** - HTTP Basic auth (username / password)
- **JWT** - Bearer token validation, ideal for any standards-based IdP (FusionAuth, Keycloak, Auth0, Okta...)

**User Providers** turn that validated identity into a `UserInfo` object.  Uvicore ships with:

- **ORM** - loads a real user (with roles, groups and permissions) from your database
- **JWT** - builds the user directly from the token's claims, no database required

You can configure multiple authenticators, they are tried in order until one succeeds.

```python
# config/auth.py (api block)
'api': {
    'default_provider': 'user_model',
    'authenticators': {
        'jwt':   {'default_options': 'jwt'},
        'basic': {'default_options': 'basic'},
    },
},
```

---

## The Flow

On every request, the Authentication middleware:

1. Loads the `auth` config for its `route_type` (`web` or `api`).
2. Tries each configured authenticator in order.
3. Stops at the first authenticator that returns a valid `UserInfo`.
4. Falls back to the configured **anonymous** user if none succeed.
5. Injects `user`, `route_type` and `authenticator` into the request scope.

When a user *is* authenticated, Uvicore also ensures the `authenticated` permission is present in their permissions list, which makes guarding "any logged-in user" as simple as `scopes=['authenticated']`.

---

## Accessing the User

```python
# The convenient way
user = request.user

# The explicit scope key (identical object)
user = request.scope['user']
```

The `UserInfo` object carries everything you need for authorization:

```python
user.id
user.email
user.roles            # ['Administrator', ...]
user.permissions      # ['posts.read', 'posts.create', ...]
user.superadmin       # bool, superadmins bypass all permission checks
user.authenticated    # bool

# Permission helpers
user.can('posts.read')                 # True if user has ALL given permissions
user.can_any(['posts.read', 'admin'])  # True if user has ANY
```

!!! tip
    Build a custom authenticator or user provider by mirroring the framework's own implementations.  See the [Authentication middleware source](https://github.com/uvicore/framework/blob/master/uvicore/http/middleware/authentication.py) and the `uvicore/auth/authenticators` and `uvicore/auth/user_providers` packages for reference.

---

## Debugging

As with all [middleware](concepts.md), `dump()` and `dd()` do not work inside the request pipeline.  Use the logger instead and watch the output in the terminal running `./uvicore http serve`:

```python
uvicore.log.dump(request.user)
```
