# NotFound

Convenience wrapper around `HTTPException` with a 404 and a `Not Found` message.  If you need more control use the main [HTTPException](http-exception.md)

## :material-pound: Throw From Controller

```python
import uvicore
from uvicore.http import status
from uvicore.http.exceptions import HTTPException, NotFound
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
                raise NotFound('/tmp/foo not found')

                # Or Full Params
                raise NotFound(
                    detail='/tmp/foo not found',
                    extra={'foo': 'bar'},
                    headers={'optional': 'dict of headers'}
                )
        except Exception as e:
            raise HTTPException(500, exception=e)
```


## :material-pound: API Response Example
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
class NotFound(HTTPException):
    """Not Found Exception"""
    def __init__(self,
        detail: Optional[str] = None,
        *,
        extra: Optional[Dict] = None,
        headers: Optional[Dict[str, Any]] = None
    ) -> None:
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            message='Not Found',
            detail=detail,
            extra=extra,
            headers=headers,
        )
```
