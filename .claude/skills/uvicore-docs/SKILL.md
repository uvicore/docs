---
name: uvicore-docs
description: Author, edit, or audit Uvicore documentation pages in this MkDocs repo. Use when adding a new docs page, editing existing docs, checking a docs section for gaps/redundancy/Web-API parallelism, or building/previewing the site. Encodes the house conventions, the Poetry-based build commands, and the dual-router structure.
user-invocable: true
---

# Working on the Uvicore docs

This is the MkDocs source for https://uvicore.io. Content lives in `docs/docs/`, nav + config in
`mkdocs.yml`.

**`docs/CLAUDE.md` (always in context) already carries the basics — follow them as written:** the
Poetry build/preview commands and the `--strict` gate (including the after-edit scan for
`absolute link` / `unrecognized relative link` INFO lines, which are defects to fix); the
relative-`.md` link rule; the house conventions (frontmatter + `---` dividers, admonitions incl.
`See The Code on Github`, `python`/`bash`/`json`/`html` fences, friendly voice); the topic→folder
placement table and the add-a-page checklist; the epologue filename patterns; and the rule to read
the real framework source at `~/Code/uvicore/framework` before documenting any signature or behavior.

What follows is the on-demand working procedure and reference CLAUDE.md doesn't carry: the canonical
`acme.wiki` entities, the update/anti-pattern triggers, the dual-router audit procedure, and the
supersede/retire procedure.

## The `acme.wiki` demo domain (canonical — reuse these exact names)

**Every example across the whole site lives in one shared fictional app.** Don't invent per-page
entities — drift (`vfi`, `myapp`, random model names) is the #1 consistency defect here. Reuse:

- **Namespace** `acme.wiki`; **connection** `'wiki'`. The cross-package user lives in the **auth**
  package — reference it as `uvicore.auth.models.user.User` / table `auth.users`; never redefine it.
- **Core entities** (model → table, tables are snake_case plural):

  | Model | Table | Key columns | Relations |
  |---|---|---|---|
  | `Post` | `posts` | `id`, `unique_slug` (mapped to model field `slug`), `title`, `body`, `creator_id` | `creator` BelongsTo `User`; `comments` HasMany; `tags` BelongsToMany (pivot `post_tags`) |
  | `Comment` | `comments` | `id`, `post_id`, `creator_id`, `body` | `post` BelongsTo `Post` |
  | `Tag` | `tags` | `id`, `name` | `posts` BelongsToMany (pivot `post_tags`) |
  | `User` | `auth.users` | (from the auth package) | target of `creator` |

- **Pivot** `post_tags` (`post_id`, `tag_id`). **Polymorphic** examples use `Attribute` via
  `MorphMany(..., polyfix='attributable')`.
- **Sharded / composite-key** examples: lead with shard keys `tenant_id`, `workspace_id`, then the
  natural key (`posts.id` ↔ `comments.post_id`). See `database/orm-querybuilder.md`.
- **Need a niche entity** a core one can't illustrate? Keep it in the wiki domain, snake_case, and
  prefer reusing it. Existing one-offs (`Forecast` for computed `callback`; `invoices` for composite
  PKs) are tolerated as feature-specific illustrations — don't add more without good reason.

When in doubt, grep `docs/docs/` for how the entity is already used and match it exactly.

## Update triggers & anti-patterns

- A framework-behavior change (CLI, routes, provider/bootstrap flow, config layout,
  controllers, views, middleware, exceptions, ORM, cache, mail, jobs, events) should
  update **at least one** relevant page.
- Prefer tightening an existing page to duplicating a concept across sections.
- Never publish a page without wiring it into `mkdocs.yml` nav (and any parent
  "Reading This Section" list) — an unlinked page is invisible.
- No generic framework prose without concrete Uvicore file paths, provider methods,
  config examples, or commands. Don't document behavior the code doesn't support.

## Auditing a section for gaps / redundancy / consistency

Web (HTML) and API (JSON) are separate routers with **deliberately parallel** docs, so audits center
on sibling symmetry. Exceptions follow a hub-and-spoke shape: `http/exceptions/*` is the canonical
deep-dive; `http/web/exceptions.md` and `http/api/exceptions.md` are thin engine-specific entry
points that defer concepts to the hub. This repo is frequently reviewed for "is page X redundant?"
or "is topic Y missing on the API side?". Procedure that works well:

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

## Epologue / release docs — when to update

When docs touch the epologue, the filename patterns live in `CLAUDE.md`; the trigger to update is a
change that:

- breaks compatibility, or removes/deprecates methods, config, or behavior;
- renames a public API, provider behavior, command, or config key;
- changes a default users rely on; or
- requires users to edit code/config to adopt it.

Which page to touch: `epologue/release-notes.md` (when notable enough for the high-level summary);
`epologue/changelog/<major.minor>.md` (version-specific details); `epologue/upgrade/from-<old>-to-<new>.md`
(whenever users must act to upgrade safely). Writing rules: say **what** changed, **who** is affected,
and **what action** to take; include concrete before/after code or config for any nontrivial
migration. Keep epologue content aligned with actual (not planned) behavior, and wire new pages into
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
