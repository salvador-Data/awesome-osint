# AGENTS.md

## Cursor Cloud specific instructions

This is a **documentation-only repository** — a comprehensive curated list of 320+ OSINT, cybersecurity, and ethical hacking tools across 36 categories. It is maintained by Hacker Planet LLC and endorsed by TraceLabs. There is no application code, no build system, no services, and no runtime dependencies.

### Repository structure

- `README.md` — The main tools list (320+ tools, 36 categories, ~590 lines).
- `CONTRIBUTING.md` — Contribution guidelines (alphabetical ordering, descriptions, quality standards).
- `.github/PULL_REQUEST_TEMPLATE.md` — PR template.
- `LICENSE` — Mozilla Public License 2.0.
- `MAINTAINERS` — List of maintainers.

### Categories overview

The README covers: Email Search, Multi Search, Username Search, Social Media, Phone Numbers, People Search, Images & Video Analysis, Documentation & Capture, Geolocation & Mapping, Domain/IP/Infrastructure, Wireless, Translation, Public Records & Court Data, Dark Web & Paste Sites, Cryptocurrency & Blockchain, Vehicle & Property Lookup, Threat Intelligence, OSINT Frameworks & Automation, Data Breach & Credential Search, Flight & Maritime Tracking, Business & Corporate Intel, Browser Extensions for OSINT, Sock Puppet & Alias Management, Password & Hash Tools, Metadata & File Analysis, Search Engine Dorking, Maps & Satellite Imagery (Advanced), Missing Persons Specific, Academic & Research-Grade Tools, AI-Powered OSINT Platforms, OSINT Training & Methodology, White Hat Penetration Testing, Vulnerability Scanning & Assessment, Network Reconnaissance, Social Engineering Tools, and Security Distributions.

### Linting

- **Markdown lint**: `markdownlint README.md CONTRIBUTING.md .github/PULL_REQUEST_TEMPLATE.md`
  - `markdownlint-cli` is installed globally via npm in the update script.
  - Most lint warnings are line-length (MD013) on URL lines — expected for a links list. Do not attempt to fix these unless explicitly asked.

### User conventions

- When Sal says **"memory update"** he means **update `AGENTS.md`** with whatever was just discussed or changed.
- Always update `AGENTS.md` when making structural changes to the repo.

### Editing conventions

- Tools within each category are listed **alphabetically**.
- Each entry follows the format: `- [Tool Name](URL) – Description ending with a period.`
- New categories require at least 3 tools.
- When adding tools, check for duplicates across categories — some tools appear in multiple sections where relevant.
- See `CONTRIBUTING.md` for full quality standards.
- PR template is at `.github/PULL_REQUEST_TEMPLATE.md`.
