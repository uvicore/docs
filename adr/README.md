# Architecture Decision Records (ADRs)

One file per **significant, hard-to-reverse decision** about the docs site itself — information
architecture, section structure, build/tooling choices, conventions that shape many pages. Routine
content work goes in the [journal](../journal/README.md).

> **Not published.** Lives at the repo **root**, outside `docs/docs/`, so MkDocs never builds it.

Framework *behavior* decisions belong in the framework repo's ADRs, not here — link to them from a
page or journal entry instead.

- **Filename**: `NNNN-kebab-title.md` (sequential).
- **Format** (compact Nygard): Status, Date, Context, Decision, Consequences.
- **Supersede, don't rewrite**: mark a replaced ADR `Superseded by ADR-XXXX`.

## Template

```markdown
# ADR NNNN: <Title>

- **Status:** Accepted | Proposed | Superseded by ADR-XXXX
- **Date:** YYYY-MM-DD

## Context
## Decision
## Consequences
```

## Index
_(none yet)_
