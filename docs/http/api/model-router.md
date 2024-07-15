# API Model Router



## Organize Me

:material-auto-fix: FIXME

The auto model router already has `model.crud` style permissions attached and will require auth as long as you have some api auth middleware enabled.  If you have auth middleware enabled but you still want autoapi routes to be public, or to use a single permission, override it with the options argument on `.include()`

This will wipe out all scopes, meaning all auto endpoints are now PUBLIC
```python
# Include dynamic model CRUD API endpoints (the "auto API")!
# These routes are automatically protected by model.crud style permissions.
@route.group()
def autoapi():
    route.include(ModelRouter, options={
        'scopes': []
    })
```

This will set all to just 'authenticated', so the `model.crud` scopes are wiped out.
```python
# Include dynamic model CRUD API endpoints (the "auto API")!
# These routes are automatically protected by model.crud style permissions.
@route.group()
def autoapi():
    route.include(ModelRouter, options={
        'scopes': ['authenticated']
    })
```

This will append this scope to the existing auto `model.crud` scopes. And endpoints are only allows if user has ALL permissions, ie: both `['allowcrud', 'posts.read']` (unless your `admin`, it always wins)
```python
@route.group(scopes=['allowcrud'])
def autoapi():
    route.include(ModelRouter)
```
