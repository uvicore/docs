# ORM Query Builder

Examples use a Uvicore model called `User` and `Post`.

I also show the API URL parameters used in the automatic model router.


## Find One

Find one user by primary key of 1.  Returns a single User model instance, not a List.
```python
user = await User.query().find(1)
# URL: /users/1
```

Find one user by email.  Returns a single User model instance, not a List.  If this happens to return multiple results from the Database, TOP 1 is returned, never a List.
```python
user = await User.query().find(email='mreschke@example.com')
# URL: /users?where=["email","mreschke@example.com"]
```

!!! tip
    `.find()` ignores any `.where()`, `.or_where()`, `.order_by()`, `.key_by()` as those do not apply to finding a single record.





## Get All

Get all users.  Returns a List of User model instances.
```python
users = await User.query().get()
# URL: /users
```




## Include Relations

You can include child relations of any relational type by using `include()`

`include()` can take infinite parameters or a List
```python
# Infinite parameters
posts = await Post.query().include('creator', 'comments').get()
# URL:  /posts?include=creator,comments
# URL2: /posts?include=creator&include=comments

# As a List
posts = await Post.query().include(['creator', 'comments']).get()
# URL:  /posts?include=creator,comments
# URL2: /posts?include=creator&include=comments
```

You can include any number of deeply nested relations using dot notation.  Assume the posts `creator` links to the `User` model.  Further the `User` model has a `info` one-to-one.
```python
posts = await Post.query().include('creator.info', 'comments.creator', 'tags').get()
# URL:  /posts?include=creator.info,comments.creator,tags
# URL2: /posts?include=creator.info&include=comments.creator&include=tags
```

Most other query builder methods on relations use dot notation as well.
```python
posts = await (Post.query()
    .include('creator.info', 'comments.creator')
    .where('deleted', False)
    .where('creator.info.title', 'Master Gardner')
    .filter('comments.deleted', False)
    .sort('comments.created_at', 'DESC'),
    .order_by('created_at')
    .get()
)
```

!!! info
    All relations in a dot notation will be included, so `creator.info` includes both creator `User` and the `Info` of that creator.  No need to specify twice as `['creator', 'creator.info']`







## Composite (Multi-Column) Relation Keys

Every relation's `foreign_key` and `local_key` accept **either a single column name or an
ordered list of column names**.  When you pass lists, Uvicore builds a multi-column JOIN `ON`
clause, pairing the columns by position and `AND`-ing them together **in the order you declare
them**.

```python
from typing import List, Optional
from uvicore.orm import Model, ModelMetaclass, Field, BelongsTo, HasMany

class Post(Model['Post'], metaclass=ModelMetaclass):
    ...
    # One Post HasMany Comments, joined on THREE columns
    comments: Optional[List[Comment]] = Field(None,
        relation=HasMany('acme.wiki.models.comment.Comment',
            foreign_key=['tenant_id', 'workspace_id', 'post_id'],   # columns on comments
            local_key =['tenant_id', 'workspace_id', 'id'],         # columns on posts
        ),
    )

class Comment(Model['Comment'], metaclass=ModelMetaclass):
    ...
    # Inverse BelongsTo, same three columns
    post: Optional[Post] = Field(None,
        relation=BelongsTo('acme.wiki.models.post.Post',
            foreign_key=['tenant_id', 'workspace_id', 'id'],         # columns on posts
            local_key =['tenant_id', 'workspace_id', 'post_id'],     # columns on comments
        ),
    )
```

`await Post.query().include('comments').get()` then generates a multi-column join:

```sql
... FROM posts LEFT OUTER JOIN comments
      ON posts.tenant_id    = comments.tenant_id
     AND posts.workspace_id = comments.workspace_id
     AND posts.id           = comments.post_id
```

The lists are **positional**: `local_key[i]` is matched to `foreign_key[i]`, so both lists must
be the same length (a clear exception is raised otherwise).  A single-string key
(`foreign_key='post_id'`) keeps working exactly as before, it is simply a one-element composite.

Composite keys are honored **everywhere** the relation is used: eager-loading (`.include()`),
the inline join for `*One` relations (`BelongsTo` / `HasOne`), the secondary query for `*Many`
relations (`HasMany`), and the in-memory matching that stitches children back to their parents.

!!! info "Why composite keys?"
    Sharded / distributed databases like **Vitess / PlanetScale** route a query to a single
    shard using a **shard key** (vindex).  A join that omits the shard key forces a cross-shard
    scatter/gather, which is slow and is frequently rejected or times out.  Declaring the shard
    key columns (`tenant_id`, `workspace_id`) as the leading members of the relation key keeps the
    join on a single shard.  The columns are emitted in declared order, so list the shard key
    first.

