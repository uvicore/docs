---
title: Web Views
---

# Web Views

A view is a Jinja2 template rendered and returned as an HTML response.  In Uvicore you render one with the async `response.View()` helper, hand it a template name and a context dict, and you're done.

---

## Rendering a View

From a web [controller](controllers.md), `await response.View()` with the template name and a context.  The context **must** include the `request` object.

```python
import uvicore
from uvicore.http import Request, response
from uvicore.http.routing import WebRouter, Controller

@uvicore.controller()
class Welcome(Controller):

    def register(self, route: WebRouter):

        @route.get('/', name='welcome')
        async def welcome(request: Request):
            return await response.View('wiki/welcome.j2', {
                'request': request,
                'title': 'Welcome',
                'message': 'Hello, World!',
            })

        return route
```

Template names are resolved against the view paths your provider registered with `register_http_views(['acme.wiki.http.views'])` (see [Templating](templating.md)).  A file at `http/views/wiki/welcome.j2` is referenced as `'wiki/welcome.j2'`.

---

## The Request Context

Every view context must include `request`.  It's what powers the [current user](authentication.md) and the built-in template helpers.

```python
return await response.View('wiki/profile.j2', {
    'request': request,
    'user': request.user,
})
```

---

## Response Options

`response.View()` accepts the usual response options:

```python
return await response.View(
    'wiki/welcome.j2',
    {'request': request},
    status_code=200,
    headers={'X-Custom-Header': 'value'},
)
```

- `status_code` - HTTP status (default `200`)
- `headers` - additional response headers
- `media_type` - content type override

Rendering an error page is just a different status code:

```python
return await response.View('errors/not-found.j2', {'request': request}, status_code=404)
```

---

## Template Inheritance

Use Jinja2 inheritance for consistent layouts.

```html
<!-- http/views/wiki/base.j2 -->
<!DOCTYPE html>
<html>
<head>
  <title>{% block title %}{{ app_name }}{% endblock %}</title>
</head>
<body>
  {% block content %}{% endblock %}
</body>
</html>
```

```html
<!-- http/views/wiki/welcome.j2 -->
{% extends "wiki/base.j2" %}

{% block title %}Welcome - {{ app_name }}{% endblock %}

{% block content %}
  <h1>{{ message }}</h1>
  <p>Hello, {{ request.user.name }}</p>
{% endblock %}
```

---

## Conditional Rendering by Permission

Use the request user to show or hide UI based on the visitor's permissions.  `UserInfo` exposes `can()` and `is_authenticated`.

```html
{% if request.user.can('admin') %}
  <a href="{{ url('wiki.admin') }}">Admin Panel</a>
{% endif %}

{% if request.user.is_authenticated %}
  <p>Welcome back, {{ request.user.name }}</p>
{% else %}
  <a href="{{ url('wiki.login') }}">Login</a>
{% endif %}
```

---

## Linking and Assets

Reach for the built-in `url()` and `asset()` helpers rather than hardcoding paths, see [Templating](templating.md#built-in-template-helpers).

```html
<a href="{{ url('wiki.home') }}">Home</a>
<link rel="stylesheet" href="{{ asset('wiki/css/style.css') }}">
```

---

## Beyond Web Views

The templating engine isn't only for HTTP views, you can render templates anywhere in your app, for emails, PDFs, generated files or CLI output.  See [Templating (Digging Deeper)](../../deeper/templating.md) for standalone usage.

!!! tip "View tips"
    - Always include `request` in your context.
    - Keep business logic in [controllers](controllers.md) and models; keep presentation logic in templates.
    - Use template inheritance for consistent layouts.
    - Use `url()` and `asset()` for links and static files, never hardcoded paths.
