---
title: Web Routing
---

# Web Routing

Web routes map URLs to the controller methods that render your pages.  They are declared with the `WebRouter`, but just like the [API](../api/routing.md), they aren't wired up in one central file, they are discovered and merged through the [package and provider](../../deeper/provider.md) lifecycle, which keeps every package self-contained.

All routes are defined inside a routes class `register()` method, and you can declare them with decorators, direct method passing, groups and controllers.

---

## Registering Web Routes

Your routes are registered from your [Package Provider](../../deeper/provider.md) during `boot()`.

```python
# acme/wiki/package/provider.py
def register_routes(self) -> None:
    self.register_http_web_routes(
        module='acme.wiki.http.routes.web.Web',
        prefix=self.package.config.web.prefix,
    )
```

Uvicore then imports the routes module, creates a `WebRouter`, calls your `register()` method, merges any route-level middleware, and mounts the finished routes into the web server.

---

## The Main Routes File

The `http/routes/web.py` file is the root of your web routes.  You can define endpoints directly here, but it's best to organize them into controllers under `http/controllers/`.

```python
# acme/wiki/http/routes/web.py
import uvicore
from uvicore.http.routing import Routes, WebRouter

@uvicore.routes()
class Web(Routes):

    def register(self, route: WebRouter):
        """Register Web Route Endpoints"""

        # The base path your controllers are loaded from
        route.controllers = 'acme.wiki.http.controllers'

        # Include your web controllers
        route.controller('welcome')
        route.controller('about')

        return route
```

!!! note
    Your `routes/web.py` file, your nested controllers and your included controllers all share the same router model.  In Uvicore, a routes file *is* just a controller, and a controller is just a nested router.  It's routers all the way down!

---

## Controllers

Controllers group related endpoints into a class stored in `http/controllers/`.  From a routing perspective a controller is just a nested router that you load into your routes file.  Generate one from the CLI:

```bash
./uvicore gen controller welcome
```

```python
# acme/wiki/http/controllers/welcome.py
import uvicore
from uvicore.http import Request, response
from uvicore.http.routing import WebRouter, Controller

@uvicore.controller()
class Welcome(Controller):

    def register(self, route: WebRouter):
        """Register Web Controller Endpoints"""

        @route.get('/', name='welcome')
        async def welcome(request: Request):
            return await response.View('wiki/welcome.j2', {'request': request})

        return route
```

Always `return route` at the end of every routes and controller class, since the whole system is one infinitely-nested router, each piece hands its router back up the chain.

!!! tip
    This page covers how controllers slot into your **routing**, declaring, including and grouping them.  For what goes *inside* a handler, accessing the request, returning responses, path parameters, controller-wide authorization and testing, see [Web Controllers](controllers.md).

---

## HTTP Methods

The `WebRouter` exposes the standard verbs as both decorators and direct methods:

```python
route.get(path, endpoint=None, ...)
route.post(...)
route.put(...)
route.patch(...)
route.delete(...)
```

Each accepts the common route options: `name`, `autoprefix`, `middleware`, `auth`, `scopes` and `inherits`.

---

## Decorator Style vs Direct Style

Prefer decorators?  Great.  Don't like decorators?  That's fine too, pass your endpoint function directly.

```python
# Decorator style (most common)
@route.get('/', name='home')
async def home(request: Request):
    return await response.View('wiki/home.j2', {'request': request})

# Direct style (same result), passing the endpoint
async def home(request: Request):
    return await response.View('wiki/home.j2', {'request': request})

route.get('/', home, name='home')
```

---

## Loading Controllers

Include controllers by relative name, full module path, or by importing the class.  When `route.controllers` is set, relative names resolve against it.

```python
# String based (auto-imported)
route.controllers = 'acme.wiki.http.controllers'
route.controller('welcome')                          # -> ...controllers.welcome.Welcome
route.controller('.admin.Dashboard')                 # leading dot appends to the base path
route.controller('acme.wiki.http.controllers.users.Users')   # full path used as-is

# Module based (you import it)
from acme.wiki.http.controllers.welcome import Welcome
route.controller(Welcome)
```

---

## Route Groups

Reach for `route.group()` when routes share a prefix, tags or authorization.  It works as a decorator or as a method with a list of routes.

```python
@route.group('/admin', scopes=['authenticated', 'admin'])
def admin():
    route.controller('dashboard')

    @route.get('/settings')
    async def settings(request: Request):
        return await response.View('wiki/admin/settings.j2', {'request': request})
```

Nested groups work as expected, and group-level [`Guard`](authorization.md) scopes are *merged* with child scopes.

---

## Prefixes and Route Names

Every web package is mounted under your configured web prefix (typically `/`), defined in config so consuming apps can change it.

```python
# acme/wiki/config/http.py
web = {
    'prefix': env('WEB_PREFIX', ''),
}
```

Each route is also given a **name**, auto-prefixed with your package's short name.  Prefer referencing routes by name rather than hardcoded URL, paths shift when another app mounts your package under a different prefix, but names stay put.

```python
@route.get('/dashboard')            # auto-named from the path -> wiki.dashboard
async def dashboard(request: Request):
    ...

@route.get('/', name='home')        # the root path auto-names to wiki.root, so name it -> wiki.home
async def home(request: Request):
    ...
```

(Web route names are prefixed with your package's short name only, there is no `api` segment like the [API side](../api/routing.md#prefixes-and-route-names) gets.)

### Generating URLs From Names

In your templates, use the `url()` helper to build URLs from route names instead of hardcoding paths.

```html
<a href="{{ url('wiki.home') }}">Home</a>
<a href="{{ url('wiki.user', id=user.id) }}">Profile</a>
```

From Python, resolve a name to its URL with `url_path_for()` on the running app (or `request.url_for()` when you have a request), the same name registry the `url()` helper uses:

```python
import uvicore
path = uvicore.app.http.url_path_for('wiki.home')   # -> '/'
```

See [Resolving a Route URL in Code](../api/routing.md#resolving-a-route-url-in-code) for the full rundown.

### Overriding Another Package's Route

To replace a route from a package you consume, disable the auto-prefixer so you can claim its exact name and path.

```python
@route.get('/search', name='blog.search', autoprefix=False)
async def search(request: Request):
    ...
```

---

!!! tip "Routing tips"
    - Keep your top-level `http/routes/web.py` small, lean on controllers for real features.
    - Reference routes by **name**, never a hardcoded URL.
    - Put shared auth and tags on a **group or controller** instead of every endpoint.
    - Keep the web prefix in config, not baked into controller path strings.
