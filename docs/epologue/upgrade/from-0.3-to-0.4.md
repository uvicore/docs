# Upgrade 0.3 to 0.4

!!! danger "0.4 is a breaking release"
    Unlike earlier 0.4 previews, the shipping **0.4.0** upgrades the entire web stack:
    **Pydantic v1 → v2**, **FastAPI 0.115 → 0.137**, and **Starlette 0.45 → 1.3**.  Pydantic v2
    is the headline, FastAPI dropped Pydantic v1 entirely (in 0.126) so the two move together.
    There is no "do nothing" path this time, **plan to read this whole page before you bump.**

The good news: Uvicore's own layer absorbs most of the churn.  Your `Field()` definitions,
relations, tables, query builder, configs, seeders and Guard/scopes are **unchanged**.  The
breakage clusters in a handful of predictable spots, listed below worst-first.

See the [0.4 Changelog](../changelog/0.4.md) for the full feature list.

---

## Required Steps

These will stop your app from booting or running until addressed.

### 1. Remove `update_forward_refs()` from your models

In Pydantic v2 `update_forward_refs()` is an alias for `model_rebuild()`, which eagerly builds a
model's **entire** related-model schema graph.  Called at the bottom of each model file (mid
import-cascade), it raises `PydanticUndefinedAnnotation` before the sibling models exist.

Uvicore now rebuilds **every registered model once, centrally**, after all model modules are
imported (see `database/package/bootstrap.py`), so the per-file call is both broken and redundant.
Delete it.  **Keep** `from __future__ import annotations` and the bottom-of-file relation imports,
those are still required so the forward references can resolve.

```python
# acme/wiki/models/post.py
from __future__ import annotations          # <-- KEEP (makes relations forward refs)
from uvicore.orm import Model, ModelMetaclass, Field, BelongsTo

@uvicore.model()
class Post(Model['Post'], metaclass=ModelMetaclass):
    __tableclass__ = table.Posts
    id: Optional[int]   = Field('id', primary=True, read_only=True)
    creator: Optional[User] = Field(None, relation=BelongsTo('acme.wiki.models.user.User'))

from acme.wiki.models.user import User  # isort:skip      # <-- KEEP (resolves the forward ref)
# Post.update_forward_refs()             <-- DELETE: Uvicore rebuilds models for you now
```

### 2. Add explicit defaults to your own `Optional` Pydantic models

Pydantic v2 no longer treats `Optional[x]` as implicitly defaulting to `None`, an optional field
with no default is now **required** and raises `ValidationError`.  This affects the plain Pydantic
models you write yourself (request/response bodies, DTOs).

```python
from pydantic import BaseModel

class SearchQuery(BaseModel):
    term: str
    limit: Optional[int]          # v1: optional  |  v2: REQUIRED -> ValidationError
    limit: Optional[int] = None   # v2 fix: add the explicit default
```

!!! note "Your ORM models are exempt"
    Uvicore's `ModelMetaclass` defaults every ORM field to `None` for you (models are populated
    from partial DB rows), so your `Field(...)` definitions need **no** changes.  This step is only
    about hand-written `BaseModel` subclasses.

### 3. Replace `on_event` startup/shutdown hooks

