# API Routing

## FIXME
:material-auto-fix: FIXME

- Route groups and complex group based permissions

examples to organize
```python
        # Passing in existing methods
        def posts():
            return response.Text('Route /posts here')
        route.get('/posts', posts)

        # If your controller has an __init__ with params
        route.controller('contact', options={'param': 'one'})

        # Groups as a Decorator
        @route.group(prefix='/admin')
        def admin():
            @route.get('/profile')
            def profile():
                return response.Text('Route /admin/profile here')

        # Groups as a List of existing methods
        # tokens and themes methods not defined for brevity
        route.group(prefix='/settings', routes=[
            route.get('/tokens', token_settings),
            route.get('/theme', theme_settings),
        ])
```


## :material-pound: Routing Basics

Uvicore separates web and api routes into two files located in the `http/routes` directory.  These route files are loaded from your packages `Service Provider`. Dual routers allow for separate middleware and authentication mechanisms for web and api endpoints.  Route middleware and authentication is located in your packages `config/http.py` file.

All routes are defined inside the routes `register()` method. There are multiple ways to define route endpoints including method passing, decorators, groups and controllers.


### :material-pound::material-pound: Main Routes File

The `http/routes/api.py` file is the main API router file.  All of your API routes stem from this file.  You can define routes directly in this file, however it is best to organize your routes into controllers stored in the `http/api/*` folder.

Controllers help group your routes into logical units, each with their own middleware and auth requirements.

Example of the main API router loading up 3 controllers stored in `http/api/*`

```python title="http/routes/api.py"
import uvicore
from uvicore.http.routing import Routes, ApiRouter

@uvicore.routes()
class Api(Routes):

    def register(self, route: WebRouter):
        """Register Web Route Endpoints"""

        # Define controller base path
        route.controllers = 'acme.wiki.http.api'

        # Include all API Controllers
        route.controller('users', prefix='/users')
        route.controller('topics', prefix='/topics')
        route.controller('tags', prefix='/tags')
```

---




### :material-pound::material-pound: Controllers

Controllers help group your routes into logical units, each with their own middleware and auth requirements.  Your API controllers are stored in the `http/api/*` folder.

You can generate a new controller from the Uvicore CLI

```bash
./uvicore gen api-controller --help
./uvicore gen api-controller topics
```

```python title="http/api/topics.py"
import uvicore
from uvicore.http.routing import ApiRouter, Controller

@uvicore.controller()
class Topics(Controller):

    def register(self, route: ApiRouter):
        """Register API Controller Endpoints"""

        @route.get('/example1', tags=['Examples'])
        async def example1() -> Dict:
            """This docstring shows up in openapi"""
            return {'welcome': 'to uvicore API!'}
```

---





## :material-pound: Overriding Packages Routes

When consuming other developers packages, you may want to override some of their routes with your own.  For example, if you are building a CMS which includes a 3rd party `blog` package which contains a `/search` route named `blog.search` and you want to replace it with your own search page.

Because all of your route names are automatically `prefixed` with your package, you must disable the auto-prefixer for your own custom search override.  This will allow you to define the entire route path and name.

```python
# Your CMS package wants to override the blog packages search route
@route.get('/search', name='blog.search', autoprefix=False)
```

---





## :material-pound: Digging Deeper

In your `http/routes/api.py` file you can actually load your controllers in two different ways.  One is using 'strings' which automatically locate and import your controller python modules.  The other is by importing those python modules yourself.

```python
# String based
route.controllers = 'app.http.controllers'
route.controller('users')
route.controller('topics')
route.controller('tags')

# Module based
from acme.wiki.http.api.users import Users
from acme.wiki.http.api.topics import Topics
from acme.wiki.http.api.tags import Tags
route.controller(Users)
route.controller(Topics)
route.controller(Tags)
```

---









## END OF NEW DOCS, OLD BELOW

:material-auto-fix: FIXME










## OBSOLETE WARNING

This document is obsolete now that I refactored the entire routing infrastructure.

Obsolete below this line




## Route Prefixes and Names


FIXME, this is WEB specific, make a new one, better that is API specific
List out actual API route names


All routes are automatically given a route prefix which you define in `config/http.py`.  This prefix allows consuming developes of your package to alter each packages base URI to fit their needs.  For example, if you wrote a `wiki` app you probably want a simple `/` prefix for all routes.  If a developer consumes your `wiki` as a package inside their own app, they may override your wiki `config/http.py` and alter the prefix to `/wiki`.

Because of this route prefix, URL paths should never be referenced in views and controllers as they are subject to change and your links will break.  Instead you should always reference the `route name`.

All routes are automatically given a `route name`.  The name is based on your route path (naturally excluding your package wide prefix).  This name is also prefixed with your package name found in `config/package.py`.  For example `wiki.about`, `wiki.admin.profile`.

You can override the automatic name When defining routes, groups and controllers.  Prefixes can be defined on route groups and controllers.

```python
# Example app where config/package.py name='wiki'

# Default name based on the path
@route.get('/user/account')
def users():
    return response.Text('Name is wiki.user.account')

# Specifying a custom name
@route.get('/user/account', name='account')
def users():
    return response.Text('Name is wiki.account')

# Group default name based on path
@route.group(prefix='/admin')
def admin():
    @route.get('/profile')
    def profile():
        return response.Text('Name is wiki.admin.profile')

# Group with a custom name
@route.group(prefix='/admin', name='backend')
def admin():
    @route.get('/profile')
    def profile():
        return response.Text('Name is wiki.backend.profile')

# Controllers are by default not given a name prefix
# Assuming controller has a /home endpoint
@route.controller('home')  # name will be wiki.home

# Controllers with a prefix are given a name based on the prefix
# Assuming controller has a /home endpoint
@route.controller('home', prefix='my')  # name will be wiki.my.home

# Controllers with a custom name
# Assuming controller has a /home endpoint
@route.controller('home', name='our')  # name will be wiki.our.home
```



