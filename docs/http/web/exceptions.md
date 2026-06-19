---
title: Web Exceptions
---

# Web Exceptions

When something goes wrong in a web endpoint, you don't render an error page by hand, you `raise` an exception and let the **Web exception handler** turn it into a rendered HTML error page.  Because Uvicore uses [dual routers](routing.md), the Web and API engines each have their own handler, configured separately in `config/http.py`.  The Web handler renders HTML; the [API handler](../api/exceptions.md) renders JSON.

!!! note
    This page covers exceptions from the **Web** perspective, how to raise them in a controller and how custom error pages are rendered.  For the shared concepts, the full list of exception types and handler internals, see the [HTTP Exceptions](../exceptions/concepts.md) section.

---

## Throwing From a Web Controller

Raise any of Uvicore's HTTP exceptions from inside an endpoint and the Web handler does the rest.  The generic `HTTPException` gives you full control, while the convenience wrappers cover the common status codes.

```python
import uvicore
from uvicore.http import status
from uvicore.http import Request, response
from uvicore.http.exceptions import HTTPException, NotFound, PermissionDenied, NotAuthenticated, InvalidCredentials
from uvicore.http.routing import WebRouter, Controller

@uvicore.controller()
class Wiki(Controller):

    def register(self, route: WebRouter):
        """Register Web Controller Endpoints"""

        @route.get('/page/{slug}', name='page')
        async def page(request: Request, slug: str):
            page = await Page.query().where('slug', slug).first()
            if not page:
                raise NotFound('Page not found')
            return await response.View('wiki/page.j2', {'request': request, 'page': page})

        return route
```

The convenience wrappers are thin shortcuts over `HTTPException` with a sensible status code and message baked in:

```python
raise NotFound('Page not found')                 # 404
raise PermissionDenied(['about.read'])            # 401, lists the required scopes
raise NotAuthenticated('Login required')          # 401
raise InvalidCredentials()                         # 401

# Full control with the generic exception
raise HTTPException(
    status_code=status.HTTP_404_NOT_FOUND,
    detail='Page not found',
    message='Not Found',
    exception='stack trace, hidden unless debug=True',
    extra={'slug': slug},
    headers={'X-Custom': 'value'},
)
```

Use the `status` constants (e.g. `status.HTTP_404_NOT_FOUND`) rather than raw integers so your intent is obvious.  See each wrapper's signature in [HTTPException](../exceptions/http-exception.md), [NotFound](../exceptions/not-found.md), [PermissionDenied](../exceptions/permission-denied.md), [NotAuthenticated](../exceptions/not-authenticated.md) and [InvalidCredentials](../exceptions/invalid-credentials.md).

---

## Custom Error Pages

Instead of returning JSON, the default Web handler renders a Jinja2 template named after the status code from an `errors` [view folder](templating.md).  A `404` looks for `errors/404.j2`, falling back to `errors/catch_all.j2`, and finally to a basic built-in HTML page if neither exists.

To take control of your error pages, just create the templates in your package, no config change needed:

```
http/views/errors/404.j2
http/views/errors/catch_all.j2
```

These templates receive the error payload in their context:

```html
<!-- http/views/errors/404.j2 -->
<h1>{{ status_code }} {{ message }}</h1>
<p>{{ detail }}</p>
{% if exception %}<pre>{{ exception }}</pre>{% endif %}
```

Available variables are `request`, `status_code`, `message`, `detail`, `exception` (blank unless `debug=True`) and `extra`.  See [Handlers](../exceptions/handlers.md) for the full rendering logic and how to replace the handler entirely.

!!! danger "Never enable debug in production"
    The `exception` variable carries your stack trace.  It is blank automatically unless `debug=True` in `config/app.py`.  Keep `debug=False` in production so internals are never leaked to visitors.

---

!!! tip "Web exception tips"
    - `raise` exceptions, never hand-build an error response, let the handler render the page.
    - Reach for the convenience wrappers (`NotFound`, `PermissionDenied`, ...) and drop to `HTTPException` only when you need full control.
    - Ship `errors/404.j2` and `errors/catch_all.j2` templates so visitors see branded error pages.
    - Keep `debug=False` in production so stack traces never reach your visitors.
