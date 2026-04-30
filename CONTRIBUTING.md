# Contributing

Thanks for considering a contribution. The aim of this project is to keep a vendor-neutral, framework-aligned baseline for AI governance that any organisation can adopt.

## Ground rules

- **Stay generic.** Do not introduce specific vendor names, internal team names, or organisation-specific procedures. Use placeholders such as `[Organization Name]`, `[Document Owner]`, `[Security Contact]`.
- **Map every control.** New hardening controls or governance requirements must be mapped to at least two of: NIST AI RMF, ISO/IEC 42001, EU AI Act, OWASP LLM Top 10, MITRE ATLAS.
- **Keep the dashboard in sync.** If you change `templates/AI-Hardening-Controls-v1.0.xlsx`, mirror the changes in the `CONTROLS` array in `index.html` so the dashboard reflects the same controls.
- **Mind the bullet count.** The Word documents are designed to be readable in a single sitting. Long lists are a smell — prefer adding a referenced sub-document.

## How to propose a change

1. Open a GitHub issue describing the change and the rationale.
2. For non-trivial changes, wait for an issue triage response before opening a PR.
3. Submit a PR that includes:
   - Updated artefact(s)
   - Updated framework mappings
   - Updated change-log entry in the Word document's Change Record table
4. Bump the version (semver). Patch for typos and clarifications; minor for new controls; major for restructuring.

## Building the templates

The `.docx` files are produced from JavaScript (using `docx`) and the `.xlsx` files are produced from Python (using `openpyxl`). The build scripts live in the project root in this repository's history, but you do not need to rebuild them to use the templates. If you do want to rebuild:

- Word: `node build_governance.js out.docx`, requires `npm install docx`.
- Excel: `python3 build_hardening.py out.xlsx`, requires `pip install openpyxl`.

## Code of conduct

Be kind. Disagree on substance, not on people. This project exists because AI governance benefits from shared, open baselines — that culture starts in the issue tracker.
