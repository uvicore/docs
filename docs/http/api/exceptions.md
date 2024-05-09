# Exceptions

!!! note
    For Exception concepts and a detailed list of all exceptions see the main [Exception](../../exceptions/)



## :material-pound: Default API Exception Handler





## :material-pound: Throwing Exceptions

From an API controller you can throw exceptions like so:

```python
import uvicore
from uvicore.http import status
from uvicore.http.routing import ApiRouter, Controller
from uvicore.http.exceptions import NotFound, PermissionDenied, NotAuthenticated, InvalidCredentials, HTTPException

@uvicore.controller()
class Test(Controller):
    def register(self, route: ApiRouter):
        """Register API Controller Endpoints"""

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




## :material-pound: Custom Exception Handlers

To provide your own API handler, create your own method anywhere in your package, for example `exceptions/handlers.py`.  Then simply change your `config/app.py` `api.exceptions` to point to this new location.  You can see Uvicore's default exception handler by looking at the `uvicore.http.exceptions.handlers.api` method.  Something like this:


```python
from uvicore.http import response
from uvicore.http import Request
from uvicore.http.exceptions.handlers import HTTPException

async def api(request: Request, e: HTTPException) -> response.JSON:
    """Main exception handler for all API endpoints"""

    # Get error payload (smart based on uvicore or starlette HTTPException)
    (status_code, detail, message, exception, extra, headers) = _get_payload(e)
    return response.JSON(
        {
            "status_code": status_code,
            "message": message,
            "detail": detail,
            "exception": exception,
            "extra": extra,
        }, status_code=status_code, headers=headers
    )
```
