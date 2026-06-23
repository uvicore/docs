# Journal — Docs

A dated, chronological log of substantive work in **this repo** (the MkDocs site). Records *what
changed and why* — the reasoning behind a docs change, not just the diff.

> **Not published.** This lives at the repo **root**, outside `docs/docs/` (the MkDocs `docs_dir`),
> so it is never built into the site — same as `NOTES.md`. Do not move it under `docs/docs/`.

- **One file per day**: `journal/YYYY-MM-DD.md`. Append each piece of work as an `##` (H2) entry.
- **Update at the end of any substantive task** (new/restructured page, content correction, example
  overhaul). Skip trivia.
- **Cross-repo work**: note related edits in the sibling `framework`/`schematic` repos under
  **Related**.

## Entry template

```markdown
## <Short title>
- **Intent:** what was asked / the goal
- **Changed:** what changed and *why*
- **Files:** key pages touched (paths under docs/docs/)
- **Related:** framework/schematic edits, ADRs, follow-ups
```

Significant decisions get an [ADR](../adr/README.md).
