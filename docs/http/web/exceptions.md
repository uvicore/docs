# Exceptions

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








## :material-pound: Throwing Exceptions

From an Web controller you can throw exceptions like so:

```python
import uvicore
from uvicore.http import status
from uvicore.http.routing import WebRouter, Controller
from uvicore.http.exceptions import NotFound, PermissionDenied, NotAuthenticated, InvalidCredentials, HTTPException

@uvicore.controller()
class Test(Controller):
    def register(self, route: WebRouter):
        """Register Web Controller Endpoints"""

        # See all parameters here https://github.com/uvicore/framework/blob/master/uvicore/http/exceptions/__init__.py

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail='details here',
            message='here',
            exception='trace, will be hidden if debug=true',
            extra={'foo': 'bar'}
            headers='optional Dict of headers'
        )
        raise NotFound('File not found')
        raise PermissionDenied(['about.read'])
        raise NotAuthenticated('You should not be here')
        raise InvalidCredentials()
```


