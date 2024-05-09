# Concepts

In uvicore, Web and API endpoints are separated based on dual routers.  Each engine has it's own set of middleware, exceptions and other configurations.  Because of this separation you can define exception handlers for each route engine in your `config/http.py` under `web.exception` and `api.exception`.

!!! note "See The Code on Github"
    - [Exceptions](https://github.com/uvicore/framework/blob/master/uvicore/http/exceptions/__init__.py)
    - [Handlers](https://github.com/uvicore/framework/blob/master/uvicore/http/exceptions/handlers.py)
    - [Status Code Constants](https://github.com/uvicore/framework/blob/master/uvicore/http/status.py)



## :material-pound: Exceptions vs Handlers

- `Exceptions` contains the message and body of the error
- `Handlers` present the error in different formats

- Web Handler
    - `NotFound()` exception from a web route may be handled by presenting HTML with colors and tables.
- API Handler
    - `NowFound()` exception from an API route may be handled by presenting JSON with other wrappers and elements.
- CLI Handler
    - `NowFound()` exception from a CLI command may be handled by presenting a colored Console output and writing to the logger.

One Exception, with 3 different ways to present or handle that exception.


