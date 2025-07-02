# SQLAlchemy RAW SQL

Uvicore provides [3 Layers](/database/#the-3-layers) of database access.  Here we discuss forgoing the [Uvicore ORM](/database/orm-basics/) and the [Uvicore Query Builder](/database/db-queries/) and we even skip [SQLAlchemy Query Builder](/database/db-sa-queries/) and go straight for RAW parameterized SQL

Generally the [ORM](/database/orm-basics/) is the best way to utilize and query your tables.  And if you prefer to skip the ORM, give the [Uvicore Query Builder](/database/db-queries/) a shot.  It's simple and elegant.

However, if you need ultimate RAW SQL power, keep reading!


---


## :material-pound: Why RAW SQL?

Sometimes, query performance is paramount and the queries are so incredibly complex that nothing but plain old RAW SQL will do. SQLAlchemy allows you to write raw SQL and even parameterize all inputs for safety!

When using RAW SQL, you don't even need to build SQLAlchemy [table definitions](/database/db-tables/). You can start querying your database right away without the need for any other boilerplate.


See [ORM vs Query Builder vs RAW SQL](/database/#orm-vs-query-builder-vs-raw) for more comparisons.



---


## :material-pound: Query without Table Definitions

Predefined SQLAlchemy [table definitions](/database/db-tables/) are OPTIONAL when using RAW SQL.  They do however provide a more convenient way to run the RAW SQL, but are in no way required!


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





## :material-pound: Select


...




Can also use `fetchone()` and `execute()` for INSERTS, UPDATES and DELETES
