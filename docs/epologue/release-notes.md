# Release Notes

## 0.1

Initial public beta release of Uvicore.

Used in production by a few internal companies, running a few dozen APIs and basic websites.

Not 100% feature complete.  The web at large would have many requests for enhancement.


## 0.2

See [Upgrade 0.1 to 0.2](upgrade/from-0.1-to-0.2.md) for details.

Refactor of the "service" concept. The word `service` removed in favor or `package`, `provider`, and `registers`.


## 0.3

See the [0.3 Changelog](changelog/0.3.md) and [Upgrade 0.2 to 0.3](upgrade/from-0.2-to-0.3.md) for details.

Removed the async `encode/databases` wrapper and upgraded `SQLAlchemy` from from 1.4 up to the new async SQLAlchemy 2.0.

### Documentation Improvements

Added comprehensive documentation for HTTP web development:
- New [HTTP Web Guide](../http/web/index.md) covering web controllers, views, routing, and templates
- Expanded [Controllers](../http/web/controllers.md) documentation with real-world examples
- Enhanced [Views](../http/web/views.md) documentation with template patterns and best practices


## 0.4

See the [0.4 Changelog](changelog/0.4.md) and [Upgrade 0.3 to 0.4](upgrade/from-0.3-to-0.4.md) for details.

A **breaking** release that modernizes the web stack and hardens the database and ORM layers.

- **Modernized web stack** - upgraded to **Pydantic v2**, **FastAPI 0.137** and **Starlette 1.3**.  This is breaking for application code: model `update_forward_refs()` removal (forward refs now rebuilt centrally), explicit defaults on optional Pydantic fields, `on_event` → lifespan `Startup`/`Shutdown` events, `@validator` → `@field_validator`, and serialization renames (`.dict()` → `.model_dump()`).
- **[Inline table definitions](../database/db-tables.md#tables-inline-on-the-model)** - define a model's schema directly on the model with `__connection__` + `__tablename__` + a raw `__table__` list, no separate `Table` class required.
- **Expanded query operators** - `ilike`/`!ilike`, `between`/`!between`, `<>`, `not in`, `not like`, and explicit `is` / `is not`, all case-insensitive and whitespace tolerant.
- **Cross-database robustness** - validated against real Postgres, MySQL and MariaDB, with portable auto-increment primary keys, type-safe `find()`, and `postgres`/`postgresql` dialect normalization.
- **ORM fixes** - multiple `*Many` includes no longer cartesian-multiply, `HasMany` `delete()`/`set()` now work, and the auto-API create endpoint is fixed.
- **HTTP client moved to httpx** (0.4.2) - the bundled async [HTTP Client](../deeper/http-client.md) switched from `aiohttp` to `httpx` and `aiohttp` was dropped entirely.  This is breaking for code that calls `uvicore.ioc.make('aiohttp')`: requests are now awaited directly (no `async with`) and the response uses `r.status_code`/`r.text`/`r.json()`.
