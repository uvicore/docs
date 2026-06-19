---
title: Web Controllers
---

# Web Controllers

Controllers are where your web routes actually live.  They group related endpoints into a tidy class, handle the incoming [request](routing.md) and return a [response](views.md), usually a rendered view.  You wire them into your app from your [routes file](routing.md), which itself is registered by your [Package Provider](../../deeper/provider.md).

---

## Defining a Controller

A controller is a class decorated with `@uvicore.controller()` that defines a `register(self, route)` method.  Inside `register()` you declare your endpoints, and you always `return route` at the end.

```python
import uvicore
from uvicore.http import Request, response
from uvicore.http.routing import WebRouter, Controller

@uvicore.controller()
class Welcome(Controller):

    def register(self, route: WebRouter):
        """Register web routes for this controller."""

        @route.get('/', name='home')
        async def home(request: Request):
            return await response.View('wiki/welcome.j2', {
                'request': request,
                'message': 'Welcome to Uvicore!',
            })

        @route.get('/about', name='about')
        async def about(request: Request):
            return await response.View('wiki/about.j2', {'request': request})

        return route
```

Generate a controller skeleton from the CLI:

```bash
./uvicore gen controller welcome
```

!!! note
    Every web handler receives `request: Request` and must pipe it into the view context.  Views are rendered with the async `await response.View(name, context)` helper.

!!! tip
    This page covers what goes *inside* a controller.  For how controllers are loaded, prefixed, named and grouped, declaring `route.controllers`, including them and `route.group()`, see [Web Routing](routing.md).

---

## Accessing the Request

Every route handler receives the `request` object, your gateway to everything about the incoming request:

| Accessor | What it gives you |
|----------|-------------------|
| `request.user` | The current `UserInfo` (real even when anonymous, see [Authentication](authentication.md)) |
| `request.query_params` | URL query string parameters |
| `request.path_params` | Dynamic path segments |
| `request.headers` | HTTP headers |
| `request.cookies` | Cookie values |
| `await request.json()` | Parsed JSON body |
| `await request.form()` | Parsed form data |
| `await request.body()` | Raw request body |
| `request.url`, `request.method` | URL and method info |

```python
@route.get('/search', name='search')
async def search(request: Request):
    query = request.query_params.get('q', '')
    return await response.View('wiki/search.j2', {'request': request, 'query': query})
```

You can also let Uvicore inject typed parameters for you, query strings, path params and form fields, using the FastAPI-style param helpers from `uvicore.http.params`.

```python
from uvicore.http.params import Form

@route.post('/search', name='search.post')
async def search(request: Request, q: str = Form(...)):
    ...
```

---

## Returning Responses

The `response` namespace gives you a helper for every kind of response.  Import the namespace, or the individual helpers.

```python
from uvicore.http import response
```

### View (HTML)

The async `View()` helper renders a Jinja template.  Pass the template name and a context dict that includes `request`.

```python
@route.get('/', name='home')
async def home(request: Request):
    return await response.View('wiki/home.j2', {'request': request, 'title': 'Home'})
```

### Other Response Types

```python
return response.HTML('<h1>Hello</h1>')
return response.Text('Plain text')
return response.JSON({'status': 'ok'})
return response.Redirect('/dashboard')
return response.File('/path/to/file.pdf')
```

See [Views](views.md) for everything `response.View()` can do, including status codes and headers.

---

## Path Parameters

Declare dynamic segments with `{param_name}` and read them from `request.path_params` (or accept them as typed function arguments).

```python
@route.get('/users/{user_id}', name='user.detail')
async def user_detail(request: Request, user_id: int):
    return await response.View('wiki/user.j2', {'request': request, 'user_id': user_id})
```

Named routes make URL generation a breeze in your templates:

```html
<a href="{{ url('wiki.user.detail', user_id=123) }}">View User</a>
```

---

## Controller-Wide Authorization

Need every route in a controller to require the same permissions?  Declare class-level `scopes` (or `auth` / `middleware`) and they apply to the whole controller.  See [Authorization](authorization.md) for the full picture.

```python
@uvicore.controller()
class AdminPanel(Controller):
    scopes = ['authenticated', 'admin']

    def register(self, route: WebRouter):
        ...
        return route
```

---

## Keeping Controllers Lean

Controllers should orchestrate, not implement.  Pull real business logic into your [ORM models](../../database/orm-basics.md), a [service](../../deeper/ioc.md) or a [Job](../../deeper/jobs.md), and let the controller stay focused on turning a request into a response.

```python
@route.get('/posts', name='posts')
async def posts(request: Request):
    from acme.wiki.models.post import Post
    posts = await Post.query().include('creator').order_by('id', 'DESC').get()
    return await response.View('wiki/posts.j2', {'request': request, 'posts': posts})
```

---

## Testing Controllers

Web controllers are exercised with Uvicore's async test client.

```python
import pytest

@pytest.mark.asyncio
async def test_home_page(app1, client):
    res = await client.get('/')
    assert res.status_code == 200
    assert b'Welcome' in res.content
```

---

!!! tip "Controller tips"
    - Keep controllers lean, move business logic into models, services or jobs.
    - Always pipe `request` into your view context, templates need it for the user and helpers.
    - Use **named routes** so refactoring URLs doesn't break your templates.
    - Group related endpoints in one controller, and put shared auth at the class or [group](routing.md#route-groups) level.
