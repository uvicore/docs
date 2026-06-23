---
title: ORM Model
---

# ORM Model

A model is the heart of the [Uvicore ORM](orm-basics.md), the rich Python class that maps to one of your [database tables](db-tables.md) and represents a single entity in your application.  This page is the detailed reference for defining one: the model class itself, the `Field()` options, and the relation types.  For the bigger-picture introduction (querying, saving, hooks), start with [ORM Basics](orm-basics.md).

---

## Anatomy of a Model

A model is a class decorated with `@uvicore.model()` that inherits from `Model` and uses the `ModelMetaclass`.  It links to its table via `__tableclass__`, and declares each field with a `Field()` and a Python type hint.

```python
from __future__ import annotations
from typing import Optional, List

import uvicore
from uvicore.orm import Model, ModelMetaclass, Field, BelongsTo, HasMany
from acme.wiki.database.tables import posts as table


@uvicore.model()
class Post(Model['Post'], metaclass=ModelMetaclass):
    """Wiki Posts"""

    # Link this model to its database table
    __tableclass__ = table.Posts

    id: Optional[int] = Field('id', primary=True, read_only=True)
    slug: str = Field('unique_slug', description='URL friendly title', max_length=100)
    title: str = Field('title')
    creator_id: int = Field('creator_id')

    # Relations (see below)
    creator: Optional[User] = Field(None, relation=BelongsTo('uvicore.auth.models.user.User'))
    comments: Optional[List[Comment]] = Field(None,
        relation=HasMany('acme.wiki.models.comment.Comment', foreign_key='post_id'))


# Import forward-referenced relation types at the bottom of the file
from acme.wiki.models.comment import Comment   # isort:skip
```

!!! note
    The model field name does **not** have to match the table column name.  Above, the model field `slug` maps to the table column `unique_slug` (the first argument of `Field()`).  This is the "column mapper" concept, your model is the entity your API exposes, not a raw dump of the table.

!!! warning
    When a relation references a type that isn't imported yet (a forward reference), import it at the **bottom** of the file (and keep `from __future__ import annotations` at the top).  This sidesteps circular imports between related models.  You do **not** need to call `Model.update_forward_refs()` / `Model.model_rebuild()` — as of 0.4 (Pydantic v2) Uvicore rebuilds every registered model **centrally at boot**.

---

## The `Field()` Options

The first positional argument is the database **column name** (or `None` for a pure relation or computed field).  The rest are keyword options.

| Option | Description |
|--------|-------------|
| `primary` | Marks the primary key field |
| `description` | Field description, shown in the [OpenAPI](../http/api/openapi.md) schema |
| `default` | Default value |
| `read_only` | Excluded from inserts/updates, marked `readOnly` in OpenAPI (great for auto-increment ids and timestamps) |
| `write_only` | Excluded from query results, marked `writeOnly` in OpenAPI (great for passwords) |
| `sortable` / `searchable` | Hints for the automatic [Model Router](../http/api/model-router.md) |
| `callback` | Method name to compute the field's value when the model is built |
| `evaluate` | A function applied to the row value when mapping a DB row into the model |
| `relation` | A relation object, see below |
| `min_length` / `max_length` | Validation + schema constraints |
| `example` | Example value for the OpenAPI docs |
| `properties` | Extra raw properties merged into the field's schema |

```python
id: Optional[int] = Field('id', primary=True, read_only=True)
password: str     = Field('password', write_only=True)
slug: str         = Field('unique_slug', max_length=100, example='my-first-post')
```

See [Pydantic](orm-pydantic.md) for how these options shape validation and the OpenAPI schema.

---

## Computed / Virtual Fields

Because a model is the *entity* your application exposes, and not a raw dump of table columns, it can carry fields that **don't exist on the table at all**.  These **computed** (or **virtual**) fields are declared with a `Field()` whose column name is `None`, and they derive their value from the other fields or from the incoming database row.  They serialize into your API responses and OpenAPI schema just like a normal column.

There are two flavors, distinguished by *when* they run: `callback` runs **after** the model is built (so it sees `self`), while `evaluate` runs **before** (so it only sees the raw row).

### `callback` — computed after the model is built

A `callback` names a method on the model that runs **after** the model has been instantiated, so it has full access to `self`, every other field, relations included.  Think of it as a computed property that is materialized onto the model.

A common example is a `full_name` assembled from separate `first_name` and `last_name` columns:

```python
@uvicore.model()
class User(Model['User'], metaclass=ModelMetaclass):
    """Wiki Users"""
    __tableclass__ = table.Users

    id: Optional[int] = Field('id', primary=True, read_only=True)
    first_name: str = Field('first_name')
    last_name: str = Field('last_name')

    # Computed field — column name is None, so it maps to no database column
    full_name: Optional[str] = Field(None,
        callback='compute_full_name',
        description='First and last name combined',
    )

    def compute_full_name(self):
        return f'{self.first_name} {self.last_name}'
```

