# HTTPException

The most generic exception, which gives you full control over all parameters.


## :material-pound: Throw From Controller

```python
import uvicore
from uvicore.http import status
from uvicore.http.exceptions import HTTPException
from uvicore.http.routing import ApiRouter, Controller

@uvicore.controller()
class Test(Controller):
    def register(self, route: ApiRouter):
        try:
            # This is caught by the except Exception as e: below
            a = b

            # This is something we threw, but is also passed to the
            # except Exception as e: below as well
            if 1 != 2:
                # Simple
                raise HTTPException(404, message='Not Found', detail='/tmp/foo not found')

                # Or Full Params
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail='/tmp/foo not found',
                    message='Not Found',
                    exception='super detail, will be hidden if debug=true',
                    extra={'foo': 'bar'},
                    headers={'optional': 'dict of headers'}
                )
        except Exception as e:
            raise HTTPException(500, exception=e)
```


## :material-pound: API Response Example

Actual exception
```json
{
  "status_code": 500,
  "message": "name 'b' is not defined",
  "detail": "name 'b' is not defined",
  "exception": "Traceback (most recent call last):\n  File \"Code\train.py\", line 36, in get_complete_model\n    a = b\nNameError: name 'b' is not defined\n",
  "extra": null
}
```

Manually raised exception
```json
{
  "status_code": 404,
  "message": "Not Found",
  "detail": "/tmp/foo not found",
  "exception": null,
  "extra": null
}
```


## :material-pound: Source Code

See the [Source Code](https://github.com/uvicore/framework/blob/master/uvicore/http/exceptions/__init__.py) on Github

```python
class HTTPException(_HTTPException):
    """Main Base HTTP Exception"""

    # Message is optional and will default the the HTTP status codes TEXT as outlined in the python http module
    # Detail is a more detailed text description of the issue
    # Extra lets you pass in a dict of options or extra information that some handlers may want to use
    def __init__(self,
        status_code: int,
        detail: Optional[str] = None,
        *,
        message: Optional[str] = None,
        exception: Optional[str] = None,
        extra: Optional[Dict] = None,
        headers: Optional[Dict[str, Any]] = None
    ) -> None:
        # Detect if we were raised from another HTTPException with a status_code
        # If so, grab values from that first exception
        if exception is not None and haskey(exception, 'status_code'):
            status_code = exception.status_code
            message = exception.message
            detail = exception.detail
            extra = exception.extra
            headers = exception.headers
            exception = None
        else:
            # Standard try catch that raises HTTPException
            st = traceback.format_exc()
            message = message or str(exception)
            detail = detail or message
            exception = st

        # Call starlette exception where their detail is my message
        super().__init__(status_code=status_code, detail=message)

        # Swap starlette detail to my message
        self.message = self.detail
        self.detail = detail
        self.exception = exception if uvicore.config.app.debug else None  # Hidden unless in debug mode
        self.extra = extra
        self.headers = headers
```
