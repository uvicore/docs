# BadParameter

Convenience wrapper around `HTTPException` with a 400 and a `Bad Parameter` message.  If you need more control use the main [HTTPException](http-exception.md)

## Throw From Controller

```python
import uvicore
from uvicore.http import status
from uvicore.http.exceptions import HTTPException, BadParameter
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
                raise BadParameter('Invalid order_by parameter, possibly invalid JSON?')

                # Or Full Params
                raise BadParameter(
                    detail='Invalid order_by parameter, possibly invalid JSON?',
                    exception='super detail, will be hidden if debug=true',
                    extra={'foo': 'bar'},
                    headers={'optional': 'dict of headers'}
                )
        except Exception as e:
            raise HTTPException(500, exception=e)
```


## API Response Example
```json
{
  "status_code": 400,
  "message": "Bad Parameter",
  "detail": "Invalid order_by parameter, possibly invalid JSON?",
  "exception": null,
  "extra": null
}
```



## Source Code

See the [Source Code](https://github.com/uvicore/framework/blob/master/uvicore/http/exceptions/__init__.py) on Github

```python
class BadParameter(HTTPException):
    """Bad Parameter"""
    def __init__(self,
        detail: str | None = None,
        *,
        exception: str | None = None,
        extra: Dict | None = None,
        headers: Dict[str, Any] | None = None
    ) -> None:
        super().__init__(
            status_code=status.HTTP_400_BAD_REQUEST,
            message='Bad Parameter',
            detail=detail,
            exception=exception,
            extra=extra,
            headers=headers,
        )
```
