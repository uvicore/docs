# Uvicore Docs

This repo is the MkDocs source for https://uvicore.io — documentation for the Uvicore framework.
It contains **no framework code**, only Markdown content under `docs/docs/` plus `mkdocs.yml`.

## Commands (always use Poetry)

MkDocs is installed in a Poetry venv, **not** globally. Always prefix with `poetry run`.

| Task | Command | Notes |
|------|---------|-------|
| Build | `./build` or `poetry run mkdocs build` | Output goes to `site/` (gitignored) |
| Build (gated) | `poetry run mkdocs build --strict` | **Use this to validate work** — exits non-zero on real problems |
| Live preview | `./serve` or `poetry run mkdocs serve` | Serves on `0.0.0.0:8034` |
| Deploy | `./deploy-xenweb1` | Builds + rsyncs `site/` to the web host |

Python 3.14.x (floor `>=3.12`), Poetry, `package-mode = false`. Deps: `mkdocs`, `mkdocs-material`.

### `--strict` is the correctness gate
`poetry run mkdocs build --strict` builds clean (exit 0) and is the gate to run after edits.
Note it does **not** fail on link problems — bad links emit `INFO ... 'absolute link' ... left as is`
or `INFO ... 'unrecognized relative link' ... left as is` (not warnings), so after edits scan the
build output for any `absolute link` / `unrecognized relative link` lines and fix them (see Links
below — links must be relative `.md`). If `--strict` ever aborts on an emoji
deprecation again, it's the `pymdownx.emoji` config: the index/generator must point at
`material.extensions.emoji.*`, not the old `materialx.emoji.*`.

## Layout

- `docs/docs/` — all Markdown content (the MkDocs `docs_dir`).
- `docs/mkdocs.yml` — site config **and navigation**. Every page must be added to the `nav:` tree or it won't appear.
- `docs/NOTES.md`, `docs/docs/http/api/NOTES.md` — scratch TODO lists of content to fold into real pages. Not published.
- `site/` — build artifact, gitignored, never edit by hand.

Top-level nav sections: Getting Started, **HTTP** (API / Web / Middleware / Exceptions), CLI, Database (Database / ORM), Digging Deeper, Epologue.

### Where a page goes (topic → folder)

When deciding where to place or look for a page, map the topic to its section folder
under `docs/docs/`. Prefer editing the nearest existing page over creating a new one.

| Topic | Folder |
|-------|--------|
| Install, configuration, app/directory structure | `getting-started/` |
| CLI usage, writing commands | `cli/` |
| API, web, middleware, exceptions | `http/` |
| Database, SQLAlchemy, ORM, seeding, recipes | `database/` |
| Providers, IoC, events, jobs, templating, cache, mail, http client, internals | `deeper/` |
| Release notes, changelog, upgrades | `epologue/` |

### Epologue / release docs (filename conventions)

Release-oriented pages live under `docs/docs/epologue/` with **fixed filename patterns** —
don't invent variants:

- `epologue/release-notes.md` — high-level release summary.
- `epologue/changelog/<version>.md` — version-specific details, e.g. `0.4.0.md`.
- `epologue/upgrade/from-<old>-to-<new>.md` — migration steps, e.g. `from-0.3-to-0.4.md`
  (minor-version path; not `from-0.3.0-to-0.4.0.md`).

Avoid `v0.4.md`, `upgrade-0.3-0.4.md`, and similar. Wire new pages into `mkdocs.yml`
under `Epologue → Changelog` / `Epologue → Upgrade`. See the `uvicore-docs` skill for
when each page is required.

## Verifying framework claims against real source

The actual framework source is checked out locally at `~/Code/uvicore/framework`
(e.g. `~/Code/uvicore/framework/uvicore/http/...`). When documenting an API — a class signature,
a router option, an exception constructor — **read the real source** instead of guessing. The
"See The Code on Github" admonitions in the docs link to the same files at
`github.com/uvicore/framework/blob/master/...`.

## Writing conventions (match the existing pages)

- **Frontmatter + H1**: every page starts with `---\ntitle: Page Title\n---` then `# Page Title`.
- **Section dividers**: separate top-level `##` sections with a `---` horizontal rule.
- **Admonitions**: `!!! note`, `!!! tip "Title"`, `!!! danger "Title"`. The recurring
  `!!! note "See The Code on Github"` block links to framework source.
- **Links are RELATIVE, with the `.md` extension**: e.g. `[Routing](routing.md)`,
  `[Provider](../../deeper/provider.md)`, fragments like `[Where](orm-querybuilder.md#where)`.
  Paths are relative to the **current file's directory**. Do **not** use absolute links
  (`/http/api/routing/`) or extension-less links (`built-in-commands`) — the build must emit no
  `'absolute link'` / `'unrecognized relative link'` INFO lines.
- **Code fences** are language-tagged: `python`, `bash`, `json`, `html`. Python examples use the
  `acme.wiki` demo package namespace.
- **Voice**: friendly, second person, lightly playful ("Great.", "It's routers all the way down!").
  Keep it instructional, not stiff.
- End most pages with a `!!! tip "X tips"` bullet summary.

## The dual-router model (recurring architecture theme)

Uvicore separates **Web** (HTML) and **API** (JSON) into two routers with independent middleware,
auth and exception handlers, configured per-engine in `config/http.py` (`web.*` / `api.*`).
Consequences for the docs:

- **Web and API pages are deliberately parallel.** When you add or restructure a page in one,
  check whether the sibling needs the same treatment so the two stay symmetric (same section
  order, naming, depth). Justified divergences exist (Web has `views`/`templating`; API has
  `model-router`/`openapi`).
- **Exceptions**: `http/exceptions/*` is the **canonical, engine-agnostic** deep-dive (concepts,
  handlers, SmartException, one page per exception type). `http/web/exceptions.md` and
  `http/api/exceptions.md` are thin **engine-specific entry points** that show how to throw from
  that engine and what the response looks like, then defer the depth to `http/exceptions/*`.
  Keep concepts in one place — don't re-duplicate the shared section into the engine pages.

## Adding or editing a page

1. Create/edit the `.md` under `docs/docs/...` following the conventions above.
2. Add it to `nav:` in `mkdocs.yml` (and to any "Reading This Section" list on the parent `index.md`).
3. Run `./build` and confirm it compiles and your cross-link targets exist.
4. For a fuller authoring/audit workflow, see the `uvicore-docs` skill in `.claude/skills/`.
