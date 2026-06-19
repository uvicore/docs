---
title: OpenAPI & Swagger Docs
---

# OpenAPI & Swagger Docs

One of the joys of building an API on FastAPI is that your interactive documentation comes for free, and Uvicore makes it even nicer.  Your [routes](routing.md) and [models](../../database/orm-pydantic.md) generate a complete OpenAPI schema, served through a polished Swagger UI that you control entirely from your app config.

Uvicore leans on FastAPI's OpenAPI generation under the hood, but the docs endpoints and Swagger UI behavior are configured from your `config/http.py`, so you tune them like everything else in Uvicore: through config, not code.

---

## Configuration

OpenAPI behavior lives under `api.openapi` in your `config/http.py`.

```python
# acme/wiki/config/http.py
'openapi': {
    'title': env('OPENAPI_TITLE', 'Acme Wiki API Docs'),
    'path': '/openapi.json',
    'docs': {
        'path': '/docs',
        'expansion': 'list',                 # list, none or full
        'favicon_url': '...',
        'js_url': '/assets/wiki/js/swagger-ui-bundle.min.js',
        'css_url': '/assets/wiki/css/swagger-dark-ui.css',
    },
    'oauth2_enabled': True,
},
```

---

## The Docs Endpoints

With the default config and an API prefix of `/api`, your docs are served at:

- **`/api/docs`** - the interactive Swagger UI
- **`/api/openapi.json`** - the raw OpenAPI schema

Fire up your dev server with `./uvicore http serve` and visit [http://127.0.0.1:5000/api/docs](http://127.0.0.1:5000/api/docs) to explore and try out every endpoint live.

---

## Getting Metadata Into Your Docs

Your docs are only as good as the metadata you give them, and Uvicore forwards plenty straight from your route definitions: `tags`, `summary`, `description`, `response_model`, and even the endpoint's docstring.

```python
@route.get(
    '/welcome',
    tags=['Welcome'],
    summary='Simple welcome endpoint',
    description='Returns a basic authenticated or anonymous welcome payload.',
    response_model=APIResponse[dict],
)
async def welcome(request: Request) -> APIResponse[dict]:
    """This docstring also shows up in the generated docs!"""
    ...
```

Because your [ORM models are Pydantic models](../../database/orm-pydantic.md), using one as a `response_model` or return type hint documents the entire response shape automatically.

!!! tip
    Group related endpoints with consistent `tags` and your Swagger UI becomes beautifully navigable.  Add a `summary` and `description` to your important endpoints and your API practically documents itself.

---

## Customizing the Swagger UI

Uvicore overrides FastAPI's default Swagger UI HTML so it can expose settings FastAPI normally hides.  From config alone you can control:

- endpoint expansion (`list`, `none` or `full`)
- local or CDN-hosted Swagger assets
- a custom favicon
- OAuth2 integration for interactive auth

This is why a fresh Uvicore app ships its own local Swagger assets under `http/public/assets/` and references them in the `docs` config, your docs work offline and on-brand out of the box.

---

## OAuth2 in the Docs

When `oauth2_enabled` is `true` and your OAuth2 settings are configured in [`config/auth.py`](authentication.md#oauth2-and-the-openapi-docs), Swagger UI displays an **Authorize** button so you (and your API consumers) can log in and test protected endpoints right from the docs.

!!! warning
    The OAuth2 docs integration is a convenience for *trying out* your API interactively.  It does not secure your endpoints, that's the job of the [Authentication middleware](authentication.md).

---

!!! tip "OpenAPI tips"
    - Tag consistently so the docs stay organized as your API grows.
    - Use docstrings, `summary` and `description` on the endpoints that matter.
    - Reach for explicit `response_model` definitions whenever the return shape is important.
    - Keep your docs endpoints configured from app config, never hardcoded in a controller.
