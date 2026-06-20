---
name: uvicore-docs
description: Author, edit, or audit Uvicore documentation pages in this MkDocs repo. Use when adding a new docs page, editing existing docs, checking a docs section for gaps/redundancy/Web-API parallelism, or building/previewing the site. Encodes the house conventions, the Poetry-based build commands, and the dual-router structure.
---

# Working on the Uvicore docs

This is the MkDocs source for https://uvicore.io. Content lives in `docs/docs/`, nav + config in
`mkdocs.yml`. See `docs/CLAUDE.md` for the quick reference; this skill is the working procedure.

## Build / preview / verify (Poetry — never bare `mkdocs`)

```bash
./build                                 # poetry run mkdocs build  -> site/ (gitignored)
poetry run mkdocs build --strict        # the correctness gate — run after edits, expect exit 0
./serve                                 # poetry run mkdocs serve  -> http://0.0.0.0:8034
```

- **Gate on `--strict`.** It builds clean today; a non-zero exit means a real problem to fix.
- `--strict` does **not** fail on bad links — they emit `INFO ... 'absolute link' ... left as is`
  or `INFO ... 'unrecognized relative link' ... left as is` lines. These are **defects to fix**
  (links are relative `.md`, see below), so after edits scan the build output for any
  `absolute link` / `unrecognized relative link` lines and correct them.
- If `--strict` ever aborts on an emoji deprecation, fix `pymdownx.emoji` in `mkdocs.yml` to use
  `material.extensions.emoji.*` (not the old `materialx.emoji.*`).

## Verify API claims against real source

The framework is checked out at `~/Code/uvicore/framework`. Before documenting a signature,
option, or behavior, read the real code (e.g. `~/Code/uvicore/framework/uvicore/http/...`) rather
than inferring it. Don't ship an example you haven't grounded in source.

## House conventions (match neighbors exactly)

- Start with `---\ntitle: X\n---` then `# X`. Separate `##` sections with `---`.
- Links are **relative, with the `.md` extension**, resolved from the current file's directory:
  `[Routing](routing.md)`, `[Provider](../../deeper/provider.md)`, fragments like
  `[Where](orm-querybuilder.md#where)`. Do **not** use absolute (`/http/api/routing/`) or
  extension-less links — they break the build's link resolution.
- Admonitions: `!!! note`, `!!! tip "X tips"`, `!!! danger "..."`, and the
  `!!! note "See The Code on Github"` source-link block.
- Code fences tagged `python`/`bash`/`json`/`html`; examples use the `acme.wiki` demo namespace.
- Friendly, second-person voice. Close pages with a `!!! tip` bullet summary.

## Where a page goes (topic → folder)

Route the topic to its section folder under `docs/docs/` (full table in `CLAUDE.md`):
`getting-started/` (install/config/structure), `cli/`, `http/` (api/web/middleware/
exceptions), `database/` (db/ORM/seeding/recipes), `deeper/` (providers/IoC/events/jobs/
templating/cache/mail/http client/internals), `epologue/` (release notes/changelog/
upgrades). **Always prefer tightening the nearest existing page over creating a new one.**

## Adding a page (checklist)

1. Write the `.md` under `docs/docs/...` following conventions.
2. Register it in `mkdocs.yml` `nav:` at the right spot.
3. If the parent `index.md` has a "Reading This Section" list, add the page there too.
4. `poetry run mkdocs build --strict`, confirm exit 0 and every cross-link target file exists.

### Update triggers & anti-patterns

- A framework-behavior change (CLI, routes, provider/bootstrap flow, config layout,
  controllers, views, middleware, exceptions, ORM, cache, mail, jobs, events) should
  update **at least one** relevant page.
- Prefer tightening an existing page to duplicating a concept across sections.
- Never publish a page without wiring it into `mkdocs.yml` nav (and any parent
  "Reading This Section" list) — an unlinked page is invisible.
- No generic framework prose without concrete Uvicore file paths, provider methods,
  config examples, or commands. Don't document behavior the code doesn't support.

## The dual-router rule (most common source of gaps)

Web (HTML) and API (JSON) are separate routers with parallel docs. When touching one engine, check
the sibling for symmetry. Exceptions follow a hub-and-spoke shape: `http/exceptions/*` is the
canonical deep-dive; `http/web/exceptions.md` and `http/api/exceptions.md` are thin engine-specific
entry points that defer concepts to the hub. Keep shared concepts in one place.

## Auditing a section for gaps / redundancy / consistency

This repo is frequently reviewed for "is page X redundant?" or "is topic Y missing on the API side?".
Procedure that works well:

1. **Map both siblings.** Read the Web and API versions of the area (and any shared `http/*` hub).
2. **Classify overlap.** Separate genuinely duplicated prose from legitimately parallel structure.
   Duplicated *concepts* should live in one canonical page; *parallel structure* is good and should
   be preserved.
3. **Find the asymmetry.** Check `mkdocs.yml` nav and each `index.md` "Reading This Section" list —
   a topic present in one engine's nav but absent in the other's is a real (often navigational) gap.
4. **Decide placement**, then surface a recommendation to the user before large restructures
   (they care about the doc structure). Use a clarifying question when there's a real fork.
5. **Cross-link** the canonical page and its entry points in both directions.
6. **`poetry run mkdocs build --strict`** (expect exit 0) and verify all link targets resolve.

## Epologue / release docs flow

When docs touch the epologue, apply these versioning + release-note conventions
(filename patterns live in `CLAUDE.md`). Update is triggered by a change that:

- breaks compatibility, or removes/deprecates methods, config, or behavior;
- renames a public API, provider behavior, command, or config key;
- changes a default users rely on; or
- requires users to edit code/config to adopt it.

Which page to touch:

- `epologue/release-notes.md` — when the change is notable enough for the high-level
  release summary.
- `epologue/changelog/<version>.md` (e.g. `0.4.0.md`) — version-specific details.
- `epologue/upgrade/from-<old>-to-<new>.md` (e.g. `from-0.3-to-0.4.md`) — whenever
  users must take action to upgrade safely.

Writing rules: say **what** changed, **who** is affected, and **what action** to take;
include concrete before/after code or config for any nontrivial migration. Keep epologue
content aligned with actual (not planned) framework behavior, and wire new pages into
`mkdocs.yml` under `Epologue → Changelog` / `Epologue → Upgrade`.

## Superseding or retiring a page

When a new/rewritten page replaces older guidance or a section is reorganized, don't
leave the old page to drift:

1. Update the **new** page first so the replacement is complete.
2. Then retire the old page — delete it, shrink it to a pointer at the replacement, or
   (if it must stay temporarily) clearly label it obsolete and link forward.
3. Remove stale `mkdocs.yml` nav entries (and parent "Reading This Section" items) for
   any page that should no longer be published.
4. Scan neighboring pages for links/examples still pointing at the retired page and
   redirect them.
5. Never leave two active pages giving conflicting guidance, or published `TODO`/`FIXME`/
   obsolete-warning placeholders, once the replacement exists. Pages kept only for
   contributor/historical context belong in a deeper area, not as active end-user guidance.
