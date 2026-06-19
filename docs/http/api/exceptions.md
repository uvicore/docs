---
title: API Exceptions
---

# API Exceptions

When something goes wrong in an API endpoint, you don't build an error response by hand, you `raise` an exception and let the **API exception handler** turn it into a clean JSON response.  Because Uvicore uses [dual routers](routing.md), the API and Web engines each have their own handler, configured separately in `config/http.py`.  The API handler renders JSON; the [Web handler](../web/exceptions.md) renders HTML.

!!! note
    This page covers exceptions from the **API** perspective, how to raise them in a controller and what the JSON looks like.  For the shared concepts, the full list of exception types and how to customize a handler, see the [HTTP Exceptions](../exceptions/concepts.md) section.

---

## Throwing From an API Controller

Raise any of Uvicore's HTTP exceptions from inside an endpoint and the API handler does the rest.  The generic `HTTPException` gives you full control, while the convenience wrappers cover the common status codes.

```python
import uvicore
from uvicore.http import status
from uvicore.http.exceptions import HTTPException, NotFound, PermissionDenied, NotAuthenticated, InvalidCredentials
from uvicore.http.routing import ApiRouter, Controller

@uvicore.controller()
class Topics(Controller):

    def register(self, route: ApiRouter):
        """Register API Controller Endpoints"""

        @route.get('/topics/{id}', tags=['Topics'])
        async def show(id: int):
            topic = await Topic.query().find(id)
            if not topic:
                raise NotFound(f'Topic {id} not found')
            return topic

        return route
```

The convenience wrappers are thin shortcuts over `HTTPException` with a sensible status code and message baked in:

```python
raise NotFound('Topic not found')               # 404
raise PermissionDenied(['topics.read'])          # 401, lists the required scopes
raise NotAuthenticated('Login required')         # 401
raise InvalidCredentials()                        # 401

# Full control with the generic exception
raise HTTPException(
    status_code=status.HTTP_404_NOT_FOUND,
    detail='Topic 42 not found',
    message='Not Found',
    exception='stack trace, hidden unless debug=True',
    extra={'topic_id': 42},
    headers={'X-Custom': 'value'},
)
```

Use the `status` constants (e.g. `status.HTTP_404_NOT_FOUND`) rather than raw integers so your intent is obvious.  See each wrapper's signature in [HTTPException](../exceptions/http-exception.md), [NotFound](../exceptions/not-found.md), [PermissionDenied](../exceptions/permission-denied.md), [NotAuthenticated](../exceptions/not-authenticated.md) and [InvalidCredentials](../exceptions/invalid-credentials.md).

---

## The JSON Error Shape

The default API handler returns a consistent JSON envelope for every exception:

```json
{
  "status_code": 404,
  "message": "Not Found",
  "detail": "Topic 42 not found",
  "exception": null,
  "extra": null
}
```

- `message` - short, human-readable summary (defaults to the HTTP status text)
- `detail` - a longer description of what went wrong
- `exception` - the raw stack trace, **only** present when `debug=True` in `config/app.py`, stripped in production for safety
- `extra` - any custom dict you passed, untouched

!!! danger "Never enable debug in production"
    The `exception` field carries your stack trace.  It is hidden automatically unless `debug=True`.  Keep `debug=False` in production so internals are never leaked to API consumers.

---

## SmartException for Shared Code

If your real work lives in a [Job](../../deeper/jobs.md) or service that can be triggered from *both* an API and the CLI, raise a `SmartException` instead.  It morphs into an HTTP/JSON error when running under the API, and into a plain Python exception when running under the CLI, so the same code does the right thing at either entrypoint.

```python
from uvicore.exceptions import SmartException

raise SmartException(message='Not Found', status_code=404, detail='Topic not found')
```

See [SmartException](../exceptions/smart.md) for the full story.

---

## Customizing the API Handler

The handler is just a config pointer in your package's `config/http.py`:

```python
# acme/wiki/config/http.py
api = {
    'exception': {
        'handler': 'uvicore.http.exceptions.handlers.api',
    },
}
```

Point it at your own async function to wrap errors however your API contract requires (different field names, an envelope, etc.).  See [Handlers](../exceptions/handlers.md) for a complete custom-handler example.

---

!!! tip "API exception tips"
    - `raise` exceptions, never hand-build an error response, let the handler render the JSON.
    - Reach for the convenience wrappers (`NotFound`, `PermissionDenied`, ...) and drop to `HTTPException` only when you need full control.
    - Keep `debug=False` in production so stack traces never reach your API consumers.
    - Use a `SmartException` for logic shared between API endpoints and CLI commands.
