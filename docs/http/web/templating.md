---
title: Web Templating
---

# Web Templating

Uvicore renders all of its [views](views.md) with [Jinja2](https://jinja.palletsprojects.com/).  The templating engine is wired up through the [package and provider](../../deeper/provider.md) system, so any package can contribute template paths, custom filters, tests and context processors, and the running app can override them.

!!! note
    This page covers templating in the context of Web views.  To use the templating engine *outside* of HTTP (for emails, PDFs or CLI output), see [Templating (Digging Deeper)](../../deeper/templating.md).

---

## Registering View Paths

Tell the engine where your templates live by registering your views module from your [Package Provider](../../deeper/provider.md).

```python
# acme/wiki/package/provider.py
def register_views(self) -> None:
    self.register_http_views(['acme.wiki.http.views'])
```

Templates are discovered by their path *inside* that module.  A file at `http/views/wiki/welcome.j2` is referenced as `'wiki/welcome.j2'`, and `http/views/email/reset.j2` as `'email/reset.j2'`.

### Path Precedence

When several packages register view paths, the running app's paths take precedence, which means **your app can override a package's templates** simply by providing a template of the same name.  This is the same override philosophy you'll find throughout Uvicore's [modular](../../deeper/modular.md) design.

---

## Built-In Template Helpers

Every rendered template has access to a few helpers out of the box.

### `url(name, **params)`

Generate a URL from a [route name](routing.md#prefixes-and-route-names).  Pass path parameters as keyword arguments.

```html
<a href="{{ url('wiki.home') }}">Home</a>
<a href="{{ url('wiki.user.detail', user_id=user.id) }}">Profile</a>
```

### `asset(path)`

Generate a URL for a static asset from your `http/public/assets/` directory.

```html
<link rel="stylesheet" href="{{ asset('wiki/css/style.css') }}">
<img src="{{ asset('wiki/images/logo.png') }}" alt="Logo">
```

### `request`

The current request object, your way to the user and request details.

```html
<p>Current user: {{ request.user.name }}</p>
<p>Current path: {{ request.url.path }}</p>
```

---

## Custom Filters, Tests and Context

Register your own Jinja filters, tests and context functions from your provider with `register_http_view_context_processors()`.

```python
# acme/wiki/package/provider.py
def register_views(self) -> None:
    self.register_http_views(['acme.wiki.http.views'])

    def shout(value):
        return str(value).upper()

    self.register_http_view_context_processors({
        # Jinja filters:  {{ name | shout }}
        'filters': {
            'shout': shout,
        },
        # Global functions callable in any template:  {{ greeting() }}
        'context_functions': {
            'greeting': lambda: 'Hello!',
        },
        # Custom Jinja tests:  {% if value is prime %}
        'tests': {},
    })
```

```html
{{ message | shout }}
```

---

## Engine Features

Uvicore's Jinja2 engine ships configured with sensible, secure defaults:

- `autoescape=True` to protect against XSS
- `keep_trailing_newline=True` for cleaner output
- support for custom filters, tests and context functions
- [view composers](../../deeper/templating.md) for injecting shared context into matching views

!!! tip "Templating tips"
    - Organize templates by feature or section under `http/views/`.
    - Use filters for repeated formatting logic and context functions for app-wide data.
    - Keep business logic in [controllers](controllers.md); keep presentation logic in templates.
    - Lean on template inheritance for consistent page layouts.
