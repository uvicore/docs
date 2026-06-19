---
title: Web Overview
---

# Web Overview

Uvicore's Web layer is for the server-rendered side of your application, HTML pages, forms and templates, powered by **[Starlette](https://www.starlette.io/)** under the hood.  Like everything else in Uvicore, your web routes, middleware, authentication, authorization and templating are all wired together through the [package and provider](../../deeper/provider.md) system.

It shares the very same routing engine as the [API](../api/index.md), but where the API returns data, the Web layer returns beautiful rendered [views](views.md).

!!! note
    Web and API are deliberately kept as two separate routers with their own middleware, prefixes and exception handlers.  Reach for the Web layer when you're rendering HTML, and the [API layer](../api/index.md) when you're serving JSON.

---

## Where Things Live

- **Routes** are declared in `http/routes/web.py`; your controllers live in `http/controllers/`.
- **Views** are Jinja2 `.j2` templates under `http/views/`, rendered with `response.View()`.
- **Middleware** for the Web router is configured from your app's `config/http.py`, separate from the API stack.
- **Authentication** loads a real `request.user` on every request, with optional login-redirect behavior for web routes.
- **Authorization** is permission and scope based through the [`Guard`](authorization.md).

---

## How Web Routes Are Loaded

When your app boots, Uvicore imports each package's web routes module, creates a `WebRouter`, calls your `Routes.register()` method, then mounts the resulting routes into the global web server.  In short:

1. Your [Package Provider](../../deeper/provider.md) registers your web routes (and view paths) in `boot()`.
2. Your `config/http.py` defines the web prefix and middleware stack.
3. Your `http/routes/web.py` class registers your top-level controllers and route groups.
4. Your controllers in `http/controllers/` define the actual endpoints.

Here is the standard shape from a fresh app.

```python
# acme/wiki/package/provider.py
def register_routes(self) -> None:
    self.register_http_web_routes(
        module='acme.wiki.http.routes.web.Web',
        prefix=self.package.config.web.prefix,
    )

def register_views(self) -> None:
    # Tell the templating engine where your .j2 views live
    self.register_http_views(['acme.wiki.http.views'])
```

```python
# acme/wiki/http/routes/web.py
@uvicore.routes()
class Web(Routes):

    def register(self, route: WebRouter):
        route.controllers = 'acme.wiki.http.controllers'
        route.controller('welcome')
        return route
```

---

## Reading This Section

If you are new to Uvicore's web layer, these pages build on each other in order:

1. **[Routing](routing.md)** - define endpoints, controllers and groups.
2. **[Middleware](middleware.md)** - the global web stack and per-route middleware.
3. **[Authentication](authentication.md)** - who is making the request.
4. **[Authorization](authorization.md)** - what they are allowed to do.
5. **[Templating](templating.md)** - Jinja2, filters and helpers.
6. **[Views](views.md)** - rendering templates as responses.
7. **[Controllers](controllers.md)** - organizing your routes.
