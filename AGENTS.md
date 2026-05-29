# AGENTS.md

## Cursor Cloud specific instructions

This is a **documentation-only repository** — a curated "awesome list" of OSINT tools for missing-persons investigations. It contains only Markdown files (`README.md`, `CONTRIBUTING.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `LICENSE`, `MAINTAINERS`). There is no application code, no build system, no services, and no runtime dependencies.

### Linting

- **Markdown lint**: `markdownlint README.md CONTRIBUTING.md .github/PULL_REQUEST_TEMPLATE.md`
  - `markdownlint-cli` is installed globally via npm in the update script.
  - The existing files have ~80 pre-existing lint warnings (line length, inline HTML, etc.) that are part of the upstream content — do not attempt to fix these unless explicitly asked.

### Contribution workflow

- See `CONTRIBUTING.md` for contribution guidelines (alphabetical ordering, descriptions, quality standards).
- PR template is at `.github/PULL_REQUEST_TEMPLATE.md`.
- Edits are limited to Markdown content; there is nothing to build or deploy.
