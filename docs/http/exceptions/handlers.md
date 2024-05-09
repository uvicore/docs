# Handlers

!!! note
    See [Exception Concepts](concepts.md) for Exceptions vs Handlers


Uvicore comes with 2 main Exception handlers.  One for Web Routes and one for API Routes.  You can override these handlers and present errors any way that you like!


## :material-pound: No StackTrace in Production

If the raised error has the `exception=` parameter populated, the exception is ONLY added to the handler if `debug=True` is set in your `config/app.py` config.  These are usually the direct results of the `try...except` stack trace and will be stripped by uvicore for your safety while in production mode.  Never set `debug=True` in production!



## :material-pound: Default API Exception Handler

The default API exception handler is defined in `config/http.py` is
```python
  # API exception handlers
  'exception': {
      'handler': 'uvicore.http.exceptions.handlers.api',
  },
```

Which returns a JSON error response like so:
```json
{
  "status_code": 400,
  "message": "Bad Parameter",
  "detail": "Invalid order_by parameter, possibly invalid JSON?",
  "exception": "Expecting value: line 1 column 2 (char 1)",
  "extra": {
    "whatever": "you want here, its your dict"
  }
}
```

## :material-pound: Custom API Exception Handlers

To provide your own API handler, create your own method anywhere in your package, for example `exceptions/handlers.py`.  Then simply change your `config/app.py` `api.exceptions` to point to this new location.

See the [Source Code](https://github.com/uvicore/framework/blob/master/uvicore/http/exceptions/handlers.py) on Github


```python
from uvicore.http import response
from uvicore.http import Request
from uvicore.http.exceptions.handlers import HTTPException, expand_payload

async def api(request: Request, e: HTTPException) -> response.JSON:
    """Custom exception handler for all API endpoints"""

    # Get error payload (smart based on uvicore or stock HTTPException)
    (status_code, detail, message, exception, extra, headers) = expand_payload(e)
    return response.JSON(
        {
            "status_code2": status_code,
            "message2": message,
            "detail2": detail,
            "exception2": exception,
            "extra2": extra,
        }, status_code=status_code, headers=headers
    )
```


## :material-pound: Default Web Exception Handler

The default Web exception handler is defined in `config/http.py` is
```python
  # Web exception handlers
  'exception': {
      'handler': 'uvicore.http.exceptions.handlers.web',
  },
```

The default Web exception handler will attempt to locate and render a `Jinja2` template with the same name as the `status_code` inside a `errors` view folder.  For example a `404` error will try to render the `errors/404.j2` template.  If the template does not exist [in ANY package] it will then attempt to locate and render the `errors/catch_all.j2` template.  If that templates does not exist in any package it will return a basic HTML page with the error details.  By creating these templates, you have complete control over each individual error including a custom catch all!




## :material-pound: Custom Web Exception Handlers

To create custom error pages, there is no need to touch `config/app.py` `web.exceptions` config option.  Instead simply create a `http/views/errors/404.j2` and `http/views/errors/catch_all.j2` file in your package and the default Web exception handler will return your new template.  All packages "view paths" are combined and merged.  This means if packageA had a custom `errors/404.j2` and your running app didn't, it would use packageA.  If you created the `errors/404.j2`, your package would win since it is always defined last.  Everything in Uvicore can be overridden, configs, assets, templates, connections etc... Last package defined generally wins in all override battles.

The `Jinja2` variables available to you in these custom error template are
```
{{ request }}
{{ status_code }}
{{ message }}
{{ detail }}
{{ exception }} - will always be blank if debug=False
{{ extra }} - a user defined custom dictionary
```

See the [Source Code](https://github.com/uvicore/framework/blob/master/uvicore/http/exceptions/handlers.py) on Github

```python
async def web(request: Request, e: HTTPException) -> response.HTML:
    """Main exception handler for all Web endpoints"""

    # Get error payload (smart based on uvicore or stock HTTPException)
    (status_code, detail, message, exception, extra, headers) = expand_payload(e)

    try:
        # Try to respond with a errors template, if exists
        return await response.View('errors/' + str(status_code) + '.j2', {
            'request': request,
            **e.__dict__,
        })
    except:

        try:
            # Try to respond with a catch_all template, if exists
            return await response.View('errors/catch_all.j2', {
                'request': request,
                **e.__dict__,
            })
        except:
            # Errors status_code or catch_all template does not exist.
            # Response with generic HTML error
            html = f"""
            <div class="error">
                <h1>{status_code} {message}</h1>
                <p>{detail or ''}</p>

                <h3>Exception:</h3>
                <p>{exception or ''}</p>

                <h3>Extra:</h3>
                <pre>{extra or ''}</pre>
            </div>
            """
            return response.HTML(
                content=html,
                status_code=status_code,
                headers=headers
            )
```
