# SQLAlchemy RAW SQL

Uvicore provides [3 Layers](index.md#the-3-layers) of database access.  Here we discuss forgoing the [Uvicore ORM](orm-basics.md) and the [Uvicore Query Builder](db-queries.md) and we even skip [SQLAlchemy Query Builder](db-sa-queries.md) and go straight for RAW parameterized SQL

Generally the [ORM](orm-basics.md) is the best way to utilize and query your tables.  And if you prefer to skip the ORM, give the [Uvicore Query Builder](db-queries.md) a shot.  It's simple and elegant.

However, if you need ultimate RAW SQL power, keep reading!


---


## Why RAW SQL?

Sometimes, query performance is paramount and the queries are so incredibly complex that nothing but plain old RAW SQL will do. SQLAlchemy allows you to write raw SQL and even parameterize all inputs for safety!

When using RAW SQL, you don't even need to build SQLAlchemy [table definitions](db-tables.md). You can start querying your database right away without the need for any other boilerplate.


See [ORM vs Query Builder vs RAW SQL](index.md#orm-vs-query-builder-vs-raw) for more comparisons.



---


## Query without Table Definitions

Predefined SQLAlchemy [table definitions](db-tables.md) are OPTIONAL when using RAW SQL.  They do however provide a more convenient way to run the RAW SQL, but are in no way required!


You can query database tables without a pre-defined SQLAlchemy table definition.

```python
query = f"""SELECT
    *
FROM
    sometable
WHERE
    somekey1 = :key1
    AND somekey2 = :key2
"""
params = {
    'key1': 'parameterized value here',
    'key2': 'parameterized value here',
}
results = await uvicore.db.fetchall(query, params, connection='wiki')
```

An Update `.execute()` example

```python
query = "UPDATE posts SET title=:title WHERE id=:id"
await uvicore.db.execute(query, {
    'title': 'uvicore rocks',
    'id': 42
}, connection='wiki')

```





## Query with Table Definitions

If you *have* defined your [DB Tables](db-tables.md), you don't have to hardcode table names in your SQL.  Use `uvicore.db.tablename()` to get the proper, prefix-aware name and interpolate it into your query string.  Your parameterized **values** still go through the `:param` bindings, never string-concatenate user input into SQL.

```python
posts = uvicore.db.tablename('wiki.posts')

query = f"SELECT id, title FROM {posts} WHERE creator_id = :creator_id"
rows = await uvicore.db.fetchall(query, {'creator_id': 1}, connection='wiki')
```

---

## Execution Helpers

The same helpers used elsewhere in the database layer work with raw SQL.  Each accepts the SQL string (or a SQLAlchemy query object), an optional dict of parameters, and a `connection=` (or `metakey=`).

**Many rows**

| Method | Use for |
|--------|---------|
| `await uvicore.db.all(sql, params, connection=...)` | SELECT returning many rows.  Returns an empty list if none found |
| `await uvicore.db.fetchall(sql, params, connection=...)` | Alias to `.all()` |

**One row**

| Method | Use for |
|--------|---------|
| `await uvicore.db.first(sql, params, connection=...)` | SELECT returning the first row, or `None` if none found |
| `await uvicore.db.fetchone(sql, params, connection=...)` | Alias to `.first()` |
| `await uvicore.db.one(sql, params, connection=...)` | SELECT returning exactly one row.  Throws if zero rows or more than one row |
| `await uvicore.db.one_or_none(sql, params, connection=...)` | SELECT returning one row or `None`.  Throws if more than one row |

**Scalar values**

| Method | Use for |
|--------|---------|
| `await uvicore.db.scalars(sql, params, connection=...)` | Many scalar values (the first column of each row).  Returns an empty list if none found |
| `await uvicore.db.scalar(sql, params, connection=...)` | A single scalar value, or `None` if none found.  Returns the first if more than one |
| `await uvicore.db.scalar_one(sql, params, connection=...)` | Exactly one scalar value.  Throws if zero rows or more than one row |
| `await uvicore.db.scalar_one_or_none(sql, params, connection=...)` | One scalar value or `None`.  Throws if more than one row |

**Writes**

| Method | Use for |
|--------|---------|
| `await uvicore.db.execute(sql, params, connection=...)` | INSERT, UPDATE and DELETE.  Returns the SQLAlchemy `CursorResult` |
| `await uvicore.db.insertone(sql, params, connection=...)` | Insert one row, returning its primary key |
| `await uvicore.db.insertmany(sql, params, connection=...)` | Bulk insert many rows, returning the primary keys (on databases that support `INSERT..RETURNING`) |

```python
# A single scalar value
count = await uvicore.db.scalar(
    "SELECT COUNT(*) FROM posts WHERE creator_id = :id",
    {'id': 1},
    connection='wiki',
)

# An INSERT
await uvicore.db.execute(
    "INSERT INTO posts (slug, title, creator_id, owner_id) VALUES (:slug, :title, :cid, :oid)",
    {'slug': 'hello', 'title': 'Hello', 'cid': 1, 'oid': 1},
    connection='wiki',
)
```

!!! danger "Always parameterize"
    Never build SQL by concatenating untrusted values into the string.  Always pass them through the `:param` bindings as shown above, SQLAlchemy safely escapes them for you and protects against SQL injection.