!!! tip
    Which side each key column lives on (`foreign_key` vs `local_key`) follows the same rule as
    single keys, see the [relation reference](orm-model.md#relations).  `BelongsTo` keeps the
    foreign key on **this** table; `HasOne` / `HasMany` keep it on the **related** table.




## Where


!!! note "Operators"
    Operators are case-insensitive and whitespace tolerant.  The full set is:
    `=`, `==`, `!=`, `<>`, `>`, `>=`, `<`, `<=`, `in`, `!in` (or `not in`),
    `like`, `!like` (or `not like`), `ilike`, `!ilike` (or `not ilike`),
    `between` / `!between` (value is a `[low, high]` list), and `is` / `is not`.
    The string `'null'` (in quotes) is a valid *value* (not an operator), see the null example below.

    `like` is case-sensitive on some databases (Postgres) and case-insensitive on others (SQLite, MySQL).  Use `ilike` for portable case-insensitive matching.  See the [DB Query Builder operators](db-queries.md#operators) for the complete reference.

Get all users with eye_color blue.  Operator is assumed `=`.
```python
users = await User.query().where('eye_color', 'blue').get()
# URL: /users?where=["eye_color","blue"]
```

Explicit operator
2nd param is either the operator or the where value if operator is undefined.
```python
users = await User.query().where('eye_color', '=', 'blue').get()
# URL: /users?where=["eye_color","=","blue"]
```

Where In, Not In
```python
users = await User.query().where('eye_color', 'in', ['green', 'blue']).get()  # In
# URL: /users?where=["eye_color","in",["green", "blue"]]

users = await User.query().where('eye_color', '!in', ['green', 'blue']).get()  # Not in
# URL: /users?where=["eye_color","!in",["green", "blue"]]
```

Where Like, Not Like
```python
users = await User.query().where('eye_color', 'like', '%br%').get()  # Like
# URL: /users?where=["eye_color","like","%br%"]

users = await User.query().where('eye_color', '!like', '%br%').get()  # Not like
# URL: /users?where=["eye_color","!like","%br%"]
```

Where Null, Not Null
```python
users = await User.query().where('eye_color', 'null').get()  # Like
# URL: /users?where=["eye_color","null"]

users = await User.query().where('eye_color', '!=', 'null').get()  # Not like
# URL: /users?where=["eye_color","!=","null"]
```


### Where Multiples

There is a few ways to add multiple wheres.  You can either chain multiple `.where()` together, or use a single `.where()` with a `List of Tuples`.  The Tuple style accepts all the optional operators just like the normal `.where()`.

Multiple chains
```python
users = await User.query().where('eye_color', 'green').where('gender', '!=', 'male').get()
# URL: /users?where=[["eye_color","green"],["gender","!=","male"]]
```

List of Tuples
```python
users = await (User.query().where([
    ('eye_color', 'green'),
    ('gender', '!=', 'male'),
]).get()
# URL: /users?where=[["eye_color","green"],["gender","!=","male"]]
```



### Where OR

Where ORs are a bit limited at the moment.   The OR only works at the end of a where in the final SQL statement.  Meaning you cannot do complex (and (or) and (or)) order of operations

```python
users = await User.query().or_where([
    ('eye_color', 'green'),
    ('eye_color', '=', 'blue')
]).get()
# URL: /users?or_where=[["eye_color","green],["eye_color","=","blue"]]
# SQL: SELECT * FROM User WHERE eye_color='green' OR eye_color='blue'
```

The `or_where` can be combined with `where` and any other query builder method
```python
users = await (User.query()
    .where('gender', 'male')
    .where('hair_color', 'blonde')
    .or_where([
        ('eye_color', 'green'),
        ('eye_color', 'blue')
    ]
).get())
# URL: /users?where=[["gender","male"],["hair_color", "blonde"]]&or_where=[["eye_color","green"],["eye_color","blue"]]
# SQL: SELECT * FROM User WHERE gender='male' AND hair_color='blonde' AND (eye_color='green' OR eye_color='blue')
```




## Filter Children

Filter is like `.where()` but only filters child relations.  For example you would use a `where` to get all posts by `creator_id=1` and `include('comments')`, but use a `filter` to filter the child comments to all non deleted comments.  Thus a `filter` is only applicable if you also have some `include()` defined that shows MANY children.

Available chainables are `filter()` and `or_filter()`

```python
posts = await (Post.query()
    .include('comments')
    .where('creator_id', 1)
    .filter('comments.deleted', False)
    .get()
)
# URL: /posts?include=comments&where=["creator_id",1]&filter=["comments.deleted",false]
```

!!! tip
    The same rules for `where()` apply to `filter()`.  Meaning operator as 2nd parameter is optional.  Multiple filters may be either chained or used as a List of Tuples.  Just like `or_where()`, `or_filter()` is also available and has the same syntax.



## Order By

Order by is used to sort the main table by one or more columns, either ascending (the default) or aescending.


Get all posts ordered by `created_at` ascending.  Second param is optional, defaults to `ASC`.
```python
posts = await Post.query().order_by('created_at')
# URL: /posts?order_by=created_at
```

Get all posts ordered by `created_at` descending.  Notice the API URL turns into JSON at this point.
```python
posts = await Post.query().order_by('created_at', 'DESC')
# URL: /posts?order_by=["created_at","DESC"]
```

Order multiple columns, both by ASC.  Uses a `List of Tuples`
```python
posts = await Post.query().order_by([('creator_id'), ('created_at')])
# URL: /posts?order_by=[["creator_id"],["created_at"]]
```

Order multiple columns, choosing ASC or DESC.
```python
posts = await Post.query().order_by([('creator_id'), ('created_at','DESC')])
# URL: /posts?order_by=[["creator_id"],["created_at","DESC"]]
```



## Sort Children

Filter is like `.order_by()` but only sorts relations.  For example you would use an `order_by` to order all posts by `created_at DESC` but use a `sort` to sort the child comments by`created_at ASC`.  Thus `sort` is only applicable if you also have some `include()` defined that shows MANY children.
```python
posts = await (Post.query()
    .include('comments')
    .order_by('created_at', 'DESC')
    .sort('comments.created_at')
    .get()
)
# URL: /posts?include=comments&order_by=["created_at","DESC"]&sort=comments.created_at
```

You can also sort on many columns.  If a `List of Strings`, then no order is defined and the default of ASC (ascending) is used.
```python
posts = await (Post.query()
    .include('comments')
    .order_by('created_at', 'DESC')
    .sort(['comments.created_at', 'comments.title'])
    .get()
)
# URL: /posts?include=comments&order_by=["created_at","DESC"]&sort=["comments.created_at","comments.title"]
```

You can also define the sorting order, ASC or DESC by using a `List of Tuples`
```python
posts = await (Post.query()
    .include('comments')
    .order_by('created_at', 'DESC')
    .sort([('comments.created_at', 'ASC'), ('comments.title', 'DESC')])
    .get()
)
# URL: /posts?include=comments&order_by=["created_at","DESC"]&sort=[["comments.created_at","ASC"],["comments.title","DESC"]]
```



## Limit & Offset (Paging)

Use `.limit()` and `.offset()` to page through large result sets.  In the automatic model router these are driven by the `page` and `page_size` URL parameters.

```python
# First 25 posts
posts = await Post.query().order_by('id').limit(25).get()
# URL: /posts?page=1&page_size=25

# The next 25 (page 2)
posts = await Post.query().order_by('id').limit(25).offset(25).get()
# URL: /posts?page=2&page_size=25
```

!!! tip
    Always pair paging with an `.order_by()`.  Without an explicit order, databases like Postgres and MySQL do not guarantee row order, so your pages could overlap or skip rows.


## Count

Get the number of matching rows without pulling back the records themselves.

```python
total = await Post.query().count()
mine  = await Post.query().where('creator_id', 1).count()
```


## Key By

By default `.get()` returns a `List` of model instances.  Use `.key_by()` to instead return a `Dict` keyed by one of the model's fields, perfect for quick lookups.

```python
# Returns {'linux': <Tag>, 'mac': <Tag>, 'bsd': <Tag>, ...}
tags = await Tag.query().key_by('name').get()
linux = tags['linux']
```


## Update & Delete

The query builder can also perform bulk updates and deletes against everything matching your `.where()` clauses.

```python
# Bulk update matching rows
await Post.query().where('creator_id', 5).update(owner_id=1)

# Bulk delete matching rows
await Post.query().where('other', 'is', None).delete()
```

!!! note
    These operate directly at the query level and do **not** fire the model [lifecycle hooks](orm-basics.md#hooks).  To run hooks, load the model(s) and call `.save()` or `.delete()` on each instance instead.


## Caching

Cache a query's results with `.cache()`.  Pass an optional key, TTL `seconds` and `store`.  See [Cache](../deeper/cache.md) for backend configuration.

```python
# Cache using the default store and TTL
posts = await Post.query().cache().get()

# Custom key, 60 second TTL, specific store
posts = await Post.query().cache('all_posts', seconds=60, store='redis').get()
```


## Inspecting the SQL

While building a query, call `.sql()` to see the generated SQL without executing it, handy for debugging.

```python
from uvicore.support.dumper import dump

query = Post.query().include('comments').where('creator_id', 1)
dump(query.sql())
posts = await query.get()
```
