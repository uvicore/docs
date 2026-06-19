---
title: Web Authentication
---

# Web Authentication

Authentication answers *who* is making the request.  For web routes it works exactly like it does for the [API](../api/authentication.md), a global middleware identifies the user on every request, then route guards [authorize](authorization.md) that user, with one lovely extra: web routes can **redirect** unauthenticated visitors to a login page instead of returning a raw error.

!!! note
    The Authentication middleware is shared by both routers.  For the full mechanics, authenticators, user providers, the anonymous fallback, see [Authentication Middleware](../middleware/authentication.md).  This page focuses on the web specifics.

---

## Enabling Authentication

Add the `Authentication` middleware to your web stack and set its `route_type` to `web`.

```python
# acme/wiki/config/http.py
'Authentication': {
    'module': 'uvicore.http.middleware.Authentication',
    'options': {
        'route_type': 'web',
    }
},
```

The middleware loads the `web` auth config, runs your authenticators, and stores the resolved user in `request.user`.

---

## request.user Always Exists

Just like the API, `request.user` is **never `None`**.  If authentication succeeds it's an authenticated `UserInfo`; otherwise it's the configured **anonymous** user, still a real `UserInfo`.  Your public pages can read `request.user` and check permissions without special-casing logged-out visitors.

```python
@route.get('/', name='home')
async def home(request: Request):
    user = request.user
    return await response.View('wiki/home.j2', {
        'request': request,
        'greeting': f'Hello, {user.name}!',
    })
```

---

## Configuring Web Auth

Web authentication is configured in your `config/auth.py` under the `web` block.

```python
# acme/wiki/config/auth.py
'web': {
    'default_provider': 'user_model',
    'authenticators': {
        'basic': {'default_options': 'basic'},
    },
    'unauthenticated_handler': {
        'redirect': 'wiki.login',   # route name (or a full URL)
    },
},
```

The pieces in play:

- **`default_provider`** - how anonymous and default users are resolved.
- **`authenticators`** - which mechanisms are attempted, in order.
- **`providers`** - how a validated identity becomes a `UserInfo` (defined elsewhere in `config/auth.py`).
- **`unauthenticated_handler`** - what happens when auth fails (redirect, or raise an exception).

---

## Redirect on Failed Authentication

This is the big difference from the API.  For user-facing web routes, you usually want to send an unauthenticated visitor to your login page rather than throwing an error.  Configure `unauthenticated_handler.redirect` with a route name (one containing a `.`) or a full URL (one containing a `/`).

```python
# acme/wiki/config/auth.py
'unauthenticated_handler': {
    # A route NAME (has a dot, no slash)
    'redirect': 'wiki.login',

    # ...or a full URL (has a slash) to an external IdP
    # 'redirect': 'https://idp.example.com/login',

    # Optionally throw with custom headers instead of redirecting
    # (handy for prompting a browser Basic-auth dialog)
    'exception': {
        'headers': {'WWW-Authenticate': 'Basic realm="Acme Wiki Realm"'},
    },
},
```

When a redirect is configured, the visitor's current URL is preserved as a `?referer=` query parameter so you can send them back where they came from after they log in.

---

## Putting It Together

A public page that reads the (possibly anonymous) user:

```python
@route.get('/', name='home')
async def home(request: Request):
    return await response.View('wiki/home.j2', {
        'request': request,
        'greeting': f'Hello, {request.user.name}!',
    })
```

A protected page that redirects logged-out visitors to login:

```python
@route.get('/dashboard', name='dashboard', scopes=['authenticated'])
async def dashboard(request: Request):
    return await response.View('wiki/dashboard.j2', {'request': request})
```

Ready to lock pages down to specific permissions?  Head to [Authorization](authorization.md).

!!! tip
    Use **redirect-on-failure** for user-facing web routes and **exception-on-failure** for API-style routes.  Keep your authenticator ordering intentional, and let [user providers](../middleware/authentication.md) normalize users into `UserInfo` instead of scattering auth logic across controllers.
