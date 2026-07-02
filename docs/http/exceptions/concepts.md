# Concepts

In Uvicore, Web and API endpoints are separated based on dual routers.  Each engine has its own set of middleware, exceptions and other configurations.  Because of this separation you can define exception handlers for each route engine in your `config/http.py` under `web.exception` and `api.exception`.

!!! note "See The Code on Github"
    - [Exceptions](https://github.com/uvicore/framework/blob/master/uvicore/http/exceptions/__init__.py)
    - [Handlers](https://github.com/uvicore/framework/blob/master/uvicore/http/exceptions/handlers.py)
    - [Status Code Constants](https://github.com/uvicore/framework/blob/master/uvicore/http/status.py)

---

## Exceptions vs Handlers

- **Exceptions** contain the message and body of the error
- **Handlers** present the error in different formats (Web HTML, API JSON, CLI console output)

One exception class can be presented three different ways depending on where it is raised:

- **Web route** — `NotFound()` is rendered as styled HTML by the [Web handler](handlers.md).
- **API route** — `NotFound()` is rendered as JSON by the [API handler](handlers.md).
- **CLI command** — a [SmartException](smart.md) morphs into a plain Python exception (colored console output, logged) instead of an HTTP response.

One exception, three different ways to present or handle it.

---

## Exception Classes

Uvicore defines a family of HTTP exception classes built on Starlette's `HTTPException`.  Each carries structured metadata (`message`, `detail`, `extra`, `exception`, `headers`) that handlers can render intelligently.  Each has its own page with a throw example, its parameters, and its source code:

| Exception | Status | Use it when | Page |
|---|---|---|---|
| `HTTPException` | *any* | You need full control over every parameter | [HTTPException](http-exception.md) |
| `NotFound` | 404 | A resource cannot be found | [NotFound](not-found.md) |
| `BadParameter` | 400 | A request contains invalid parameters | [BadParameter](bad-parameter.md) |
| `PermissionDenied` | 401 | The user lacks the required permissions | [PermissionDenied](permission-denied.md) |
| `NotAuthenticated` | 401 | The user is not logged in | [NotAuthenticated](not-authenticated.md) |
| `InvalidCredentials` | 401 | The user's login credentials are invalid | [InvalidCredentials](invalid-credentials.md) |

All of the convenience exceptions (everything except `HTTPException` itself) are thin wrappers around `HTTPException` with a preset status code and message.  If you need more control, reach for the base [HTTPException](http-exception.md) directly.

---

## Handlers

Uvicore ships two built-in exception handlers, one per route engine — an API handler (JSON) and a Web handler (HTML with Jinja2 template fallback).  Both are configured per engine in `config/http.py` and can be fully overridden.  See the [Handlers](handlers.md) page for configuration, the JSON/HTML response shapes, and how to write your own.

---

## SmartException (CLI Exceptions)

The `SmartException` class handles exceptions across both HTTP and CLI contexts, morphing into an `HTTPException` on a Web/API route or a plain Python exception on the CLI.  See the [SmartException](smart.md) page for details.
