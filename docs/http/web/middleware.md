---
title: Web Middleware
---

# Web Middleware

Middleware wraps every request flowing into your web pages, handling cross-cutting concerns like trusted hosts, HTTPS redirects, compression and [authentication](authentication.md) before your route runs.

As with the API, **the running application owns the global middleware stack, not individual packages.**  Packages register their routes; the app being served decides which global middleware wraps them.  This keeps packages portable.

!!! note
    This page covers the Web stack specifically.  For the shared concepts behind Uvicore middleware (and how to write your own), see [Middleware Concepts](../middleware/concepts.md).

---

## Where Web Middleware Lives

The global web middleware stack is defined in your `config/http.py` under `web.middleware`.  It's an `OrderedDict`, so the order you list middleware is the order it runs.

```python
# acme/wiki/config/http.py
web = {
    'middleware': OrderedDict({

        # Only allow this site to be served from these domains
        'TrustedHost': {
            'module': 'uvicore.http.middleware.TrustedHost',
            'options': {
                'allowed_hosts': env.list('WEB_TRUSTED_HOSTS', ['127.0.0.1', 'localhost', 'testserver']),
                'www_redirect': True,
            }
        },

        # Load request.user on every request (uncomment to enable)
        # 'Authentication': {
        #     'module': 'uvicore.http.middleware.Authentication',
        #     'options': {'route_type': 'web'},
        # },

        # Force HTTPS (skip if a load balancer terminates SSL in front of you)
        'HTTPSRedirect': {
            'module': 'uvicore.http.middleware.HTTPSRedirect',
        },

        # Gzip responses (skip if your web server/load balancer handles gzip)
        'GZip': {
            'module': 'uvicore.http.middleware.Gzip',
            'options': {
                'minimum_size': 500,
            }
        },
    }),
}
```

This stack applies only to the web sub-application, your [API routes](../api/middleware.md) have their own, separate stack.

!!! tip
    To disable a piece of middleware, just comment it out in `config/http.py`, no code changes needed.

---

## Route-Level Middleware

Global middleware handles app-wide concerns, but Uvicore also lets you attach middleware at the *route* layer, which is where authorization usually lives. You have three shorthands:

```python
@route.get('/dashboard', scopes=['authenticated'])                  # scopes shorthand
@route.get('/dashboard', auth=Guard(['authenticated']))             # auth shorthand
@route.get('/dashboard', middleware=[Guard(['authenticated'])])     # full middleware list
```

And you can declare these at any level, the top-level routes class, a controller class, a route group, an individual endpoint, or an endpoint parameter using `Guard(...)`.  See [Authorization](authorization.md) for the full story.

---

## How Middleware Layers Merge

When middleware is set at multiple levels, Uvicore *merges* it from parent to child rather than letting the child blow the parent away.  For [`Guard`](authorization.md) this means scopes accumulate: group or controller scopes are inherited by nested endpoints, and a child can *add* scopes without silently wiping out the parent's guard.

Because middleware wraps the endpoint, the outermost middleware (first in the `OrderedDict`) runs first on the way in and last on the way out.

---

## Exception Handling

The web exception handler is configured from the same `config/http.py`.

```python
# acme/wiki/config/http.py
web = {
    'exception': {
        'handler': 'uvicore.http.exceptions.handlers.web',
    },
}
```

The standard web handler renders HTML error pages (and can redirect on auth failures).  See [Web Exceptions](exceptions.md) for raising and shaping errors.

---

!!! tip "Middleware tips"
    - Put global web middleware (hosts, HTTPS, gzip, auth) in `config/http.py`.
    - Use route-level `Guard` rules for *authorization*, not for host or HTTPS policy.
    - Keep your package code free of app-specific global-middleware assumptions.
    - Treat the Web and API middleware as two completely separate stacks.
