---
title: View Composers
---

# View Composers

A **view composer** is a small class that injects shared context into every view whose name matches a wildcard, *without* you having to repeat that data in every controller.

Think of the header, sidebar or footer that appears on every page of your site.  They usually need data, a list of tags for the sidebar, the logged-in user's notifications, the site's navigation.  Rather than fetching that data by hand in every single controller, you register one composer against a view wildcard like `wiki/*` and Uvicore runs it automatically for every matching view, merging its return value into the template context.

!!! note "See The Code on Github"
    - [composer decorator](https://github.com/uvicore/framework/blob/master/uvicore/foundation/decorators/composer.py)
    - [response.View()](https://github.com/uvicore/framework/blob/master/uvicore/http/response.py) — where composers are matched and merged
    - [register_http_view_composers()](https://github.com/uvicore/framework/blob/master/uvicore/http/package/registers.py)

!!! tip "Coming from Laravel?"
    Uvicore's view composers are modelled on [Laravel's view composers](https://laravel.com/docs/13.x/views#view-composers), so the idea will feel familiar: a class with a `compose()` method, registered in a provider's `boot()`, matched to views by name or wildcard (`*` for all).  A few deliberate differences to keep in mind:

    - **Argument order is reversed.**  Laravel is `View::composer($views, $composer)` (views first); Uvicore is `register_http_view_composers(module, views)` (the composer module first).
    - **Return instead of mutate.**  Laravel's `compose(View $view)` mutates the view with `$view->with(...)`.  Uvicore's `async def compose(self) -> dict` **returns** a dict that Uvicore merges into the context.
    - **Fixed constructor.**  Laravel resolves composers from the container and injects your constructor dependencies.  Uvicore hands every composer the same six render values (see below); resolve any other services yourself via `uvicore.ioc`.

---

## Anatomy of a Composer

A composer is a class decorated with `@uvicore.composer()` that defines an async `compose()` method returning a `dict`.  Whatever you return is merged into the view's context.

```python
# acme/wiki/http/composers/layout.py
import uvicore
from uvicore.http.request import Request
from acme.wiki.models import Tag


@uvicore.composer()
class Layout:
    """Layout composer - shared context for every wiki view."""

    def __init__(self,
        request: Request,
        name: str,
        context: dict,
        status_code: int,
        headers: dict,
        media_type: str,
    ) -> None:
        self.request = request
        self.name = name
        self.context = context
        self.status_code = status_code
        self.headers = headers
        self.media_type = media_type

    async def compose(self) -> dict:
        # The sidebar on every wiki page lists all tags.  Provide them here
        # once, instead of repeating this query in every controller.
        tags = await Tag.query().order_by('name').get()

        # This dict is merged into the view context
        return {
            'tags': tags,
        }
```

Uvicore constructs your composer fresh on **every** matching render and hands the `__init__` the same six values it used to build the response, so `compose()` has the full picture of the view being rendered:

| Parameter | What it is |
|---|---|
| `request` | The current `Request` (also available inside `compose()` via `self.request`) |
| `name` | The template name being rendered, e.g. `wiki/welcome.j2` |
| `context` | The context dict the controller passed to `response.View()` |
| `status_code` | The response status code |
| `headers` | The response headers dict |
| `media_type` | The response media type |

!!! tip
    Because a new instance is created and `compose()` is awaited on every render, composers are the right place for **per-request, dynamic** data.  The composer *class* lookup is cached for speed, but your `compose()` logic runs every time the view is rendered.

---

## Registering Composers

Composers are wired up in your [Package Provider](../../deeper/provider.md)'s `boot()` phase with `register_http_view_composers(module, views)`.  The first argument is the dotted path to your composer class; the second is a view wildcard (or a list of them).

```python
# acme/wiki/package/provider.py
def register_views(self) -> None:
    # Where your .j2 views live
    self.register_http_views(['acme.wiki.http.views'])

    # Run the Layout composer for every wiki/* view
    self.register_http_view_composers('acme.wiki.http.composers.layout.Layout', 'wiki/*')
```

The `views` argument accepts a single wildcard or a list of specific view names:

```python
# A single view
self.register_http_view_composers('acme.wiki.http.composers.layout.Layout', 'wiki/welcome')

# A list of specific views
self.register_http_view_composers('acme.wiki.http.composers.layout.Layout', ['wiki/welcome', 'wiki/post'])
```

To register several composers at once, pass a **dict** of `module -> views`:

```python
self.register_http_view_composers({
    'acme.wiki.http.composers.layout.Layout': 'wiki/*',
    'acme.wiki.http.composers.sidebar.Sidebar': ['wiki/post', 'wiki/tag'],
})
```

Use `append=True` to add more views to a composer you already registered (handy when one package extends another):

```python
self.register_http_view_composers('acme.wiki.http.composers.layout.Layout', ['auth/login'], append=True)
```

!!! note
    View composers share the package's `views` [registers flag](../../deeper/provider.md).  If `registers.views` is `False` for your package, its composers are skipped along with its views.

---

## How Matching Works

When you render a view, Uvicore compares its name against every registered composer wildcard:

- The match is made against the template name **with its file extension stripped**, so `wiki/welcome.j2` is matched as `wiki/welcome`.
- Wildcards are evaluated as **regular expressions** with Python's `re.search`, so `wiki/*` matches any view under `wiki/`.  The special value `*` on its own matches **every** view.
- **Multiple composers can match the same view** and they all run, so a broad `wiki/*` layout composer and a narrow `wiki/post` composer can both contribute context to the same page.
- Matches are cached per view name after the first render, purely as a performance optimization.

```python
# Every wiki page
self.register_http_view_composers('acme.wiki.http.composers.layout.Layout', 'wiki/*')

# Absolutely every view in the app, regardless of package
self.register_http_view_composers('acme.wiki.http.composers.global.Global', '*')
```

---

## The View Always Wins

A composer's returned dict is merged into the context as **defaults**, it only fills in keys the view does not already have.  If a controller already put a `tags` key into the context, that value stays and the composer's `tags` is ignored.

This is deliberate: composers provide sensible shared defaults, but any individual controller can always override them for a specific page.

```python
# This controller sets its own 'tags', so the Layout composer's 'tags' is ignored here
async def curated(request: Request):
    return await response.View('wiki/welcome.j2', {
        'request': request,
        'tags': await Tag.query().where('featured', True).get(),
    })
```

Inside your templates the composed context is available like any other variable:

```html
<aside class="sidebar">
  <h3>Tags</h3>
  <ul>
    {% for tag in tags %}
      <li>{{ tag.name }}</li>
    {% endfor %}
  </ul>
</aside>
```

---

## Generating a Composer

Uvicore ships a generator that scaffolds a composer from the standard stub into your package's `http/composers/` folder:

```bash
./uvicore gen composer layout
```

Composer names should be `lower_underscore` and **singular** (e.g. `layout`, `side_nav`).  After generating the file, register it in your provider's `boot()` as shown above.

---

## Web Views Only

Composers run inside `response.View()`, so they apply to server-rendered **Web** views only.  They do **not** run for [API](../api/index.md) JSON responses.  If you need shared data on the API side, compose it in your controllers, services or a [model router](../api/model-router.md) instead.

!!! tip "View composer tips"
    - Reach for a composer when the **same data** is needed by **many views**, header, sidebar, footer.
    - Register broad layouts with `wiki/*` and narrow, page-specific composers with an explicit view name.
    - Remember the view wins, a composer only fills context keys the controller didn't set.
    - Keep `compose()` lean, it runs on every matching render.
