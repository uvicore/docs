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







## Where


!!! note "Operators"
    Valid operators are `in, !in, like, !like, =, != >, >=, <, <=`.
    and `'null'` (in quotes) is a valid "value" (not operator), see null example below.

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

