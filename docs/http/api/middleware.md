---
title: API Middleware
---

# API Middleware

Middleware wraps every request flowing into your API, handling cross-cutting concerns like trusted hosts, CORS and [authentication](authentication.md) before your route ever runs.

There is an important philosophy here: **the running application owns the global middleware stack, not individual packages.**  Packages register their routes, but the app that is actually being served decides which global middleware wraps them.  This keeps packages portable, a package never imposes its own host or CORS policy on the app consuming it.

!!! note
    This page covers the API stack specifically.  For the shared concepts behind Uvicore middleware (and how to write your own), see [Middleware Concepts](../middleware/concepts.md).

---

## Where API Middleware Lives

The global API middleware stack is defined in your `config/http.py` under `api.middleware`.  It is an `OrderedDict`, so the order you list middleware in is the order it runs.

```python
# acme/wiki/config/http.py
api = {
    'middleware': OrderedDict({

        # Only allow this site to be served from these domains
        'TrustedHost': {
            'module': 'uvicore.http.middleware.TrustedHost',
            'options': {
                'allowed_hosts': env.list('API_TRUSTED_HOSTS', ['127.0.0.1', 'localhost', 'testserver']),
                'www_redirect': True,
            }
        },

        # Only allow these origins to call your API
        'CORS': {
            'module': 'uvicore.http.middleware.CORS',
            'options': {
                'allow_origins': env.list('CORS_ALLOW_ORIGINS', ['http://127.0.0.1:5000']),
                'allow_methods': ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
            }
        },

        # Load request.user on every request (uncomment to enable)
        # 'Authentication': {
        #     'module': 'uvicore.http.middleware.Authentication',
        #     'options': {'route_type': 'api'},
        # },
    }),
}
```

This stack applies only to the API sub-application, your [Web routes](../web/middleware.md) have their own, separate stack.

!!! tip
    To disable a piece of middleware, simply comment it out in your `config/http.py`.  No code changes required.

---

## Route-Level Middleware

Global middleware handles app-wide concerns, but Uvicore also lets you attach middleware at the *route* layer, which is where authorization usually lives.  You have three shorthands:

```python
@route.get('/reports', scopes=['authenticated', 'reports.read'])      # scopes shorthand
@route.get('/reports', auth=Guard(['reports.read']))                   # auth shorthand
@route.get('/reports', middleware=[Guard(['reports.read'])])           # full middleware list
```

And you can declare these at any level:

- the top-level routes class
- a controller class
- a route group
- an individual endpoint
- an endpoint parameter, using `Guard(...)` as a dependency

See [Authorization](authorization.md) for the full story on `Guard` and scopes.

---

## How Middleware Layers Merge

When you set middleware at multiple levels, Uvicore *merges* them from parent to child rather than letting the child blow the parent away.  For [`Guard`](authorization.md) this means scopes accumulate, which has two happy consequences:

1. Group or controller scopes are inherited by every nested endpoint.
2. A child endpoint can *add* scopes, but it never silently wipes out the parent's guard.

Uvicore is also smart enough to detect when the same `Guard` is applied both as route middleware *and* as a FastAPI dependency parameter, so it won't double up.

---

## Exception Handling

The API's exception handler is configured from the same `config/http.py`.

```python
# acme/wiki/config/http.py
api = {
    'exception': {
        'handler': 'uvicore.http.exceptions.handlers.api',
    },
}
```

The standard API handler returns clean JSON using `APIErrorResponse`.  See [API Exceptions](exceptions.md) for how to raise and shape errors.

---

!!! tip "Middleware tips"
    - Put global API middleware (hosts, CORS, auth) in `config/http.py`.
    - Use route-level `Guard` rules for endpoint *authorization*, not for host or CORS policy.
    - Keep your package code free of app-specific global-middleware assumptions.
    - Treat the API and Web middleware as two completely separate stacks.
