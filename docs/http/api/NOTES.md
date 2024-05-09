# NOTES to Add to Docs

## response_class

I added route.x(response_class=??)  to uvicore
to pipe into fastAPI
for this page https://fastapi.tiangolo.com/advanced/custom-response/


Basically in my dreml GET /train it returns a CSV
but was still getting application/json in OpenAPI UI dropdown and curl examples
curl -X 'GET' \
  'http://local-dreml.dynatron.io/api/v1/train/csv?topicId=1&revisionId=1' \
  -H 'accept: application/json'

So by adding this
@route.get('/csv', tags=['Train'], response_class=File)

now curl shows
curl -X 'GET' \
  'http://local-dreml.dynatron.io/api/v1/train/csv?topicId=1&revisionId=1' \
  -H 'accept: */*'


## responses

Also to document is ability to add multiple response
See See https://fastapi.tiangolo.com/advanced/additional-responses/ for forcing responses=

```
@route.get('/csv', tags=['Train'], responses={
    200: {
        "content": {"text/csv": {}}
    }
})
```

If you mix responses with response_class for a CSV download

```
@route.get('/csv', tags=['Train'], responses={
    200: {
        "content": {"text/csv": {}}
    }
}, response_class=FileResponse)
```

Then you get the text/csv dropdown perfectly, and the curl shows up as
```
curl -X 'GET' \
  'http://local-dreml.dynatron.io/api/v1/train/csv?topicId=1&revisionId=1' \
  -H 'accept: text/csv'
```

PERFECT.  However there is a bug in OpenAPI if you use text/csv
```
return FileResponse(train_file, media_type="text/csv", filename=download_filename)
```

It spins forever and crashes firefox/chrome

So use
```
return FileResponse(train_file, media_type="application/octet-stream", filename=download_filename)
```



## Uvicore vs FastAPI

Talk about how uvicore api router is actuall fastAPI

screenshot of a controller, outline in BLUE the uvicore parts
outline in GREEN the fastAPI parts and say anything in GREEN
you can actually use FastAPI's docs.

Now before you do that though, the Uvicore router.x() decorator does NOT
currently support all FastAPI methods

See fastAPI source routing.py
```
class APIRoute(routing.Route):
    def __init__(
        self,
        path: str,
        endpoint: Callable[..., Any],
        *,
        response_model: Any = Default(None),
        status_code: Optional[int] = None,
        tags: Optional[List[Union[str, Enum]]] = None,
        dependencies: Optional[Sequence[params.Depends]] = None,
        summary: Optional[str] = None,
        description: Optional[str] = None,
        response_description: str = "Successful Response",
        responses: Optional[Dict[Union[int, str], Dict[str, Any]]] = None,
        deprecated: Optional[bool] = None,
        name: Optional[str] = None,
        methods: Optional[Union[Set[str], List[str]]] = None,
        operation_id: Optional[str] = None,
        response_model_include: Optional[IncEx] = None,
        response_model_exclude: Optional[IncEx] = None,
        response_model_by_alias: bool = True,
        response_model_exclude_unset: bool = False,
        response_model_exclude_defaults: bool = False,
        response_model_exclude_none: bool = False,
        include_in_schema: bool = True,
        response_class: Union[Type[Response], DefaultPlaceholder] = Default(
            JSONResponse
        ),
        dependency_overrides_provider: Optional[Any] = None,
        callbacks: Optional[List[BaseRoute]] = None,
        openapi_extra: Optional[Dict[str, Any]] = None,
        generate_unique_id_function: Union[
            Callable[["APIRoute"], str], DefaultPlaceholder
        ] = Default(generate_unique_id),
    ) -> None:
```

And in uvicore you have `uvicore/http/routing/api_router.py` which doesn't accept all of those
If you add them, you have to add to `uvicore/http/routing/api_router.py` in all get/post/put/patch/delete and in the main `def add` and in your contract, and then in `uvicore/http/package/bootstrap.py` `def add_api_routes` to make them "pass through"

Also make note in docs that I ADD extra options like
```
        autoprefix: bool = True,
        middleware: Optional[List] = None,
        auth: Optional[Guard] = None,
        scopes: Optional[List] = None,
        inherits: Optional[Callable] = None,
```

and describe them.

Talk about how uvicore is a layer on top of FastAPI that gathers all the routes, deep merges them across packages, adds defaults like naming, prefixing, adds middleware and auth etc...  In the end you have a huge deep merged array of routes which you can see finally merged with
`./uvicore http routes`

