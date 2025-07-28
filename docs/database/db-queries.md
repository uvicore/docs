# DB Query Builder

Uvicore provides [3 Layers](/database/#the-3-layers) of database access.  Here we discuss Uvicore's own custom Database Query Builder!

Generally the [ORM](/database/orm-basics/) is the best way to utilize and query your tables.  But if you decide an ORM is to abstract, this simple query builder may be for you.

If you find Uvicore's query builder to be too limiting you can dive straight into the power of [SQLAlchemy's Query Builder](/database/db-sa-queries/) instead.

!!! note
    A prerequisite to using Uvicore's Query Builder is to define your [DB Tables](/database/db-tables/).  If you prefer zero table definitions, then [SQLAlchemy RAW SQL](/database/db-sa-raw/) may be for you!


---

## :material-pound: Results

Results are returned as either a `List[Row]`, an empty List `[]`, single `Row` or as `None`.

See [sqlalchemy.engine.Row](https://docs.sqlalchemy.org/en/20/core/connections.html#sqlalchemy.engine.Row) for the `Row` object which acts much like a Python named tuple.

Using `.find(123)` and record ID 123 exists

```python
post = await uvicore.db.query().table('posts').find(123)
dd(post, type(post))

(123, 'test-post1', 'Test Post1')
sqlalchemy.engine.row.Row  # class
```

Using `.find(999)` and record ID 999 does NOT exist

```python
post = await uvicore.db.query().table('posts').find(999)
dd(post, type(post))

None
type(None)
```

Using `.get()` and records exist

```python
posts = await uvicore.db.query().table('posts').get()
dd(posts, type(posts))

[
    (1, 'test-post1', 'Test Post1'),
    (2, 'test-post2', 'Test Post2'),
    (3, 'test-post3', 'Test Post3')

]
list
```

Using `.get()` and records do not exist

```python
posts = await uvicore.db.query().table('posts').where('id', '>', 999).get()
dd(posts, type(posts))

[]
list
```


---


## :material-pound: Operators

The `.where()` and `or_where()` clauses accept the following operators

- `=` and `==` are interchangeable and mean equals
- `!=` not equal
- `>` greater than
- `>=` greater than or equal to
- `<` less than
- `like` contains
- `!like` does not contain
- `in` SQL IN statement
- `!in` SQL NOT IN statement


---


## :material-pound: Specifying a Connection

The `default` database connection defined in env `DATABASE_DEFAULT` is used if no alternate is provided.  Use the CLI `./uvicore db connections` to see a list of all connections.

Use the `default` connection

```python
posts = await uvicore.db.query().table('posts').get()
```

Specify the `wiki` DB connection explicitly

```python
posts = await uvicore.db.query('wiki').table('posts').get()
```


---


## :material-pound: Strings vs Actual Table Properties

The query builder allow you to use `strings` for all tables, select columns, wheres, order bys etc...

Strings are great because you don't need to import the actual table to get the table object and columns.  However using SQLAlchemy table and column objects may provide better code intellisense.

String Example

```python
results = (await uvicore.db.query('app1')
    .table('posts')
    .where('id', '>', 2)
    .order_by('title', 'DESC')
    .get()
)
```

SQLAlchemy Table object properties and columns

```python
from app1.database.tables.posts import Posts
post = Posts.table.c

results = (await uvicore.db.query('app1')
    .table(Posts.table)
    .where(post.id, '>', 2)
    .order_by(post.title, 'DESC')
    .get()
)
```

You can also use SQLAlchemy expressions in wheres and other clauses

```python
from app1.database.tables.posts import Posts
post = Posts.table.c

results = (await uvicore.db.query('app1')
    .table(Posts.table)
    .where(post.id > 2)  # Notice an actual comparison instead of 3 parameters
    .order_by(post.title, 'DESC')
    .get()
)

# Example count distinct column
count = (await uvicore.db.query().table('app1')
    .select(sa.func.count(sa.distinct(post.creator_id)))
    .where('creator_id', 1)
    .scalar()
)

```


---


## :material-pound: .get() / .all() / .fetchall()

The `.get()`, `.all()` and `.fetchall()` methods are used to get one or more records.

**Returns a `List[Row]` or an empty List `[]` if no results found.**

Selecting all columns

```python
posts = (await uvicore.db.query()
    .table('posts')
    .get()  # or .all() or .fetchall()
)
```

Selecting specific columns

```python
posts = (await uvicore.db.query()
    .table('posts')
    .select('id', 'title')
    .get()
)
```


---


## :material-pound: .count()

Count rows that would be returned from a query

```python

# Ex: select count(*) from posts where creator_id = 1
count = await uvicore.db.query().table('posts').where('creator_id', 1).count()

# Ex: select count(distinct creator_id) from posts where creator_id = 1
count = await uvicore.db.query().table('posts').select('creator_id').where('creator_id', 1).distinct().count()

# Ex: select count(distinct creator_id) from posts where creator_id = 1
# But using raw sa.func
from app1.database.tables.posts import Posts
post = Posts.table.c
count = await uvicore.db.query().table('posts').select(sa.func.count(sa.distinct(post.creator_id))).where('creator_id', 1).scalar()
```


---


## :material-pound: .distinct()

Use `.distinct()` on any query to add distinctness to the results

```python
posts = (await uvicore.db.query()
    .table('posts')
    .select('creator_id')
    .distinct()
    .get()
)
```


---


## :material-pound: .find()

The `.find()` method is used to get a single record, generally by the PK, but accepts any other field.

**Returns either a single `Row` object, or `None` if not found.**

By the `pk` (primary key)

```python
post = (await uvicore.db.query('app1')
    .table('posts')
    .find(1)
)
```

By an alternate field on the table

```python
post = (await uvicore.db.query('app1')
    .table('posts')
    .find(unique_slug='test-post1')
)
```

When using `JOINS`, you can still use `.find()` by using the long double underscore nested table column

```python
# Using a join table alias
post = (await uvicore.db.query('app1')
    .table('posts')
    .join('auth.users', 'posts.creator_id', 'auth.users.id', alias='creator')
    .find(creator__id=2)
)

# Without a join alias
post = (await uvicore.db.query('app1')
    .table('posts')
    .join('auth.users', 'posts.creator_id', 'auth.users.id')
    .find(users__id=2) # or auth__users__id
)
```


---


## :material-pound: .first() / .fetchone()

The `.first()` and `.fetchone()` methods are used to get ONE record, the first/top record from the query results.

**Returns `None` if no records found.**

```python
posts = (await uvicore.db.query()
    .table('posts')
    .order_by('id', 'desc')
    .first()  # or .fetchone()
)
```


---


## :material-pound: .one()

The `.one()` method is used to get one record from query or an `Exception` if not found.

**Throws an Exception if no data found or querying more than one record.**

If ID 4 exists, returns result.  If ID 4 does not exist, throws `Exception: No row was found when one was required`
```python
posts = (await uvicore.db.query()
    .table('posts')
    .where('id', '=', 4)
    .one()
)
```


---


### :material-pound: :material-pound: .one_or_none()

The `.one_or_none()` method is used to get one record from query or `None` if nothing found.

**Returns None if no record found or Throws Exception if querying more than one record.**


```python
posts = (await uvicore.db.query()
    .table('posts')
    .where('id', '=', 999)
    .one_or_none()
)
```


---


## :material-pound: .scalars()

The `.scalars()` (plural) method is used to get one column from ALL rows in results.

**Returns empty List `[]` if no records found. If selecting multiple columns, returns List of FIRST column only.**

```python
posts = (await uvicore.db.query()
    .table('posts')
    .select('title')
    .where('id', '>', 2)
    .scalars()
)
```


---


### :material-pound: :material-pound: .scalar()

The `.scalar()` method is used to get one column from one row.

**Returns None if no record found.  Returns first column from first row if more than one record found.**

```python
posts = (await uvicore.db.query()
    .table('posts')
    .select('id')
    .where('id', '=', 1)
    .scalar()
)
```


---


### :material-pound: :material-pound: .scalar_one()

The `.scalar_one()` method is used to get one column from one row or an `Exception` if not found.

**Throws an Exception if no data found or querying more than one record.**

```python
posts = (await uvicore.db.query()
    .table('posts')
    .select('title')
    .where('id', '=', 1)
    .scalar_one()
)
```


---


### :material-pound: :material-pound: .scalar_one_or_none()

The `.scalar_one_or_none()` method is used to get one column from one row or `None` if nothing found.

**Returns None if no record found or Throws Exception if querying more than one record**

```python
posts = (await uvicore.db.query()
    .table('posts')
    .select('title')
    .where('id', '=', 1)
    .scalar_one_or_none()
)
```


---


## :material-pound: .where()

The default chained `.where()` clauses are AND statements.

The `.where()` method takes 2 or 3 arguments.  If 2 arguments, the default `=` (equals) operator is assumed.  If 3 arguments, then you specify the operator as the 2ND parameter.

Assumed default `=` operator

```python
posts = (await uvicore.db.query('app1')
    .table('posts')
    .where('id', 1)
    .get()
)
```

Define the operator as 2ND parameter

```python
posts = (await uvicore.db.query('app1')
    .table('posts')
    .where('id', '>', 2)
    .get()
)
```

Multiple `.where()` as chainables

```python
posts = (await uvicore.db.query('app1')
    .table('posts')
    .where('id', '>', 2)
    .where('creator_id', 2)
    .get()
)
```

Multiple `.where()` as `List[Tuple]`

```python
posts = (await uvicore.db.query('app1')
    .table('posts')
    .where([
        ('id', '>', 2),
        ('creator_id', 2)
    ])
    .get()
)
```


### :material-pound: :material-pound: Where NULL

Where NULL

```python
# Using None
posts = (await uvicore.db.query('app1')
    .table('posts')
    .where('other', None)
    .get()
)

# Using 'null' as a case insensitive string (null or NULL)
posts = (await uvicore.db.query('app1')
    .table('posts')
    .where('other', 'null')
    .get()
)
```

Where NOT NULL

```python
# Using None
posts = (await uvicore.db.query('app1')
    .table('posts')
    .where('other', '!=', None)
    .get()
)

# Using 'null' as a case insensitive string (null or NULL)
posts = (await uvicore.db.query('app1')
    .table('posts')
    .where('other', '!=', 'null')
    .get()
)
```

### :material-pound: :material-pound: Where IN

Where IN

```python
posts = (await uvicore.db.query('app1')
    .table('posts')
    .where('id', 'in', [1, 2])
    .get()
)
```

Where NOT IN
```python
posts = (await uvicore.db.query('app1')
    .table('posts')
    .where('id', '!in', [1, 2])
    .get()
)
```

### :material-pound: :material-pound: Where Like

Where Like

```python
posts = (await uvicore.db.query('app1')
    .table('posts')
    .where('body', 'like', '%red%')
    .get()
)
```

Where NOT Like
```python
posts = (await uvicore.db.query('app1')
    .table('posts')
    .where('body', '!like', '%red%')
    .get()
)
```



---


## :material-pound: .where_or()

FIXME

