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


# Resolve forward-referenced relation types
from acme.wiki.models.comment import Comment   # isort:skip
Post.update_forward_refs()
```

!!! note
    The model field name does **not** have to match the table column name.  Above, the model field `slug` maps to the table column `unique_slug` (the first argument of `Field()`).  This is the "column mapper" concept, your model is the entity your API exposes, not a raw dump of the table.

!!! warning
    When a relation references a type that isn't imported yet (a forward reference), import it at the bottom of the file and call `Model.update_forward_refs()`.  This sidesteps circular imports between related models.

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
