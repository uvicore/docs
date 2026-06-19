---
title: Pydantic
---

# Pydantic

Every Uvicore [ORM Model](orm-basics.md) **is** a [Pydantic](https://docs.pydantic.dev/) model.  When you decorate a class with `@uvicore.model()` and declare its fields, Uvicore builds a genuine Pydantic model behind the scenes.

This is one of Uvicore's most elegant tricks.  In raw FastAPI you typically maintain two parallel classes, a SQLAlchemy ORM model for the database *and* a separate Pydantic model for the API schema and validation.  In Uvicore they are **one and the same**.  Your model is your table mapping, your OpenAPI schema and your request validator, all in a single class.

!!! note
    Uvicore currently targets **Pydantic v1**.  Use v1 conventions (`class Config`, `.dict()`, `.json()`, `schema_extra`) in your models.

---

## What You Get for Free

Because your models are Pydantic models, you automatically gain:

- **Validation** of incoming request payloads on your [API routes](../http/api/routing.md).
- **Serialization** to and from JSON for API responses.
- **OpenAPI schema** generation for your [interactive docs](../http/api/openapi.md).
- **Type coercion** of field values according to your type hints.

```python
from acme.wiki.models.post import Post

post = await Post.query().find(1)

# Pydantic serialization helpers
post.dict()        # -> a plain python dict
post.json()        # -> a JSON string
```

When a model is the type hint of an [API route](../http/api/routing.md) parameter, Uvicore validates the request body against it.  When a model is the return type, Uvicore serializes it and documents it in OpenAPI.

```python
@route.post('/posts')
async def create(post: Post):              # request body validated against the Post model
    await Post.insert(post)

@route.get('/posts/{id}')
async def show(id: int) -> Post:           # response serialized + documented from the Post model
    return await Post.query().find(id)
```

---

## Customizing the Schema

Since your model is Pydantic, you can use Pydantic's `Config` class to tune the generated schema.  A common need is to provide a nicer **example** for the OpenAPI docs.

```python
@uvicore.model()
class Post(Model['Post'], metaclass=ModelMetaclass):
    """Wiki Posts"""

    class Config:
        schema_extra = {
            "example": {
                "id": 1,
                "slug": "title-as-a-slug",
                "title": "My First Post",
            },
        }

    # ... your fields ...
```

---

## Read-Only and Write-Only Fields

Uvicore's `Field()` adds first-class support for fields that should only appear in one direction, which maps directly onto OpenAPI's `readOnly` and `writeOnly`.

```python
id: Optional[int] = Field('id', primary=True, read_only=True)   # never accepted on input
password: str    = Field('password', write_only=True)           # never returned in output
```

- `read_only=True` fields are excluded from inserts and updates (great for auto-increment primary keys and timestamps) and marked `readOnly` in OpenAPI.
- `write_only=True` fields are excluded from query results and marked `writeOnly` in OpenAPI.

---

## Field Validation Options

Many `Field()` options flow straight through to the Pydantic schema and validators.

```python
slug: str = Field('unique_slug',
    description='URL friendly title',   # OpenAPI description
    max_length=255,                     # validation + schema constraint
    min_length=3,
    example='my-first-post',            # OpenAPI example
)
```

See [ORM Model](orm-model.md) for the complete list of `Field()` options.
