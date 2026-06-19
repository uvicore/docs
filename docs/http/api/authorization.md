---
title: API Authorization
---

# API Authorization

Once [authentication](authentication.md) has answered *who* is making the request, authorization answers the next question: **what are they allowed to do?**

Uvicore authorization is built around the `Guard` and flat **permission scopes**.  Notice the framework does not authorize routes by *role* names directly.  Instead, a route requires one or more scopes, and the authenticated user must hold all of them.  Roles map to permissions back in the auth layer, your routes only ever think in terms of scopes.

---

## The Guard

`Guard` is Uvicore's authorization dependency.  It wraps FastAPI's `Security` model and checks the current `request.user` against the scopes a route requires.

```python
from uvicore.http.routing import Guard
```

You rarely instantiate it manually, the shorthands below handle that for you.

---

## Three Ways to Guard a Route

**The `scopes=` shorthand** (simplest and preferred):

```python
@route.get('/userinfo', scopes=['authenticated'])
async def userinfo(request: Request):
    return request.user
```

**The `auth=` shorthand**, when you want to pass a `Guard` explicitly:

```python
@route.get('/admin', auth=Guard(['authenticated', 'admin']))
async def admin(request: Request):
    return {'ok': True}
```

**The full `middleware=` list**, for when a route has other middleware too:

```python
@route.get('/reports', middleware=[Guard(['authenticated', 'reports.read'])])
async def reports(request: Request):
    return []
```

---

## Injecting the User

Use `Guard` as an endpoint *parameter* and you get the best of both worlds, the route is protected *and* the authorized user is handed straight to you.

```python
from uvicore.auth import UserInfo

@route.get('/profile')
async def profile(user: UserInfo = Guard(['authenticated'])):
    return user
```

---

## Where Guards Can Live

You can apply authorization at every level, and Uvicore merges the requirements so they accumulate from parent to child:

- the top-level routes class
- a controller class
- a route group
- an individual route
- an endpoint parameter

```python
# Controller-wide
@uvicore.controller()
class Posts(Controller):
    scopes = ['authenticated', 'posts.read']

# Group-wide
@route.group('/admin', scopes=['authenticated', 'admin'])
def admin():
    route.controller('users')

# Endpoint-specific (adds to whatever the controller/group already require)
@route.delete('/posts/{id}', scopes=['authenticated', 'posts.delete'])
async def delete_post(id: int):
    ...
```

---

## How Scopes Are Evaluated

`Guard` checks permissions with three simple rules:

1. If a route requires **no** scopes, access is allowed.
2. If the user is a **superadmin**, access is always allowed.
3. Otherwise, the user must hold **all** the required scopes.

!!! note
    This is an **AND** check, not OR.  `scopes=['posts.read', 'posts.delete']` means the user needs *both* permissions.

---

## Authenticated vs Authorized

Uvicore is careful to distinguish two different failure modes, and it raises a different exception for each:

- **Not authenticated** - the user is anonymous and the route requires access → `NotAuthenticated`.
- **Authenticated but unauthorized** - the user is logged in but missing one or more required scopes → `PermissionDenied`.

You can customize what happens on an unauthenticated failure in your `config/auth.py`.  Web routes might redirect to a login page; APIs usually raise a structured exception, optionally with headers (handy for prompting a browser Basic-auth dialog).

```python
# acme/wiki/config/auth.py
'unauthenticated_handler': {
    'exception': {
        'headers': {
            'WWW-Authenticate': 'Basic realm="Acme Wiki Realm"'
        },
    },
},
```

See [HTTP Exceptions](../exceptions/concepts.md) for more on how these errors are rendered.

---

## Thinking in Scopes

Because authorization is permission-based, your routes and your users speak the same flat language:

- routes declare the scopes they require
- users expose a flat `permissions` list
- role-to-permission mapping happens in the auth layer / [user provider](../middleware/authentication.md), never in the router

So your controllers think in terms of scopes like `authenticated`, `posts.read`, `posts.create` and `admin`, the same scopes the [Model Router](model-router.md) uses for its automatic CRUD endpoints.

!!! tip "Authorization tips"
    - Guard with **scopes**, not hardcoded role names.
    - Put shared rules at the **controller or group** level; reserve endpoint-level scopes for the more specific requirements.
    - Treat `superadmin` as an emergency bypass, not as your primary authorization model.
    - Keep permission naming consistent across your hand-written and auto-API endpoints.
