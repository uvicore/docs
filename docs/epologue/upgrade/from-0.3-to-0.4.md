# Upgrade 0.3 to 0.4

Good news, **0.4 is a non-breaking, additive release for application code.**  Your existing models, tables, query builders and configs continue to work unchanged.  This page simply highlights what you can now *adopt*, plus a couple of behavior improvements worth knowing about.

See the [0.4 Changelog](../changelog/0.4.md) for the full list.

---

## Nothing Required

There are no forced migration steps.  If you do nothing, your 0.3 app runs on 0.4 as-is.

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

## Behavior Improvements to Be Aware Of

These are bug fixes rather than breaking changes, but they alter behavior you may have worked around:

- **Multiple `*Many` includes.** Eager-loading several many-relations in one query (for example `.include('comments', 'tags')`) previously returned duplicated/cartesian rows.  Results are now correct.  If you had added manual de-duplication to compensate, you can remove it.
- **Auto-increment primary keys.** Inserts no longer send an explicit `NULL` primary key.  Behavior is unchanged on SQLite, and inserts that previously failed on Postgres/MySQL now succeed.
- **`find()` by primary key** coerces the value to the column's type, so passing a string id works on strict engines like Postgres.
- **`HasMany` `delete()` / `set()`** now work (they previously raised).

---

## If You Use Postgres

Postgres connections now work whether you set `dialect` to `postgres` or `postgresql` (the `postgres` alias is normalized automatically).  No config change is required, but `postgresql` is the canonical value.

```python
# Both of these now work identically
'dialect': env('DB_WIKI_DIALECT', 'postgresql'),
```
