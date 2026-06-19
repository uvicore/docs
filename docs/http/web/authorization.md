---
title: Web Authorization
---

# Web Authorization

Once [authentication](authentication.md) has answered *who* is visiting, authorization answers *what they're allowed to see and do*.  Web authorization works exactly like the [API](../api/authorization.md): it's built around the `Guard` and flat **permission scopes**, and your routes think in terms of scopes, never role names directly.

---

## The Guard

`Guard` is Uvicore's authorization dependency.  It wraps FastAPI's `Security` model and checks the current `request.user` against the scopes a route requires.

```python
from uvicore.http.routing import Guard
```

You rarely instantiate it yourself, the shorthands below do that for you.

---

## Three Ways to Guard a Route

**The `scopes=` shorthand** (simplest and preferred):

```python
@route.get('/dashboard', name='dashboard', scopes=['authenticated'])
async def dashboard(request: Request):
    return await response.View('wiki/dashboard.j2', {'request': request})
```

**The `auth=` shorthand:**

```python
@route.get('/admin', name='admin', auth=Guard(['authenticated', 'admin']))
async def admin(request: Request):
    return await response.View('wiki/admin.j2', {'request': request})
```

**The full `middleware=` list:**

```python
@route.get('/reports', name='reports', middleware=[Guard(['authenticated', 'reports.read'])])
async def reports(request: Request):
    return await response.View('wiki/reports.j2', {'request': request})
```

---

## Injecting the User

Use `Guard` as an endpoint parameter and the route is protected *and* the authorized user is handed straight to you.

```python
from uvicore.auth import UserInfo

@route.get('/profile', name='profile')
async def profile(request: Request, user: UserInfo = Guard(['authenticated'])):
    return await response.View('wiki/profile.j2', {'request': request, 'user': user})
```

---

## Where Guards Can Live

Apply authorization at any level, Uvicore *merges* the requirements so they accumulate from parent to child:

```python
# Controller-wide
@uvicore.controller()
class AdminPanel(Controller):
    scopes = ['authenticated', 'admin']

# Group-wide
@route.group('/admin', scopes=['authenticated', 'admin'])
def admin():
    route.controller('dashboard')

# Endpoint-specific (adds to controller/group scopes)
@route.delete('/users/{id}', name='user.delete', scopes=['authenticated', 'users.delete'])
async def delete_user(request: Request, id: int):
    ...
```

---

## How Scopes Are Evaluated

`Guard` checks permissions with three simple rules:

1. If a route requires **no** scopes, access is allowed.
2. If the user is a **superadmin**, access is always allowed.
3. Otherwise, the user must hold **all** the required scopes.

!!! note
    This is an **AND** check, not OR.  `scopes=['posts.read', 'posts.delete']` means the user needs *both*.

---

## Authenticated vs Authorized

Uvicore distinguishes two failure modes:

- **Not authenticated** - the visitor is anonymous and the route requires access.  For web routes this typically **redirects** to your login page (if [configured](authentication.md#redirect-on-failed-authentication)), otherwise raises `NotAuthenticated`.
- **Authenticated but unauthorized** - the user is logged in but missing a required scope → `PermissionDenied`.

---

## Checking Permissions in Templates

Show or hide UI based on what the current user can do.  `UserInfo` exposes `can()`, `can_any()` and `is_authenticated`, and you can always inspect the flat `permissions` list directly.

```html
{% if request.user.can('reports.read') %}
  <a href="{{ url('wiki.reports') }}">View Reports</a>
{% endif %}

{% if 'admin' in request.user.permissions %}
  <a href="{{ url('wiki.admin') }}">Admin</a>
{% endif %}
```

---

!!! tip "Authorization tips"
    - Guard with **scopes**, not hardcoded role names.
    - Put shared rules at the **controller or group** level; reserve endpoint scopes for the specific cases.
    - Treat `superadmin` as an emergency bypass, not your primary authorization model.
    - Check permissions in templates to conditionally render UI, but still guard the route itself, never rely on a hidden link alone.