Starlette 1.0 removed `on_event`/`add_event_handler` from the application, so
`@uvicore.app.http.on_event("startup")` no longer exists.  Listen to Uvicore's HTTP server events
instead (typically from your provider's `boot()`):

```python
# Before (0.3)
@uvicore.app.http.on_event('startup')
async def startup():
    ...

# After (0.4)
from uvicore.http.events.server import Startup, Shutdown

async def on_http_startup(event):
    ...

Startup.listen(on_http_startup)     # or Startup.listen('acme.wiki.events.listeners.on_http_startup')
Shutdown.listen(on_http_shutdown)
```

### 4. Port custom validators

Pydantic v1 `@validator` / `@root_validator` are superseded by `@field_validator` /
`@model_validator` (different signatures and return semantics).

```python
# Before
from pydantic import validator
@validator('slug')
def lower(cls, v): return v.lower()

# After
from pydantic import field_validator
@field_validator('slug')
@classmethod
def lower(cls, v): return v.lower()
```

### 5. Fix removed Pydantic imports

If any of your code imports these, they were moved or deleted in v2:

| Pydantic v1 | Pydantic v2 |
|---|---|
| `from pydantic.generics import GenericModel` | `class X(BaseModel, Generic[T])` (BaseModel is generic) |
| `from pydantic.typing import ...` | the stdlib `typing` module |
| `from pydantic.fields import ModelField` | `FieldInfo` (different shape) via `Model.model_fields` |
| custom type `__get_validators__` / `__modify_schema__` | `__get_pydantic_core_schema__` / `__get_pydantic_json_schema__` |

---

## HTTP Client Changed From aiohttp to httpx

Uvicore's bundled async [HTTP Client](../../deeper/http-client.md) switched from **`aiohttp`** to
**`httpx`** in 0.4.  `aiohttp` is no longer a dependency.  If any of your code calls
`uvicore.ioc.make('aiohttp')`, it will fail until updated.

The client is now resolved as `http_client` or `httpx`, the request is **awaited directly** (no
`async with`), and the response accessors are **not** awaited:

```python
# Before (0.3 — aiohttp)
http = uvicore.ioc.make('aiohttp')
async with http.get(url, auth=aiohttp.BasicAuth(user, pw)) as r:
    if r.status == 200:
        data = await r.json()

# After (0.4 — httpx)
http = uvicore.ioc.make('httpx')              # or 'http_client'
r = await http.get(url, auth=(user, pw))
if r.status_code == 200:
    data = r.json()
```

The full mapping of every aiohttp idiom to its httpx equivalent:

| aiohttp (0.3) | httpx (0.4) |
|---|---|
| `uvicore.ioc.make('aiohttp')` | `uvicore.ioc.make('httpx')` *(or `'http_client'`)* |
| `async with http.get(url) as r:` | `r = await http.get(url)` |
| `async with http.post(url, json=p) as r:` | `r = await http.post(url, json=p)` |
| `r.status` | `r.status_code` |
| `await r.text()` | `r.text` |
| `await r.json()` | `r.json()` |
| `await r.read()` | `r.content` |
| `aiohttp.BasicAuth(user, pw)` | `(user, pw)` *or* `httpx.BasicAuth(user, pw)` |
| `aiohttp.FormData()` + `.add_field(...)` | `data={...}` (form) and/or `files=[...]` (uploads) |
| repeated `add_field('to', x)` | `data={'to': ['a', 'b']}` (list value) |
| `await session.close()` | `await client.aclose()` |

The two gotchas that catch everyone:

1. **No `async with` on the request.** httpx awaits the request and hands you a fully‑read
   response.  `async with` is only for [streaming](../../deeper/http-client.md#streaming-large-responses).
2. **Response accessors aren't awaited.**  `r.text` is a property and `r.json()` is a sync method,
   `await`ing either is an error.

See the [HTTP Client](../../deeper/http-client.md) guide for the complete, httpx‑based API including
auth helpers, timeouts, streaming, error handling and building your own client instances.

!!! note "httpx is also the pytest client"
    Uvicore already used `httpx` internally for its in‑process ASGI test client, so 0.4 simply
    consolidates onto the one library.  If you write framework‑style tests with
    `httpx.AsyncClient`, note the modern signature is
    `AsyncClient(transport=ASGITransport(app=...))` (the old `app=` shortcut was removed in
    httpx 0.28).

---

## How `.env` Is Loaded Changed (environs upgrade)

0.4 upgraded the `environs` library (up through **15.x**).  As of `environs >= 11`, `read_env()`
loads variables **only into the `Env` instance it is called on** — it no longer exports them to the
global `os.environ`.  Older `environs` (≤ 9) loaded `.env` via python-dotenv's `load_dotenv`, which
populated `os.environ`, so *every* `Env` instance could see the values.

This breaks the default `package/bootstrap.py` that earlier app scaffolds shipped.  It read `.env`
into a **throwaway** `Env()` instance:

```python
# Before — loads .env into a brand-new instance that is then discarded
from uvicore.configuration import Env
...
Env().read_env(base_path + '/.env')
```

But your config files read variables through the **shared** `env` exported from
`uvicore.configuration`:

```python
from uvicore.configuration import env
config = {'name': env('APP_NAME', 'Acme')}
```

Under modern `environs` those are two different stores, so the configs see **none** of your `.env`
values and silently fall back to the defaults in `env('KEY', default)`.  Fix it by reading `.env`
into that same shared instance:

```python
# After — load .env into the shared instance the configs actually read
from uvicore.configuration import env
...
env.read_env(base_path + '/.env')
```

!!! tip "One-line fix"
    In `package/bootstrap.py`, change the import from `Env` to `env` and the call from
    `Env().read_env(...)` to `env.read_env(...)`.  Newly generated apps already have this, only
    apps scaffolded before this change need the edit.

---

## Deprecations

These still work but emit `PydanticDeprecatedSince20` warnings, migrate when convenient.

- **Serialization methods:** `.dict()` → `.model_dump()`, `.json()` → `.model_dump_json()`,
  `.copy()` → `.model_copy()`, `.parse_obj()` → `.model_validate()`, `.construct()` →
  `.model_construct()`.
- **Model config:** the inner `class Config:` → `model_config = ConfigDict(...)`.  Several keys
  were renamed: `schema_extra` → `json_schema_extra`, `orm_mode` → `from_attributes`,
  `allow_population_by_field_name` → `populate_by_name`.
- **Response classes:** `response.ORJSON` / `response.UJSON` are deprecated upstream in FastAPI but
  still re-exported.

```python
# Before
class DeleteQuery(BaseModel):
    where: Optional[dict] = None
    class Config:
        schema_extra = {"example": {"where": {"id": 1}}}

# After
from pydantic import ConfigDict
class DeleteQuery(BaseModel):
    where: Optional[dict] = None
    model_config = ConfigDict(json_schema_extra={"example": {"where": {"id": 1}}})
```

---

## Behavioral Changes To Watch

No error, but the output or behavior shifts:

- **Stricter validation/coercion.** Pydantic v2 is less forgiving about loose type coercion and
  unexpected types when constructing models from input.
- **JSON output differs.** `model_dump()` handles `None`/nested values differently than v1
  `.dict()`, and FastAPI now generates **OpenAPI 3.1** (was 3.0).  Any test that asserts an exact
  response body or `openapi.json` structure will need updating.  Field metadata you set via
  `Field()` (`read_only`, `write_only`, `sortable`, …) still appears in the schema (as `readOnly`,
  `writeOnly`, and the `x-tra` extension block).
- **Python floor.** FastAPI 0.137 requires **Python ≥ 3.10**.  Uvicore already required 3.10, so
  compliant apps are unaffected.

---

## What Is *Not* Affected

To keep the scope honest, these public surfaces are unchanged in 0.4:

- The uvicore **`Field()` API** — `primary`, `read_only`, `write_only`, `description`,
  `min_length`/`max_length`, `relation=...`, `callback=`, etc.
- **All relation types** (`BelongsTo`, `HasOne/Many`, `BelongsToMany`, the `Morph*` family).
- **Tables**, the **ORM query builder**, **seeders**, **config files**, and **Guard / auth scopes**.

---

## New: Inline Tables

You can now define an ORM model's table schema [fully inline](../../database/db-tables.md#tables-inline-on-the-model), without a separate `Table` class, using `__connection__`, `__tablename__` and a raw `__table__` column list.

```python
@uvicore.model()
class Post(Model['Post'], metaclass=ModelMetaclass):
    __connection__ = 'wiki'
    __tablename__ = 'posts'
    __table__ = [
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('title', sa.String(length=100)),
    ]
    id: Optional[int] = Field('id', primary=True, read_only=True)
    title: str = Field('title')
```

Your existing `__tableclass__` models are completely unaffected, this is just an additional option.

---

## New: More Query Operators

`.where()`, `.or_where()`, `.filter()` and `.or_filter()` now accept more operators: `<>`, `<=`, `not in`, `not like`, `ilike`, `!ilike`, `between`, `!between`, and explicit `is` / `is not`.  Operators are now case-insensitive and whitespace tolerant.

The most useful addition is **`ilike`** for portable case-insensitive matching:

```python
# 'like' is case-sensitive on Postgres but not on SQLite/MySQL.
# 'ilike' is case-insensitive everywhere.
posts = await Post.query().where('title', 'ilike', '%uvicore%').get()
```

---

## New: Composite (Multi-Column) Joins

Relations and the query builder can now join on **multiple columns** at once, ANDed together in
declared order, needed for sharded backends like **Vitess / PlanetScale** that must join on the
shard key in addition to the natural key.  This is purely additive; single-column relations and
joins are unchanged (a single string key is just a one-element composite).

```python
# Relation keys accept ordered lists (paired positionally)
items: Optional[List[RoItem]] = Field(None,
    relation=HasMany('vfi.core.models.ro_item.RoItem',
        foreign_key=['qgroup_id', 'client_id', 'ro_key'],   # columns on ro_items
        local_key =['qgroup_id', 'client_id', 'key']))      # columns on ros

# The DB query builder's .join() accepts a full sa.and_() ON clause
.join('ro_items', sa.and_(
    ros.qgroup_id == items.qgroup_id,
    ros.client_id == items.client_id,
    ros.key       == items.ro_key,
), alias='items')
```

See [Composite Relation Keys](../../database/orm-querybuilder.md#composite-multi-column-relation-keys) and the [Joins section](../../database/db-queries.md#joins).

---

## Behavior Improvements to Be Aware Of

These are bug fixes rather than breaking changes, but they alter behavior you may have worked around:

- **Multiple `*Many` includes.** Eager-loading several many-relations in one query (for example `.include('comments', 'tags')`) previously returned duplicated/cartesian rows.  Results are now correct.  If you had added manual de-duplication to compensate, you can remove it.
- **Auto-increment primary keys.** Inserts no longer send an explicit `NULL` primary key.  Behavior is unchanged on SQLite, and inserts that previously failed on Postgres/MySQL now succeed.
- **`find()` by primary key** coerces the value to the column's type, so passing a string id works on strict engines like Postgres.
- **`HasMany` `delete()` / `set()`** now work (they previously raised).
- **Eager-loading on a natural (non-primary-key) `local_key`** (0.4.3).  A `HasMany` / `HasOne` whose `local_key` is *not* the parent's primary key (e.g. `ros.key` ↔ `ro_items.ro_key`) now attaches its children correctly; such `*Many` collections previously came back empty.  If you worked around this by querying children separately, you can now just `.include()` them.
- **`*Many` includes combined with `.limit()` / `.offset()`** (0.4.3).  Limit/offset now page the **parent** rows (each parent keeps all of its children) instead of truncating on the multiplied join rows.  If you avoided combining `.include()` of a many-relation with `.limit()`, that combination now works.

---

## If You Use Postgres

Postgres connections now work whether you set `dialect` to `postgres` or `postgresql` (the `postgres` alias is normalized automatically).  No config change is required, but `postgresql` is the canonical value.

```python
# Both of these now work identically
'dialect': env('DB_WIKI_DIALECT', 'postgresql'),
```

---

!!! tip "Upgrade tips"
    - **Delete `update_forward_refs()`** from every model, keep `from __future__ import annotations`
      and the bottom-of-file relation imports.
    - **Add `= None`** to optional fields in your own `BaseModel` classes (ORM models are handled
      for you).
    - **Swap `on_event`** for `Startup.listen()` / `Shutdown.listen()`.
    - **Port** `@validator` → `@field_validator`, `class Config` → `model_config`, and
      `.dict()`/`.json()` → `.model_dump()`/`.model_dump_json()`.
    - Re-check any test that asserts exact JSON or OpenAPI output, v2 + OpenAPI 3.1 shift the shape.
    - **Swap `uvicore.ioc.make('aiohttp')`** for `make('httpx')`, await requests directly (no
      `async with`), and use `r.status_code` / `r.text` / `r.json()` (not awaited).
