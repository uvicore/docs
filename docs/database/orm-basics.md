---
title: ORM Basics
---

# ORM Basics

The Uvicore ORM is an elegant, fully async Object Relational Mapper built on top of [SQLAlchemy Core](https://docs.sqlalchemy.org/en/20/core/) and [Pydantic](orm-pydantic.md).  It maps your database tables to expressive Python model classes, so query results come back as rich, nested objects instead of plain rows and columns.

Using the ORM is **optional**, you can always drop down to the [DB Query Builder](db-queries.md) or [raw SQL](db-sa-raw.md), but it is the easiest, most integrated and most powerful way to work with your data.  Because Uvicore models *are* Pydantic models, they double as your OpenAPI schemas and request validators with zero extra work.

---

## Introduction

A Uvicore model (also called an *entity*) is a higher-level abstraction over a [database table](db-tables.md).  Unlike most ORMs, a Uvicore model does not have to match its table one-to-one:

- Model fields can be **renamed** from their underlying columns (your table may use `lowercase_underscore` while your model enjoys `camelCase`).
- A model can expose **[computed or virtual](orm-model.md#computed-virtual-fields)** fields that don't exist on the table.
- A model can expose **only a subset** of the table's columns.
- A model carries **relations**, so a single query can eager-load deeply nested related objects.

In other words, a model represents the *entity* your application and API care about, not just a dump of table columns.  In fact, a model **is** your API result, one and the same.

!!! note
    Uvicore keeps a clear distinction between [Tables](db-tables.md) (the exact SQLAlchemy table) and ORM Models (the higher-level entity).  A table is required to use a model, but the model layer itself is optional.  See [Database & ORM](index.md) for the full picture of all three data-access layers.

---

## Defining a Model

A model is a class decorated with `@uvicore.model()` that inherits from `Model` and uses the `ModelMetaclass`.  Each field is declared with a `Field()` and a Python type hint.  The `__tableclass__` attribute links the model to its [table](db-tables.md).

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
    slug: str = Field('unique_slug', description='URL friendly title')   # field name != column name
    title: str = Field('title')
    body: str = Field('body')
    creator_id: int = Field('creator_id')

    # Relations
    creator: Optional[User] = Field(None, relation=BelongsTo('uvicore.auth.models.user.User'))
    comments: Optional[List[Comment]] = Field(None,
        relation=HasMany('acme.wiki.models.comment.Comment', foreign_key='post_id'))


# Import forward-referenced relation types at the bottom of the file
from acme.wiki.models.comment import Comment   # isort:skip
```

Generate a fresh model skeleton with the [schematic generator](../cli/built-in-commands.md):

```bash
./uvicore gen model post
```

See [ORM Model](orm-model.md) for the full anatomy of a model, field options and relations, and remember to register your models in your [Package Provider](../deeper/provider.md).

---

## Querying

Every model exposes a fluent, chainable, async query builder via `Model.query()`.

```python
from acme.wiki.models.post import Post

# All posts
posts = await Post.query().get()

# Find by primary key
post = await Post.query().find(1)

# Filter, eager-load relations, sort and paginate
posts = await (Post.query()
    .include('creator', 'comments')
    .where('title', 'like', '%uvicore%')
    .order_by('id', 'DESC')
    .limit(25)
    .get())
```

The full set of `where` operators, relation includes, filters and pagination is documented in the [ORM Query Builder](orm-querybuilder.md).

---

## Saving

Models read and write with the same elegant API.

```python
# Insert or update by primary key
post = Post(slug='hello', title='Hello', body='...', creator_id=1)
await post.save()

# Bulk insert
await Post.insert([{...}, {...}])

# Insert with nested relations in one call
await Post.insert_with_relations([{
    'slug': 'hello', 'title': 'Hello', 'body': '...', 'creator_id': 1,
    'comments': [{'title': 'Nice!', 'body': '...', 'creator_id': 2}],
}])

# Delete
await post.delete()
```

---

## Hooks

In your model, you can override these defs to run logic around the model's lifecycle.  Remember to `await super()` when overriding.

```python
# New records only, actual INSERTS
_before_insert(self)
_after_insert(self)

# Both insert or update, any save to the database
_before_save(self)
_after_save(self)

# Delete
_before_delete(self)
_after_delete(self)
```

```python
@uvicore.model()
class Post(Model['Post'], metaclass=ModelMetaclass):
    ...
    async def _before_save(self):
        await super()._before_save()
        self.slug = self.slug.lower()
```

## Events

The ORM hooks also fire named string based events to use anywhere else in the system.  The string is based on the model's FQN (fully qualified name).  For example if the model is `uvicore.auth.models.user.User` the event names would be

```
uvicore.orm-{uvicore.auth.models.user.User}-BeforeInsert
uvicore.orm-{uvicore.auth.models.user.User}-AfterInsert

uvicore.orm-{uvicore.auth.models.user.User}-BeforeSave
uvicore.orm-{uvicore.auth.models.user.User}-AfterSave

uvicore.orm-{uvicore.auth.models.user.User}-BeforeDelete
uvicore.orm-{uvicore.auth.models.user.User}-AfterDelete
```

This lets a *different* part of your app (or another package entirely) react to a model's lifecycle without modifying the model itself.  See [Events](../deeper/events/index.md) to learn how to listen.

!!! tip
    Use a model **hook** for logic that belongs to the model itself (normalizing a slug).  Use an **event listener** for cross-cutting reactions that live elsewhere (sending a notification when a `Post` is created).
