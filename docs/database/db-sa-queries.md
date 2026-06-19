---
title: SQLAlchemy Query Builder
---

# SQLAlchemy Query Builder

Uvicore provides [3 Layers](index.md#the-3-layers) of database access.  Here we discuss forgoing the [Uvicore ORM](orm-basics.md) and the [Uvicore Query Builder](db-queries.md) and jumping straight into SQLAlchemy's own Query Builder!

Generally the [ORM](orm-basics.md) is the best way to utilize and query your tables.  And if you prefer to skip the ORM, give the [Uvicore Query Builder](db-queries.md) a shot, it's simple and elegant.

However, if you need the ultimate SQLAlchemy power, keep reading!

!!! note
    A prerequisite to using SQLAlchemy's Query Builder is to define your [DB Tables](db-tables.md).  If you prefer zero table definitions, then [SQLAlchemy RAW SQL](db-sa-raw.md) may be for you!

---

## Getting the Table

To build a SQLAlchemy Core query you first need the `sa.Table` object.  Grab it from Uvicore with `uvicore.db.table()`, which returns the real, prefix-aware SQLAlchemy table for the given connection.  This is better than importing your `Table` class directly because it honors any table prefix configured for the connection.

```python
import uvicore
import sqlalchemy as sa

# Get the SQLAlchemy table for the 'wiki' connection
posts = uvicore.db.table('posts', 'wiki')

# Or using dotnotation (connection.table)
posts = uvicore.db.table('wiki.posts')
```

---

## Executing a Query

You build a query with SQLAlchemy Core, then run it through Uvicore's database manager.  The handy execution helpers are:

| Method | Returns |
|--------|---------|
| `await uvicore.db.fetchall(query, connection=...)` | a list of rows |
| `await uvicore.db.first(query, connection=...)` | the first row (or `None`) |
| `await uvicore.db.scalar(query, connection=...)` | the first column of the first row |
| `await uvicore.db.execute(query, connection=...)` | runs INSERT / UPDATE / DELETE |

All of these accept a `connection=` keyword to target a specific connection (it defaults to your configured default connection).

---

## Select

```python
import uvicore
import sqlalchemy as sa

posts = uvicore.db.table('wiki.posts')

# SELECT * FROM posts
query = sa.select(posts)
rows = await uvicore.db.fetchall(query, connection='wiki')

# Select specific columns
query = sa.select(posts.c.id, posts.c.title)
rows = await uvicore.db.fetchall(query, connection='wiki')
```

---

## Where

```python
posts = uvicore.db.table('wiki.posts')

query = (sa.select(posts)
    .where(posts.c.creator_id == 1)
    .where(posts.c.title.like('%uvicore%'))
    .order_by(posts.c.id)
)
rows = await uvicore.db.fetchall(query, connection='wiki')

# OR conditions
query = sa.select(posts).where(
    sa.or_(posts.c.id == 1, posts.c.id == 7)
)
rows = await uvicore.db.fetchall(query, connection='wiki')
```

---

## Joins

```python
posts = uvicore.db.table('wiki.posts')
users = uvicore.db.table('auth.users')

query = (sa.select(posts, users.c.email)
    .select_from(posts.join(users, posts.c.creator_id == users.c.id))
    .where(users.c.email.like('%example.com'))
)
rows = await uvicore.db.fetchall(query, connection='wiki')
```

---

## Aggregates, Group By and Order By

```python
posts = uvicore.db.table('wiki.posts')

# Count posts per creator
query = (sa.select(posts.c.creator_id, sa.func.count().label('total'))
    .group_by(posts.c.creator_id)
    .order_by(sa.desc('total'))
)
rows = await uvicore.db.fetchall(query, connection='wiki')

# A single scalar value
query = sa.select(sa.func.count()).select_from(posts)
total = await uvicore.db.scalar(query, connection='wiki')
```

---

## Insert, Update and Delete

Use `uvicore.db.execute()` for write operations.

```python
posts = uvicore.db.table('wiki.posts')

# Insert
await uvicore.db.execute(
    posts.insert().values(slug='hello', title='Hello', creator_id=1, owner_id=1),
    connection='wiki',
)

# Update
await uvicore.db.execute(
    posts.update().where(posts.c.id == 1).values(title='Updated'),
    connection='wiki',
)

# Delete
await uvicore.db.execute(
    posts.delete().where(posts.c.id == 1),
    connection='wiki',
)
```

!!! tip
    This is the full SQLAlchemy Core query builder, so anything in the [SQLAlchemy 2.0 docs](https://docs.sqlalchemy.org/en/20/core/) works here.  When even this isn't enough, drop all the way down to [RAW SQL](db-sa-raw.md).
