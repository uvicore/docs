# Views

asdf


## Templates without HTTP

The template system works with HTTP as a templated response but also without any Web request/response at all.  For example a CLI app that generates HTML->PDF using the template system.

You will notice with the HTTP mixin you get a `self.register_http_views` and with the Templating mixin you get a `self.register_templating_paths`.  These both add paths to the same template engine.  The `self.register_http_views` however only applies with running in HTTP mode (serving the app).  So only `self.register_templating_paths` are added in CLI+HTTP mode.

In your provider include the `from uvicore.templating.package.registers import Templating` mixin

```python
# Define template paths
self.register_templating_paths(['bi.assets.templates'])

def up_filter(input):
    return input.upper()

def up_filter2(context, input):
    return input.upper()

self.register_templating_context_processors({
    'context_filters': {
        'up': up_filter2,
    },
    'filters': {
        'up': up_filter,
    },
})
```

Now from some non-web code

```python
from uvicore.templating.engine import Templates
html = Templates.render('report.j2', {
    'topLeft': 'Top Left <b>HERE</b>!!!',
    'topRight': 'Top Right <b>HERE</b>!!!',
    'main': 'report <b>HTML</b> here!'
})
dd(html)
```