Every `User` you query or build now exposes `user.full_name` even though there is no `full_name` column, and it shows up in the JSON response and OpenAPI schema.  Because the callback runs *after* instantiation, it can read any field on the model, including eager-loaded relations (for example, summing the totals of a `HasMany` to expose an `order_count`).

!!! note
    A `callback` field has no underlying column, so it is read-only by nature, it is computed on the way out and never written back to the database on `.save()`.

### `evaluate` — transform the row before the model is built

An `evaluate` function runs **before** the model is instantiated, while the raw database row (a dict) is being mapped into the model.  It receives the row and returns the value for that field, so use it to reshape, cast or extract a value as it comes out of the database (it has the row, but no `self`).

```python
# Pull a nested value out of a JSON column, with a fallback
name: Optional[str] = Field(None,
    evaluate=lambda row: row['data']['name'] if 'data' in row else row['name']
)

# A standalone function instead of a lambda
def decode_status(row):
    return 'active' if row['status'] == 1 else 'inactive'

status: Optional[str] = Field(None, evaluate=decode_status)

# A function that also takes extra parameters, pass a (func, *args) tuple
flag: Optional[str] = Field(None, evaluate=(decode_status, 'Data'))
```

!!! tip
    Reach for `evaluate` when the value depends only on the **raw row** (casting, extracting from a JSON blob, choosing between columns).  Reach for `callback` when the value depends on the **finished model**, other computed fields, or eager-loaded relations.

---

## Relations

Relations are declared as a `Field(None, relation=...)`.  The first argument to every relation is the **import path** of the related model.  Import the relation types from `uvicore.orm`.

```python
from uvicore.orm import (
    BelongsTo, HasOne, HasMany, BelongsToMany,
    MorphOne, MorphMany, MorphToMany,
)
```

| Relation | Constructor | Foreign key lives on |
|----------|-------------|----------------------|
| `BelongsTo` | `BelongsTo(model, foreign_key='id', local_key='{field}_id')` | **this** table |
| `HasOne` | `HasOne(model, foreign_key=...)` | the **related** table |
| `HasMany` | `HasMany(model, foreign_key=...)` | the **related** table |
| `BelongsToMany` | `BelongsToMany(model, join_tablename=..., left_key=..., right_key=...)` | a pivot table |
| `MorphOne` | `MorphOne(model, polyfix='imageable')` | the related (polymorphic) table |
| `MorphMany` | `MorphMany(model, polyfix='attributable')` | the related (polymorphic) table |
| `MorphToMany` | `MorphToMany(model, join_tablename=..., polyfix=..., right_key=...)` | a polymorphic pivot table |

```python
# One Post BelongsTo one creator (creator_id FK is on the posts table)
creator: Optional[User] = Field(None, relation=BelongsTo('uvicore.auth.models.user.User'))

# One Post HasMany comments (post_id FK is on the comments table)
comments: Optional[List[Comment]] = Field(None,
    relation=HasMany('acme.wiki.models.comment.Comment', foreign_key='post_id'))

# Many-To-Many via a pivot table
tags: Optional[List[Tag]] = Field(None,
    relation=BelongsToMany('acme.wiki.models.tag.Tag',
                           join_tablename='post_tags', left_key='post_id', right_key='tag_id'))

# Polymorphic one-to-many
attributes: Optional[Dict] = Field(None,
    relation=MorphMany('acme.wiki.models.attribute.Attribute', polyfix='attributable',
                       dict_key='key', dict_value='value'))
```

Eager-load relations with [`.include()`](orm-querybuilder.md#include-relations), and manage them with `.create()`, `.add()`, `.set()`, `.link()`, `.unlink()` and `.delete()` (see [ORM Basics](orm-basics.md#saving)).

### How `local_key` and `foreign_key` are derived

Every non-pivot relation joins on two columns, and the JOIN is always:

```
this_table.local_key  =  related_table.foreign_key
```

- **`local_key`** is the column on **this** model's table (the model you're declaring the relation *on*).
- **`foreign_key`** is the column on the **related** model's table.

In the examples above both keys are *omitted* on `BelongsTo` and `local_key` is omitted on `HasMany`.  That's perfectly fine — Uvicore **derives** the missing key for you so the common case stays terse.  The derivation rules differ per relation type:

