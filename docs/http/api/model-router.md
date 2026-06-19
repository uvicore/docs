---
title: API Model Router
---

# API Model Router

Here is one of Uvicore's most delightful super-powers: the **Model Router** can generate a full set of REST-style CRUD endpoints for your [ORM models](../../database/orm-basics.md) automatically, complete with OpenAPI metadata, response models and permission scopes.  Register your models, include the router, and you instantly have a rich, query-driven, permission-protected API, no controllers to write.

It's perfect for the large swathe of endpoints that map cleanly onto your data.  And when an endpoint needs real business logic instead, you simply write a [controller](routing.md) for it, the two happily coexist.

---

## Enabling the Model Router

Include `ModelRouter` from your top-level API routes file, passing it your `auto_api` config.

```python
# acme/wiki/http/routes/api.py
import uvicore
from uvicore.http.routing import Routes, ApiRouter, ModelRouter

@uvicore.routes()
class Api(Routes):

    def register(self, route: ApiRouter):
        route.controllers = 'acme.wiki.http.api'
        route.controller('welcome')

        # Generate CRUD endpoints for all your registered models
        route.include(ModelRouter, options=uvicore.config.app.api.auto_api)

        return route
```

---

## Configuration

The router's behavior is controlled from your `config/http.py` under `api.auto_api`.

```python
# acme/wiki/config/http.py
'auto_api': {
    # Only include models matching these wildcards (empty = all registered models)
    'include': [
        # 'acme.wiki.models.*'
    ],
    # Exclude models matching these wildcards
    'exclude': [
        # '*.models.user.*'
    ],
    # Override the default per-model CRUD scopes
    # 'scopes': []
},
```

- **`include`** - only generate endpoints for matching models.
- **`exclude`** - skip matching models.
- **`scopes`** - override the automatic CRUD permission scopes (see below).

---

## Generated Endpoints

For every included model, Uvicore generates a conventional REST surface:

| Method & Path | Purpose |
|---------------|---------|
| `GET /<model>` | List, with rich query-driven filtering |
| `GET /<model>/{id}` | Fetch a single record by primary key |
| `POST /<model>` | Create one or many records |
| `POST /<model>/with_relations` | Create with nested relations |
| `PUT /<model>/{id}` | Full update (replace) |
| `PATCH /<model>/{id}` | Partial update |
| `DELETE /<model>/{id}` | Delete a single record |

Every one of these arrives fully documented in your [OpenAPI docs](openapi.md), with response models and permission scopes already attached.

---

## The Default Permission Model

By default, each model's endpoints are guarded by CRUD-style scopes derived from the table name.  For a `users` model:

| Scope | Required by |
|-------|-------------|
| `users.read` | `GET` (list and detail) |
| `users.create` | `POST` |
| `users.update` | `PUT` and `PATCH` |
| `users.delete` | `DELETE` |

This convention maps cleanly onto your [authorization](authorization.md) scopes and keeps permission naming predictable across your whole app.

---

## Overriding Scopes

**Make the whole auto API public** (no permissions required):

```python
route.include(ModelRouter, options={'scopes': []})
```

**Use one shared scope list for every endpoint** (replaces the CRUD scopes):

```python
route.include(ModelRouter, options={'scopes': ['authenticated', 'autoapi_user']})
```

**Set custom scopes per verb:**

```python
route.include(ModelRouter, options={
    'scopes': {
        'create': ['autoapi.create'],
        'read':   ['autoapi.read'],
        'update': ['autoapi.update'],
        'delete': ['autoapi.delete'],
    }
})
```

**Append extra scopes on top of the CRUD defaults** by wrapping the router in a group:

```python
@route.group(scopes=['authenticated', 'autoapi_user'])
def autoapi():
    route.include(ModelRouter)
```

This keeps each model's default CRUD scopes *and* layers the group's scopes on top, since [guards merge](middleware.md#how-middleware-layers-merge).

---

## Query Parameters

The `GET /<model>` list endpoint is driven entirely by query parameters, which Uvicore translates directly into [ORM Query Builder](../../database/orm-querybuilder.md) operations.  Values are JSON, so spin up complex queries right from the URL.

| Parameter | Example | Description |
|-----------|---------|-------------|
| `include` | `include=creator,comments` | Eager-load relations (dot-nested allowed) |
| `where` | `where=["creator_id", 1]` | Filter the main query |
| `or_where` | `or_where=[["id",1],["id",7]]` | OR group of conditions |
| `filter` | `filter=["status","active"]` | Filter the rows of an included `*Many` relation |
| `or_filter` | | OR variant of `filter` |
| `order_by` | `order_by=["id","DESC"]` | Sort the main query |
| `sort` | | Sort within `*Many` relations |
| `page` | `page=2` | Page number |
| `page_size` | `page_size=50` | Records per page (ORM limit/offset) |

The `where` family uses a **JSON list** format, not a dict:

```text
# Field and value (operator defaults to =)
?where=["creator_id", 1]

# Field, operator, value
?where=["id", ">", 5]
?where=["email", "like", "%example.com"]
?where=["id", "in", [1, 5, 9]]

# Multiple ANDed conditions (a list of lists)
?where=[["creator_id", 1], ["other", "is", null]]
```

!!! tip
    `LIKE` is case-sensitive on some databases (Postgres) and case-insensitive on others (SQLite, MySQL).  Use the `ilike` operator for portable case-insensitive matching.  See the [ORM Query Builder](../../database/orm-querybuilder.md) for the full operator list.

---

## Relation Includes Are Permission-Checked

When a client uses `include` to pull in related models, Uvicore verifies the user is allowed to *read each included entity* too.  So a request can pass the parent model's scope and still be denied if it tries to include a child relation the user lacks `*.read` permission for.  Your authorization is enforced all the way down the object graph, automatically.

---

## When to Use It

!!! success "Reach for the Model Router when"
    - your models map cleanly onto CRUD endpoints
    - the default permission naming works for you
    - query-driven list and detail endpoints are enough

!!! note "Prefer hand-written controllers when"
    - your API isn't CRUD-shaped
    - you need custom business workflows
    - each endpoint needs distinct, non-CRUD authorization
    - you need full control over request and response payloads

The best apps use both, the Model Router for the bulk of resourceful endpoints, and [controllers](routing.md) for the handful that need a human touch.
