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
    'separate_schemas': env.bool('OPENAPI_SEPARATE_SCHEMAS', False),
    'docs': {
        'path': '/docs',
        'expansion': 'list',                 # list, none or full
        'models_expansion': env.int('OPENAPI_MODELS_EXPANSION', -1),
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

## Taming Large Schema Sets

When you expose many models, especially through the [automatic model CRUD API](model-router.md), the OpenAPI schema can grow large and the Swagger UI can become sluggish, because Swagger renders the entire **Schemas** section and resolves every `$ref`.  A few config knobs keep it fast.

### `separate_schemas` — one schema per model, not two

By default FastAPI emits **two** schemas for every model, `Foo-Input` (request bodies) and `Foo-Output` (responses), even when the two are identical.  With a large model graph this doubles your schema count and can easily double the size of your `openapi.json`.

Uvicore defaults `separate_schemas` to `False`, collapsing each model into a **single** `Foo` schema:

```python
'openapi': {
    'separate_schemas': env.bool('OPENAPI_SEPARATE_SCHEMAS', False),  # one schema per model
    ...
},
```

Set it to `True` only if you genuinely need FastAPI's split input/output schema behavior (e.g. you rely on read-only fields differing between request and response).

### `models_expansion` — hide the giant Schemas section

The `models_expansion` setting maps to Swagger UI's `defaultModelsExpandDepth` and controls the **Schemas** section at the bottom of the docs:

- `-1` (Uvicore default) hides the Schemas section entirely, the single biggest win for responsiveness when your model graph is large.
- `0` shows the section collapsed.
- `1` or higher expands the models.

```python
'docs': {
    'models_expansion': env.int('OPENAPI_MODELS_EXPANSION', -1),  # -1 hides, 0 collapses, 1+ expands
    ...
},
```

!!! tip
    Hiding the Schemas section (`models_expansion: -1`) does not remove anything from `openapi.json`, your endpoints still document their full request/response shapes inline.  It only stops Swagger UI from rendering the (often huge) standalone model list.

### `model_expansion` — collapse the per-operation model tree

Hiding the Schemas section fixes the *initial* page load, but expanding a single operation (e.g. `GET /ros`) can still take a couple of seconds the first time, because Swagger recursively renders that operation's request/response **model tree** and resolves every nested relation `$ref`.

`model_expansion` maps to Swagger UI's `defaultModelExpandDepth` and controls that per-operation tree:

- `1` (Swagger's default) pre-renders one level of the model when you expand an operation.
- `0` keeps the model collapsed so operations expand instantly, you click into the model only when you want it.

```python
'docs': {
    'model_expansion': env.int('OPENAPI_MODEL_EXPANSION', 0),  # 0 = collapse per-op model, fastest
    ...
},
```

### `parameters` — any other Swagger UI setting

For anything else, `parameters` is a raw passthrough merged into the `SwaggerUIBundle({...})` config (and it overrides the defaults above).  For example, if the lag on expand is the **example-value** computation rather than the model tree, default each operation to the cheaper Schema tab:

```python
'docs': {
    'parameters': {
        'defaultModelRendering': 'model',   # show the Schema tab, not a computed Example Value
        'tryItOutEnabled': True,
    },
    ...
},
```

!!! note "The deeper lever"
    Per-operation expand cost scales with the size of each model's *resolved* schema.  The biggest models are big because their relations are embedded as nested `$ref`s that cascade through the graph.  These knobs make Swagger render that schema lazily; they don't shrink it.  If you need the schema itself smaller, reduce what each model embeds (relations are loadable on demand via `?include=`).

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