| Relation | `local_key` (this table) | `foreign_key` (related table) |
|----------|--------------------------|-------------------------------|
| `BelongsTo` | derives to `'{field_name}_id'` | derives to `'id'` |
| `HasOne` | derives to `'id'` | **required** — you must pass it |
| `HasMany` | derives to `'id'` | **required** — you must pass it |
| `MorphOne` / `MorphMany` | derives to `'id'` | derives to `'{polyfix}_id'` |

`{field_name}` is the name of the relation field itself (e.g. the `creator` field derives `creator_id`).  `HasOne`/`HasMany` cannot derive `foreign_key` — they don't know this model's name — so it is a required argument; only `local_key` is optional for them.

The examples below are written **fully explicit** so you can see exactly what the terse versions resolve to.  Each pair is equivalent:

```python
# BelongsTo — terse (both keys derived):
creator: Optional[User] = Field(None, relation=BelongsTo('uvicore.auth.models.user.User'))
# BelongsTo — explicit equivalent (join: posts.creator_id = users.id):
creator: Optional[User] = Field(None,
    relation=BelongsTo('uvicore.auth.models.user.User', local_key='creator_id', foreign_key='id'))

# HasMany — terse (local_key derived):
comments: Optional[List[Comment]] = Field(None,
    relation=HasMany('acme.wiki.models.comment.Comment', foreign_key='post_id'))
# HasMany — explicit equivalent (join: posts.id = comments.post_id):
comments: Optional[List[Comment]] = Field(None,
    relation=HasMany('acme.wiki.models.comment.Comment', foreign_key='post_id', local_key='id'))
```

Pass the keys explicitly whenever your columns don't match the derived names — for example a `BelongsTo` whose FK column is `author_id` rather than `{field_name}_id`, or a self-referential relation:

```python
# A 'parent' BelongsTo on the same table, FK column is parent_id (matches default), PK is id:
parent: Optional[Post] = Field(None,
    relation=BelongsTo('acme.wiki.models.post.Post', local_key='parent_id', foreign_key='id'))

# A BelongsTo whose FK column name does NOT match the field name (field 'owner', column 'user_id'):
owner: Optional[User] = Field(None,
    relation=BelongsTo('uvicore.auth.models.user.User', local_key='user_id', foreign_key='id'))
```

!!! tip "Composite (multi-column) keys"
    `foreign_key` and `local_key` accept an **ordered list** of columns as well as a single
    string, producing a multi-column JOIN `ON` clause (e.g. `foreign_key=['tenant_id', 'workspace_id', 'post_id']`).
    The two lists are **positional** and must be the same length (`local_key[i]` pairs with
    `foreign_key[i]`, `AND`-ed in declared order); composite keys are **not** derived, so list every
    column explicitly on both sides.  This is needed for sharded backends (Vitess / PlanetScale)
    that must join on the shard key — list it first.
    See [Composite Relation Keys](orm-querybuilder.md#composite-multi-column-relation-keys) for full details.

!!! tip
    `*Many` relations (`HasMany`, `BelongsToMany`, `MorphMany`, `MorphToMany`) accept `dict_key`, `dict_value` and `list_value` to shape the output as a dict or a flat list instead of a list of full model objects.  When you set `dict_key`, type the field as `Optional[Dict]`; otherwise type it `Optional[List[RelatedModel]]`.

---

## OpenAPI Example Override

The OpenAPI docs auto-generate an example for request and response bodies from your model schema.  Override it by leaning on the [Pydantic](orm-pydantic.md) `Config` class.

```python
@uvicore.model()
class Post(Model['Post'], metaclass=ModelMetaclass):
    """Wiki Posts"""

    class Config:
        schema_extra = {
            "example": {
                "id": 1,
                "slug": "title-as-a-slug",
                # ...
            },
        }
    # ...
```

---

## Tables

Most ORM models have a corresponding database table.  You can attach one in three ways: point `__tableclass__` at a [Table](db-tables.md) class in a separate file, define that `Table` class in the same file as the model, or define the schema [fully inline](db-tables.md#tables-inline-on-the-model) on the model with `__connection__` + `__tablename__` + a raw `__table__` column list.  See [Database Tables](db-tables.md) for all three styles.

---

## Tableless Models

A model does **not** require a database table.  Perhaps you're building an API passthrough with a custom schema, wrapping a remote service, or shaping data that never touches your database.  Simply omit `__tableclass__` and declare your fields.  You won't be able to run database queries against such a model, but it still works beautifully as a Pydantic schema for your [API](../http/api/routing.md) request and response bodies.

```python
@uvicore.model()
class Forecast(Model['Forecast'], metaclass=ModelMetaclass):
    """A weather forecast assembled from a remote API (no database table)."""
    city: str = Field('city')
    temperature: float = Field('temperature')
    summary: str = Field('summary')
```
