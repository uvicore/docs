---
title: API Routing
---

# API Routing

API routes are how you expose your application's data and actions to the world.  In Uvicore they are declared with the `ApiRouter`, but unlike a bare FastAPI project there is no single central app file wiring everything together.  Instead, routes are discovered and merged through the [package and provider](../../deeper/provider.md) lifecycle, which keeps every package self-contained and composable.

Uvicore separates Web and API routes into two files in your `http/routes` directory.  This dual-router design lets your Web and API endpoints have completely separate middleware and authentication, configured in your package's `config/http.py`.

All routes are defined inside a routes class `register()` method, and there are several elegant ways to declare them: decorators, direct method passing, groups and controllers.

---

## Registering API Routes

Your routes are registered from your [Package Provider](../../deeper/provider.md) during `boot()`.

```python
# acme/wiki/package/provider.py
def register_routes(self) -> None:
    self.register_http_api_routes(
        module='acme.wiki.http.routes.api.Api',
        prefix=self.package.config.api.prefix,
    )
```

Uvicore then imports the routes module, creates an `ApiRouter`, calls your `register()` method, merges any route-level middleware, and adds the finished routes to the API server.

---

## The Main Routes File

The `http/routes/api.py` file is the root of your API.  Every API route stems from here.  You *can* define endpoints directly in this file, but it is best to organize them into controllers stored in `http/api/`.  Controllers group your routes into logical units, each with its own middleware and auth requirements.

```python
# acme/wiki/http/routes/api.py
import uvicore
from uvicore.http.routing import Routes, ApiRouter, ModelRouter

@uvicore.routes()
class Api(Routes):

    def register(self, route: ApiRouter):
        """Register API Route Endpoints"""

        # The base path your controllers are loaded from
        route.controllers = 'acme.wiki.http.api'

        # Include your API controllers
        route.controller('users', prefix='/users')
        route.controller('topics', prefix='/topics')
        route.controller('tags', prefix='/tags')

        # Optionally generate automatic CRUD endpoints from your ORM models
        route.include(ModelRouter, options=uvicore.config.app.api.auto_api)

        return route
```

!!! note
    Your `routes/api.py` file, your nested controllers and your included controllers all share the same router model.  In Uvicore, a routes file *is* just a controller, and a controller is just a nested router.  It's routers all the way down!

---

## Controllers

Controllers store your endpoints in `http/api/` and keep your routing organized.  Generate one from the CLI:

```bash
./uvicore gen api-controller --help
./uvicore gen api-controller topics
```

```python
# acme/wiki/http/api/topics.py
from typing import Dict
import uvicore
from uvicore.http.routing import ApiRouter, Controller

@uvicore.controller()
class Topics(Controller):

    def register(self, route: ApiRouter):
        """Register API Controller Endpoints"""

        @route.get('/example1', tags=['Examples'])
        async def example1() -> Dict:
            """This docstring shows up in OpenAPI!"""
            return {'welcome': 'to the uvicore API!'}

        return route
```

Always remember to `return route` at the end of every routes and controller class.  Because the whole system is one infinitely-nested router, each piece must hand its router back up the chain.

---

## HTTP Methods

The `ApiRouter` exposes all the standard verbs as both decorators and direct methods:

```python
route.get(path, endpoint=None, ...)
route.post(...)
route.put(...)
route.patch(...)
route.delete(...)
```

Every method accepts the common route options, `name`, `autoprefix`, `middleware`, `auth`, `scopes` and `inherits`, plus the API-specific OpenAPI options that make your [docs](openapi.md) shine: `response_model`, `response_class`, `responses`, `tags`, `summary` and `description`.

---

## Decorator Style vs Direct Style

Prefer decorators?  Great.  Don't like decorators?  That's fine too, pass your endpoint function directly.

```python
# Decorator style
@route.get('/posts', tags=['Posts'])
async def posts():
    return []

# Direct style (same result)
async def posts():
    return []

route.get('/posts', posts, tags=['Posts'])
```

---

## Loading Controllers

You can include controllers by relative name, full module path, or by importing the class yourself.  When `route.controllers` is set, relative names are resolved against it.

```python
# String based (auto-imported)
route.controllers = 'acme.wiki.http.api'
route.controller('users')                 # -> acme.wiki.http.api.users.Users
route.controller('.admin.Users')          # leading dot appends to the base path
route.controller('acme.wiki.http.api.users.Users')   # full path used as-is

# Module based (you import it)
from acme.wiki.http.api.users import Users
route.controller(Users)
```

---

## Route Groups

Reach for `route.group()` when a set of routes shares a common prefix, tags or authorization requirements.  Groups work as a decorator or as a method with a list of routes.

```python
# As a decorator
@route.group('/admin', scopes=['authenticated', 'admin'], tags=['Admin'])
def admin():
    route.controller('users')

    @route.get('/health')
    async def health():
        return {'ok': True}

# As a method with a list of existing endpoints
route.group(prefix='/settings', routes=[
    route.get('/tokens', token_settings),
    route.get('/theme', theme_settings),
])
```

Nested groups work exactly as you would expect, and group-level [`Guard`](authorization.md) scopes are *merged* with child scopes rather than replacing them.

---

## Prefixes and Route Names

Every API package is mounted under your configured API prefix (typically `/api`), defined in config so consuming apps can change it.

```python
# acme/wiki/config/http.py
api = {
    'prefix': env('API_PREFIX', '/api'),
}
```

Each route is also given a **name**, automatically prefixed with your package's short name.  Prefer referencing routes by name rather than by hardcoded URL, paths can change when another app mounts your package under a different prefix, but names are stable.

```python
@route.get('/welcome')              # auto-named, e.g. wiki.welcome
async def welcome():
    ...

@route.get('/welcome', name='greeting')   # custom name (still auto-prefixed)
async def welcome():
    ...
```

### Overriding Another Package's Route

When you consume someone else's package, you may want to replace one of their routes with your own.  Say a 3rd party `blog` package defines a `/search` route named `blog.search` and you want your own search page instead.

Because Uvicore auto-prefixes route names with your own package, you must disable the auto-prefixer to claim the *exact* name and path of the route you are overriding.

```python
# Override the blog package's search route from your CMS
@route.get('/search', name='blog.search', autoprefix=False)
async def search():
    ...
```

---

## Inherited Parameter Signatures

The `inherits=` option lets one endpoint reuse another function's signature.  Uvicore leans on this heavily in the [Model Router](model-router.md) so every auto-generated endpoint can share the same rich set of query parameters without repeating the signature on each route.

It's an advanced feature, but a handy one when many of your endpoints share the same query contract.

---

!!! tip "Routing tips"
    - Keep your top-level `http/routes/api.py` small, lean on controllers for real features.
    - Reference routes by **name**, not hardcoded URL.
    - Put shared auth and tagging rules on a **group or controller** instead of repeating them on every endpoint.
    - Keep the API prefix in config, never baked into controller path strings.
