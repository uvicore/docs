---
title: API Overview
---

# API Overview

Uvicore's API layer is built on the amazing and blazing fast **[FastAPI](https://fastapi.tiangolo.com/)**, but it isn't wired up the way a bare FastAPI project is.  In Uvicore, your API is a first-class citizen of the [package and provider](../../deeper/provider.md) system.  Your routes, middleware, authentication, authorization, OpenAPI docs and even automatic CRUD endpoints are all registered through your app's [Package Provider](../../deeper/provider.md) and configured from your app config.

The payoff is huge.  You write clean, organized controllers and let Uvicore handle the wiring, the user, the permissions and the docs, so you can focus on your actual API.

!!! note
    This section documents Uvicore's API layer specifically.  For server-rendered HTML pages, see the [Web](../web/index.md) section.  The two share the same routing engine but serve very different purposes.

---

## Where Things Live

Your API lives in a couple of predictable places:

- **Routes** are declared in `http/routes/api.py` and your controllers live in `http/api/`.
- **Middleware** for the API is configured from your running app's `config/http.py`, not from individual packages.
- **Authentication** loads a real `request.user` object on *every* request, even anonymous ones.
- **Authorization** is permission and scope based through the [`Guard`](authorization.md).
- **OpenAPI** docs are generated from your route metadata and tuned from app config.
- The optional **[Model Router](model-router.md)** can generate full CRUD endpoints automatically from your registered [ORM models](../../database/orm-basics.md).

---

## How API Routes Are Loaded

When your app boots, Uvicore imports each package's API routes module, creates an `ApiRouter`, calls your `Routes.register()` method, then merges the resulting routes into the global API server.  In short:

1. Your [Package Provider](../../deeper/provider.md) registers your API routes in `boot()`.
2. Your `config/http.py` defines the API prefix and the API middleware stack.
3. Your `http/routes/api.py` class registers your top-level controllers and route groups.
4. Your controllers in `http/api/` define the actual endpoints with `@route.get()`, `@route.post()` and friends.

Here is the standard shape, straight from a fresh app.

```python
# acme/wiki/package/provider.py
def register_routes(self) -> None:
    self.register_http_api_routes(
        module='acme.wiki.http.routes.api.Api',
        prefix=self.package.config.api.prefix,
    )
```

```python
# acme/wiki/http/routes/api.py
@uvicore.routes()
class Api(Routes):

    def register(self, route: ApiRouter):
        route.controllers = 'acme.wiki.http.api'
        route.controller('welcome')

        # Optionally generate automatic CRUD endpoints for all your models
        route.include(ModelRouter, options=uvicore.config.app.api.auto_api)
        return route
```

---

## Reading This Section

If you are new to Uvicore's API layer, these pages build on each other nicely in order:

1. **[Routing](routing.md)** - define endpoints, controllers and groups.
2. **[Middleware](middleware.md)** - the global stack and per-route middleware.
3. **[Authentication](authentication.md)** - who is making the request.
4. **[Authorization](authorization.md)** - what they are allowed to do.
5. **[Model Router](model-router.md)** - instant CRUD APIs from your models.
6. **[OpenAPI](openapi.md)** - interactive Swagger docs.
7. **[File Uploads](file-upload.md)** - accepting files.
8. **[Exceptions](exceptions.md)** - raising errors and shaping the JSON response.
