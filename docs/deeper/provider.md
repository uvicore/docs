---
title: Package Provider
---

# Package Provider

Every Uvicore package contains a `package/provider.py` file.  This is the bootstrap heart of your package.

Similar to how Laravel's Service Providers work, the Package Provider is where your package registers itself and all of its details, its config, routes, commands, models, tables, views and event listeners, into Uvicore during the bootstrap phase.

If your app does only one thing, it talks to its provider.  Adding almost any feature comes down to a single rule: **create the file, then wire it up in the provider.**

---

## Anatomy of a Provider

A provider is a class decorated with `@uvicore.provider()` that defines two lifecycle methods, `register()` and `boot()`.  It composes feature *mixins* to gain helper methods for whatever your package needs to register.

```python
import uvicore
from uvicore.package import Provider
from uvicore.console.package.registers import Cli
from uvicore.database.package.registers import Db
from uvicore.http.package.registers import Http

@uvicore.provider()
class Wiki(Provider, Cli, Db, Http):

    def register(self) -> None:
        # Merge configs, light IoC bindings and early event listeners ONLY
        self.configs([
            {'key': self.name, 'value': self.package_config},
        ])

    def boot(self) -> None:
        # The real work: register connections, models, routes, commands, views...
        self.registers(self.package.config.registers)
        self.register_db_models(['acme.wiki.models'])
        self.register_db_tables(['acme.wiki.database.tables'])
        self.register_routes()
        self.register_commands()
```

Each mixin (`Cli`, `Db`, `Http`, `Redis`, `Templating`) unlocks a family of `register_*()` helper methods.  Only mix in what your package actually uses.

---

## register() vs boot()

Understanding the difference between these two methods is the single most important concept of a provider.  Uvicore calls `register()` on **every** package first, then calls `boot()` on every package.

### register()

`register()` runs very early, **before** all packages have registered.  At this point the configuration system is not yet fully merged, so you have no reliable view of the final config.

Keep `register()` limited to:

- Merging your package config with `self.configs([...])`
- Lightweight IoC bindings with `self.bind(...)`
- Registering early event listeners

!!! warning
    Do not perform real work in `register()`.  The config is not fully merged yet and `self.package` is not available.  Anything substantial belongs in `boot()`.

### boot()

`boot()` runs **after** every package has registered, which means all configs are now deep merged into one complete, accurate view.  This is where you do the real wiring:

- Register database connections, models, tables and seeders
- Register Web and API routes
- Register views, assets and public paths
- Register CLI commands

```python
def boot(self) -> None:
    self.registers(self.package.config.registers)

    self.register_db_connections(
        connections=self.package.config.database.connections,
        default=self.package.config.database.default,
    )
    self.register_db_models(['acme.wiki.models'])
    self.register_db_tables(['acme.wiki.database.tables'])
    self.register_db_seeders(['acme.wiki.database.seeders.seed'])

    self.register_http_web_routes(module='acme.wiki.http.routes.web.Web', prefix=self.package.config.web.prefix)
    self.register_http_api_routes(module='acme.wiki.http.routes.api.Api', prefix=self.package.config.api.prefix)

    self.register_cli_commands(group='wiki', help='Wiki Commands', commands={
        'welcome': 'acme.wiki.commands.welcome.cli',
    })
```

!!! tip
    Need to run code *after every package* has booted (for example to inspect the fully assembled route table)?  Don't try to force provider ordering.  Instead listen to the `uvicore.foundation.events.app.Booted` [event](events/index.md).

---

## Helper Methods by Mixin

| Mixin | Import | Helpers |
|-------|--------|---------|
| `Cli` | `uvicore.console.package.registers` | `register_cli_commands()` |
| `Db` | `uvicore.database.package.registers` | `register_db_connections()`, `register_db_models()`, `register_db_tables()`, `register_db_seeders()` |
| `Http` | `uvicore.http.package.registers` | `register_http_web_routes()`, `register_http_api_routes()`, `register_http_views()`, `register_http_public()`, `register_http_assets()` |
| `Redis` | `uvicore.redis.package.registers` | `register_redis_connections()` |
| `Templating` | `uvicore.templating.package.registers` | `register_templating_paths()`, `register_templating_context_processors()` |

---

## Registration Control

Notice the `self.registers(self.package.config.registers)` call.  This wires your provider up to the `registers` gate in your package's `config/package.py`.  When your package is consumed as a library by *another* app, that host app can disable parts of your registration (routes, commands, models, etc.) through config overrides.  This keeps your package a good citizen in the larger [modular](modular.md) ecosystem.

---

## The Golden Rule

A model, route, command or view that is not registered in the provider simply **does not exist** as far as Uvicore is concerned.  Whenever you add a feature, your final step is always to wire it into `boot()`.
