# Concepts

In Uvicore, both Web and API routers utilize a Middleware stack to handle Authentication, CORS, Trusted Host, Compression, HTTPS Redirects and more.

All of the built in middleware is defined in `uvicore.http.middleware`.  Because Uvicore is built on [Starlette](https://github.com/encode/starlette), most of this is simply a passthrough into Starlette's middleware modules.



## Usage

Middleware for both Web and API routes is enabled and configured from your package's `config/http.py` file.

!!! note
    To remove/disable middleware from your Web or API routers, simply comment out the proper middleware definition in your `config/http.py` file.


Example `config/http.py` API section

```python
api = {
    ...
    # API middleware
    'middleware': OrderedDict({
        # Only allow this site to be hosted from these domains
        'TrustedHost': {
            'module': 'uvicore.http.middleware.TrustedHost',
            'options': {
                # Host testserver is for automated unit tests
                'allowed_hosts': env.list('API_TRUSTED_HOSTS', ['127.0.0.1', '0.0.0.0', 'localhost', 'testserver']),
                'www_redirect': True,
            }
        },

        # Only allow these domains to access routes
        'CORS': {
            'module': 'uvicore.http.middleware.CORS',
            'options': {
                # Allow origins are full protocol://domain:port, ie: http://127.0.0.1:5000
                'allow_origins': env.list('CORS_ALLOW_ORIGINS', ['http://127.0.0.1:5000', 'http://0.0.0.0:5000', 'http://localhost:5000']),
                'allow_methods': env.list('CORS_ALLOW_METHODS', ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS']),
                'allow_headers': [],
                'allow_credentials': False,
                'allow_origin_regex': None,
                'expose_headers': [],
                'max_age': 600,
            }
        },

        # Detect one or more authentication mechanisms and load valid or anonymous user into request.user
        'Authentication': {
            # All options are configured in the 'auth' section of this app config
            'module': 'uvicore.http.middleware.Authentication',
            'options': {
                'route_type': 'api',  # web or api only
            }
        },
    }),
    ...
}
```


Example `config/http.py` Web section

```python
web = {
    ...
    # Web middleware
    'middleware': OrderedDict({
        # Only allow this site to be hosted from these domains
        'TrustedHost': {
            'module': 'uvicore.http.middleware.TrustedHost',
            'options': {
                # Host testserver is for automated unit tests
                'allowed_hosts': env.list('WEB_TRUSTED_HOSTS', ['127.0.0.1', '0.0.0.0', 'localhost', 'testserver']),
                'www_redirect': True,
            }
        },

        # Detect one or more authentication mechanisms and load valid or anonymous user into request.user
        'Authentication': {
            # All options are configured in the 'auth' section of this app config
            'module': 'uvicore.http.middleware.Authentication',
            'options': {
                'route_type': 'web',  # web or api only
            }
        },

        # If you have a loadbalancer with SSL termination in front of your web
        # app, don't use this redirection to enforce HTTPS as it is always HTTP internally.
        'HTTPSRedirect': {
            'module': 'uvicore.http.middleware.HTTPSRedirect',
        },
        # Not needed if your loadbalancer or web server handles gzip itself.
        'GZip': {
            'module': 'uvicore.http.middleware.Gzip',
            'options': {
                # Do not GZip responses that are smaller than this minimum size in bytes. Defaults to 500
                'minimum_size': 500
            }
        },
    }),
    ...
```


## Adding your own Middleware

As you can see from the `config/http.py` examples above, all middleware configurations contain a `module` property, example: `'module': 'uvicore.http.middleware.CORS'`.  This is the actual python code that contains the middleware itself.

Creating your own middleware involves making a Python Class with a `def __init__()` and a `def __call__` method.  Any parameters that you want to pass in can be defined in the `__init__()` method and those values are dynamically passed from the `config/http.py` `options` property.

Example FooBar Middleware


**Create a new acme/wiki/http/middleware/foo_bar.py**
```python
import uvicore
from uvicore.http.exceptions import HTTPException
from uvicore.http.request import HTTPConnection, Request
from uvicore.http.response import Text, HTML, JSON, Response
from uvicore.typing import Dict, Callable, ASGIApp, Send, Receive, Scope

@uvicore.service()
class FooBar:
    """FooBar Middleware Capable of Fooing your Bar Real Good"""

    def __init__(self, app: ASGIApp, param1: str, pararm2: str) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        # This FooBar middleware only for http and websocket types
        if scope["type"] not in ["http", "websocket"]:
            # Next middleware in stack
            await self.app(scope, receive, send)
            return

        # Get the http connection.  This is essentially the Request but not HTTP specific.
        # The base connection that works for HTTP and WebSockets.  Request inherits from HTTPConnection
        request = HTTPConnection(scope)
        method = scope["method"]
        headers = Headers(scope=scope)
        host = headers.get("host", "").split(":")[0]
        origin = headers.get("origin")

        if bad_things_happened
            response = PlainTextResponse("Things are Foo Bar", status_code=400)
            await response(scope, receive, send)

        # Success
        # Next global middleware in stack
        await self.app(scope, receive, send)
```

Now add to your `config/http.py` in whatever order you want this middleware to fire.

```python
api = {
    ...
    # Web middleware
    'middleware': OrderedDict({
        # Other middleware...

        'FooBar': {
            'module': 'acme.wiki.middleware.foo_bar.FooBar',
            'options': {
                'param1': 'foo',
                'param2': 'bar'
            }
        }

        # Other middleware...
    }),
    ...
```

!!! info
    For more examples of middleware, see

    * [Uvicore Aauthentication Middleware](https://github.com/uvicore/framework/blob/master/uvicore/http/middleware/authentication.py)
    * [Starlette Middleware](https://github.com/encode/starlette/tree/master/starlette/middleware)

    What about FastAPI's middleware?  FastAPI is built on Starlette and does not provide any additional middleware of its own.



## Debugging Middleware

Uvicore's `dump()` and `dd()` functions do not work in middleware and cause Internal Server Errrors.

Instead use the logger including the loggers own `dump()`.

```python
# Somewhere in your middleware code

uvicore.log.dump('hi')
```

The output will not show in your browser, but in the CLI running `./uvicore http serve`
