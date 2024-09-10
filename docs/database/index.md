---
# DOC STATUS
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
title: Database & ORM
---

# Database & ORM

Uvicore comes with an all new custom ORM on top of SQLAlchemy Core query builder. Although the ORM abstracts the database tables at a higher level, the tables are still well defined and separate from your ORM models.

---


## :material-pound:  The 3 Layers

Uvicore uses SQLAlchemy Core to talk to many types of relational databases.  Uvicore does NOT use the SQLAlchemy ORM and instead chose to build a complete custom ORM from scratch.

Uvicore has 3 levels of database access.

1. The lowest level is the Dbal itself which is abstracted by SQLAlchemy Core
    - For example `aiomysql` or `aiopg/psycopg2`.
    - You generally won't ever interact with this layer.
2. Database Query Builder (from SQLAlchemy Core) which sits atop the Dbal.
3. Uvicore's own ORM which is an "entity" level abstraction on top of the DB level query builder.

Uvicore allows you to use either the DB Query Builder and/or the ORM for your projects.  The choice is yours!

---


## :material-pound: Tables vs ORM Models

Unlike some frameworks, Uvicore creates a well defined distinction between tables and models.

**Tables**

The table is the exact SQLAlchemy table, the same table you see in MySQL/Postgres.  The table can be directly queried using Uvicore's [DB Query Builder](/database/db-queries/).

A table is required to use the [DB Query Builder](/database/db-queries/) and is also required if you want to use Models with the ORM.  The ORM and Models however are options.


**ORM Models**

The model (also known as an "entity") is a higher level abstraction on the table which may have slightly different column names (understore vs camelCase) and may contain additional "computed" columns along with helper methods to interact with and query your entity.

Using the ORM is optional but provides a great Object Relational Mapping abstraction on top of your tables for developer simplicity.

---


## :material-pound: Query Builder vs ORM

:material-auto-fix: FIXME

