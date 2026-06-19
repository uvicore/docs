# Database & ORM

Uvicore comes with its own custom [DB query builder](db-queries.md) (table layer) and [ORM](orm-basics.md) (object layer) which are built on top of [SQLAlchemy Core](https://docs.sqlalchemy.org/en/20/core/).  Therefore you have 3 layers available to you!

If you need more database access than SQLAlchemy provides, `pip install` whatever you need!

!!! note
    SQLAlchemy ORM is NOT included with Uvicore and Uvicore models are not SQLAlchemy models but a mix of Uvicore ORM plus [Pydantic](orm-pydantic.md) models which fit perfectly into Uvicore's OpenAPI schema and validators!


---


##  The 3 Layers

Uvicore provides 3 layers of database access.

1. The [SQLAlchemy Core](https://docs.sqlalchemy.org/en/20/core/) query builder (not their ORM)
2. Uvicore's own custom [Database query builder](db-queries.md)
3. Uvicore's own custom [Object Relational Mapper](orm-basics.md)

**Recommended** - Uvicore [ORM](orm-basics.md) and models are the easiest and most integrated way to use the database. If using APIs or desire an object mapper with full column entity mapping, use Uvicore's [ORM](orm-basics.md)!

If you want to forgo the [ORM](orm-basics.md) and API integrations and prefer the raw performance of SQL without object mapping, then use Uvicore's simple query builder.  This builder is simple and elegant but does not yet facilitate every type of complex nested query.

If you need ultra complex queries, then perhaps SQLAlchemy core's query builder is right for you.  You can also write RAW SQL (no query builder) using SQLAlchemy Core which supports full query parameterization.

!!! note
    Uvicore uses SQLAlchemy 2.0 for fully async queries which are ideal for this fully async full stack framework!

---


## Tables vs ORM Models

Unlike some frameworks, Uvicore creates a well defined distinction between tables and models.

**Tables**

The table is the exact SQLAlchemy table, the same table you see in MySQL/Postgres.  The table can be directly queried using Uvicore's [DB Query Builder](db-queries.md).

A table is required to use the [DB Query Builder](db-queries.md) and is also required if you want to use Models with the ORM.  The ORM and Models however are optional.


**ORM Models**

The model (also known as an "entity") is a higher level abstraction on the table which may have slightly different column names (understore vs camelCase) and may contain additional "computed or virtual" columns along with helper methods to interact with and query your entity.

Using the [ORM](orm-basics.md) is optional but provides a great Object Relational Mapping abstraction on top of your tables for developer simplicity.  Uvicore models integrate seamlessly into automatic Pydantic models for OpenAPI schemas and validations!

---


## ORM vs Query Builder vs RAW

**ORM**

The Uvicore [ORM](orm-basics.md) models provide an abstraction on top of your database.  Not only are the query results represented as Lists of nested Python classes but also allow your model schema to look different than the table schema.  While your tables may prefer the `lowercase_underscore` naming convention, your models may enjoy the `camelCase` or `PascalCase` convention.  Most ORM's don't provide this "column mapper" concept, but Uvicore does!  Your table may have 20 columns, while your model (and therefore your OpenAPI results) may only want 10 with slightly different names.  With mapping concept, you can think of models more like the actual entities represented by your APIs.  In fact, a model IS your API results, one and the same!

Uvicore's models also integrate directly with Pydantic which drives the OpenAPI schema and validations!  Contrast this to raw FastAPI where you must build your SQLAlchemy ORM models separately than your Pydantic models (2 files in one!)

**Query Builder**

The query builder is a class based chainable abstraction above RAW SQL.

```python
posts = (uvicore.db.query()
    .table('posts')
    .where('body', 'like', 'uvicore is awesome')
    .order_by('id')
    .get()
)
```

This not only allows clean parameterization of paramaters, but also lets you slowly build the query based on a series of conditionals (no RAQ SQL string concatenation!).

The query builder however does not map or morph your tables columns like an [ORM](orm-basics.md) would.  This is a directly query and representation of your actual tables.  Results are returned as rows and columns like any SQL result, not fully nested Class objects like an ORM.

**RAW SQL**

Sometimes, query performance is paramount and the queries are so incredibly complex that nothing but plain old RAW SQL will do.  SQLAlchemy allows you to write raw SQL and even parameterize all inputs for safety!  The query results are identical to the query builder above, just rows and columns from the query itself, no object mapping or hierarchical representations.

When using RAW SQL, you don't technically even need to build SQLAlchemy table classes.  You can start querying your database right away without the need for any other boilerplate.

