# PermissionDenied

Convenience wrapper around `HTTPException` with a 401 and a `Permission Denied` message.  If you need more control use the main [HTTPException](http-exception.md)

## :material-pound: Throw From Controller

```python
import uvicore
from uvicore.http import status
from uvicore.http.exceptions import HTTPException, PermissionDenied
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
                raise PermissionDenied(['about.read', 'about.create'])

                # Or Full Params
                raise PermissionDenied(
                    permissions=['about.read', 'about.create'],
                    detail='Permission denied',
                    extra={'foo': 'bar'},
                    headers={'optional': 'dict of headers'}
                )
        except Exception as e:
            raise HTTPException(500, exception=e)
```



## :material-pound: API Response Example
```json
{
  "status_code": 401,
  "message": "Permission Denied",
  "detail": "Permission denied to ['about.read', 'about.create']",
  "exception": null,
  "extra": null
}
```




## :material-pound: Source Code

See the [Source Code](https://github.com/uvicore/framework/blob/master/uvicore/http/exceptions/__init__.py) on Github

```python
class PermissionDenied(HTTPException):
    """Permission Denied Exception"""
    def __init__(self,
        permissions: Optional[List] = None,
        detail: Optional[str] = None,
        *,
        extra: Optional[Dict] = None,
        headers: Optional[Dict[str, Any]] = None
    ) -> None:
        detail = "Permission denied"
        if permissions:
            if type(permissions) != list: permissions = [permissions]
            detail += " to {}".format(permissions)
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            message='Permission Denied',
            detail=detail,
            extra=extra,
            headers=headers,
        )
```
