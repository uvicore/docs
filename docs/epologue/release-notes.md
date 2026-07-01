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
- **`.env` loading changed** (0.4.2) - `environs` was upgraded to 15.x and `read_env()` no longer populates `os.environ`, it loads only into the instance it is called on.  Existing apps must change `package/bootstrap.py` to read `.env` into the **shared** `env` instance (`from uvicore.configuration import env; env.read_env(...)`) instead of a throwaway `Env()`, or their configs will silently see no `.env` values.
- **Composite (multi-column) relation & join keys** (0.4.3) - relation `foreign_key`/`local_key` and the query builder's `.join()` now accept ordered column lists (or an `sa.and_()` expression) to build multi-column JOIN `ON` clauses, required for sharded backends like Vitess/PlanetScale.  The same release also fixes eager-loading on non-primary-key natural keys and `*Many` includes combined with `.limit()`/`.offset()`.  See the [0.4 Changelog](changelog/0.4.md#043).
- **Redis connection `options`** (0.4.5) - a Redis connection in `config/package.py` now accepts an optional `options` dict whose keys are passed straight through as keyword arguments to the underlying [redis-py](https://redis.readthedocs.io/) async client (`from_url()`) - e.g. `health_check_interval`, `socket_timeout`, `max_connections`, `decode_responses`.  This mirrors the `options` dict on a database connection.  Purely additive.  See the [0.4 Changelog](changelog/0.4.md#045).
- **Leaner OpenAPI / Swagger docs** (0.4.3) - the API server now collapses FastAPI's duplicate `Foo-Input`/`Foo-Output` schemas into a single `Foo` (new `api.openapi.separate_schemas`, default `False`), and new Swagger knobs keep the docs responsive for apps with large model graphs: `api.openapi.docs.models_expansion` (default `-1`) hides the standalone Schemas section, `docs.model_expansion` collapses each operation's nested model tree for instant expand, and `docs.parameters` passes arbitrary settings straight to Swagger UI.  Together they roughly halve `openapi.json` size and keep the UI snappy.  See the [0.4 Changelog](changelog/0.4.md#043).
