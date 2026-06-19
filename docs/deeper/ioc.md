---
title: IoC Container
---

# IoC Container

Uvicore has a custom Inversion of Control (IoC) container that registers all of its important classes into a single singleton object (the container).  Uvicore does this by placing `decorators` atop each of its services.

Once a service is registered with the IoC, it can be swapped out by your application's config on demand.  This means you can override **everything** in Uvicore, even the framework's own core foundational components!

If you have ever used Laravel's Service Container, this will feel right at home.

---

## Why Inversion of Control?

The whole point of an IoC container is decoupling.  Your code asks the container for a service *by name* instead of importing and instantiating a concrete class directly.  Because the container decides which concrete class to hand back, you (or any package that depends on yours) can transparently swap that implementation without touching the calling code.

This is what lets a fresh Uvicore app override the framework's `User` model, the `Logger`, the `Application` itself, or any other bound class, purely through config.

---

## Binding Services

Almost everything in Uvicore is bound to the container with a decorator.  The most common is `@uvicore.service()`, but there are specialized decorators that all bind into the same container.

```python
import uvicore

@uvicore.service('acme.wiki.services.weather.Weather', aliases=['Weather'], singleton=True)
class Weather:
    async def forecast(self, city: str):
        ...
```

| Decorator | Used for |
|-----------|----------|
| `@uvicore.service()` | A generic bound service |
| `@uvicore.provider()` | A [Package Provider](provider.md) |
| `@uvicore.model()` | An [ORM Model](../database/orm-basics.md) |
| `@uvicore.table()` | A [Database Table](../database/db-tables.md) |
| `@uvicore.seeder()` | A database [Seeder](../database/seeding.md) |
| `@uvicore.event()` | An [Event](events/index.md) |
| `@uvicore.job()` | A [Job](jobs.md) |
| `@uvicore.controller()` / `@uvicore.routes()` | An HTTP [controller or routes](../http/web/controllers.md) class |

If you don't pass a name, the binding name defaults to the class's fully qualified path, for example `acme.wiki.services.weather.Weather`.  Pass `aliases=[...]` to give it short, friendly names and `singleton=True` if the container should hand back the same instance every time.

!!! note
    Decorators only run when their module is *imported*.  A service that is never imported is never bound.  Your [Package Provider](provider.md) is responsible for importing (registering) the modules your package provides.

---

## Resolving Services

Ask the container for a service with `make()`, using either its full name or any alias.

```python
import uvicore

weather = uvicore.ioc.make('Weather')
forecast = await weather.forecast('Denver')
```

Many of Uvicore's core services are also exposed as convenient globals, so you rarely need `make()` at all.

```python
import uvicore

uvicore.app        # The Application
uvicore.config     # The merged configuration SuperDict
uvicore.log        # The Logger
uvicore.db         # The Database manager
uvicore.cache      # The Cache manager
uvicore.events     # The Event dispatcher
uvicore.ioc        # The IoC container itself
```

---

## Overriding Services

This is where the IoC container truly shines.  Any service bound by name can be replaced by your running application's config, **including Uvicore's own core classes**.

Open your app's `config/app.py` and use the `overrides.ioc_bindings` dictionary.  The key is the original binding name and the value is the module path to your replacement.

```python
# config/app.py
overrides = {
    'ioc_bindings': {
        # Swap the framework User model for your own
        'uvicore.auth.models.user.User': 'acme.wiki.models.user.User',

        # Even swap core framework classes
        'uvicore.foundation.application.Application': 'acme.wiki.overrides.application.Application',
    },
}
```

Your override class is free to **extend** the original.  Uvicore keeps the original binding available under a `_BASE` suffix specifically so your subclass can import its parent without a circular import.

```python
# acme/wiki/models/user.py
import uvicore
from uvicore.auth.models.user import User as BaseUser

@uvicore.model()
class User(BaseUser):
    # Add your own columns, relations and methods on top of the framework's User
    ...
```

!!! tip
    Want to see the original implementation that you just overrode?  Resolve it directly from the container with the `_BASE` suffix:
    ```python
    original = uvicore.ioc.make('uvicore.auth.models.user.User_BASE')
    ```

---

## Binding From a Provider

You can also bind services imperatively from inside a [Package Provider](provider.md) `register()` method using `self.bind()`.

```python
def register(self) -> None:
    self.bind('Weather', 'acme.wiki.services.weather.Weather', singleton=True, aliases=['weather'])
```

This honors the same `overrides.ioc_bindings` config, so a binding made here can still be overridden by a downstream app that consumes your package.
