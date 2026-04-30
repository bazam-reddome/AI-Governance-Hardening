# AI Governance and Hardening Project

Open-source, framework-aligned starter kit for organisations adopting AI safely.
Templates, policy-as-code, sandbox patterns, CI gates, per-tool drop-ins, and an
interactive dashboard — all generic, all MIT-licensed, all designed to be forked
and tailored to your organisation in under an hour.

> **Live site:** browse `index.html` locally, or enable GitHub Pages on this
> repository (the `.github/workflows/pages.yml` workflow handles the rest).

---

## What's in here

A complete enterprise AI governance and technical-hardening programme. Three
layers: **policy** (Word standards), **catalogue** (Excel control workbooks),
and **engineering** (policy-as-code, scripts, sandbox configs, CI gates,
per-tool drop-ins). Every artefact is organisation-neutral — placeholders such
as `[Organization Name]`, `[Document Owner]`, and `[Security Contact]` are
designed to be replaced via the on-page **Customisation Wizard** or, if you
prefer, find-and-replace.

### Office templates (8 documents)

| File | Format | Purpose |
| --- | --- | --- |
| [`templates/AI-Usage-Governance-Standard-v1.0.docx`](templates/AI-Usage-Governance-Standard-v1.0.docx) | Word | The controlling Standard for AI use. Risk model, requirements, controls, framework crosswalk. |
| [`templates/AI-Acceptable-Use-Policy-and-Incident-Playbook-v1.0.docx`](templates/AI-Acceptable-Use-Policy-and-Incident-Playbook-v1.0.docx) | Word | End-user-friendly AUP plus an AI Incident Response Playbook with severity tiers, IOCs, and run-cards. |
| [`templates/AI-Tool-Risk-Assessment-v1.0.xlsx`](templates/AI-Tool-Risk-Assessment-v1.0.xlsx) | Excel | Vendor due-diligence questionnaire (41 questions) and per-connector / per-plugin / per-skill / per-MCP / per-agent assessment with auto-scoring. |
| [`templates/AI-Hardening-Controls-v1.0.xlsx`](templates/AI-Hardening-Controls-v1.0.xlsx) | Excel | Master hardening catalogue — **72 controls across 13 domains (A–M)** — plus tool-specific implementation playbooks and a maturity dashboard. |
| [`templates/AI-Built-App-Promotion-Runbook-v1.0.docx`](templates/AI-Built-App-Promotion-Runbook-v1.0.docx) | Word | Six-stage promotion runbook for AI-built applications with named owners, exit criteria, peer-review gate, and printable sign-off forms. Maps to NIST SSDF, SLSA v1.0, ISO/IEC 5338. |
| [`templates/AI-Code-Review-Checklist-v1.0.docx`](templates/AI-Code-Review-Checklist-v1.0.docx) | Word | Sixty-item review checklist a security engineer runs against an AI-generated PR. Mapped to OWASP LLM Top 10 (2025), OWASP ML Top 10, CWE Top 25, NCSC/CISA Secure AI Guidelines. |
| [`templates/Intune-Endpoint-Deployment-Guide-v1.0.docx`](templates/Intune-Endpoint-Deployment-Guide-v1.0.docx) | Word | Step-by-step Intune deployment for both macOS and Windows 11. Custom OMA-URI for AppLocker, Settings catalog for proxy, Defender XDR Web Content Filtering, ASR rule GUIDs, Day-2 ops. |
| [`templates/LLM-Application-Development-Guardrails-v1.0.docx`](templates/LLM-Application-Development-Guardrails-v1.0.docx) | Word | Guardrails for **building** an application that calls an LLM (RAG, chatbot, agent, summariser). Covers input validation, prompt-injection, RAG ACL preservation, output filtering, agentic scoping, observability, evaluation harness, plus a 39-item pre-deploy checklist. |

### Policy-as-code, scripts, sandbox, CI, per-tool drop-ins

| Path | What it is |
| --- | --- |
| [`templates/endpoint-policy/policy.yaml`](templates/endpoint-policy/policy.yaml) | YAML source-of-truth for AI coding-tool containment on developer endpoints. One file → six emitted vendor-native artefacts. |
| [`templates/endpoint-policy/policy.schema.json`](templates/endpoint-policy/policy.schema.json) | JSON Schema validating `policy.yaml` before emit. |
| [`templates/endpoint-policy/emit.py`](templates/endpoint-policy/emit.py) | Generator: produces Anthropic `managed-settings.json` + `managed-mcp.json`, AppLocker XML for Windows, TCC mobileconfig for macOS, firejail profile for Linux, and a canonical egress allow-list for the corporate proxy. |
| [`templates/scripts/aigov-preflight.sh`](templates/scripts/aigov-preflight.sh) / [`.ps1`](templates/scripts/aigov-preflight.ps1) | Run on login (or via 24-hour cron) to verify the endpoint is in the right state — managed config in place, egress proxy live, AppLocker enforced, sensitive env vars not loaded, AI processes inventoried. Emits JSON, optionally posts to your SIEM webhook. |
| [`templates/sandbox/wrangler.toml`](templates/sandbox/wrangler.toml) / [`docker-compose.yml`](templates/sandbox/docker-compose.yml) | Two reference sandbox patterns: Cloudflare Workers (D1/R2/KV-bounded, no egress beyond model APIs) and capability-hardened Docker Compose with tinyproxy egress firewall and Falco runtime monitoring. |
| [`templates/sandbox/Dockerfile.template`](templates/sandbox/Dockerfile.template) | Hardened multi-stage Dockerfile for an AI-built app: distroless final image, non-root user, HEALTHCHECK, OCI labels, ready for cosign signing + CycloneDX SBOM attestation. |
| [`templates/sandbox/k8s/`](templates/sandbox/k8s/) | Kubernetes hardening — production-ready Deployment + ServiceAccount + default-deny NetworkPolicy + five Kyverno cluster policies (image-signature verification via cosign, deny privileged / host-namespaces / default-SA, require resource limits + non-root + read-only-root, require image digests, harden default SA). Aligned to PSS-restricted, NSA/CISA Kubernetes Hardening Guide v1.2, and CIS Kubernetes Benchmark. |
| [`templates/ci/.pre-commit-config.yaml`](templates/ci/.pre-commit-config.yaml) | Pre-commit hooks: gitleaks, trufflehog, semgrep, custom AI-coauthor detector. |
| [`templates/ci/ai-app-gates.yml`](templates/ci/ai-app-gates.yml) | GitHub Actions workflow enforcing SLSA L3 provenance, Sigstore cosign signing, CycloneDX SBOM with ML-BOM extension, OSV-Scanner, and Trivy when a Dockerfile is present. |
| [`templates/ci/semgrep-ai-rules.yml`](templates/ci/semgrep-ai-rules.yml) | Custom Semgrep rules for AI-specific failure modes (untrusted RAG context, missing output guards, ungated tool calls, etc.). |
| [`templates/ci/TOOL_CATALOG.md`](templates/ci/TOOL_CATALOG.md) | Landscape map of **14 tool categories** with every option tagged 🟢 Free/OSS, 🟡 Free tier + Paid, or 🔴 Paid only — secrets · SAST · AI PR review · SCA · licence · container · IaC · DAST · SBOM · signing · eval harness · K8s admission · K8s runtime · ASPM. Includes side-by-side free-only and common enterprise stacks. **Suggestions, not requirements** — the kit's reference workflow uses the free stack but you can substitute freely. |
| [`templates/ci/optional-gates.yml`](templates/ci/optional-gates.yml) | Copy-pasteable GitHub Actions jobs for SonarCloud, GitHub CodeQL (GHAS), CodeRabbit, Snyk, Checkov, GHAS Dependency Review and Promptfoo. Drop in alongside `ai-app-gates.yml` without breaking the default workflow. |
| [`templates/per-tool/`](templates/per-tool/) | Drop-in configurations for **GitHub Copilot**, **Cursor**, **Codex CLI**, and **ChatGPT desktop**. Each tool gets a README explaining the enforcement scope plus the actual config file (`.cursorrules`, `copilot-instructions.md`, etc.). |

### Interactive dashboard

[`index.html`](index.html) is a single-file static dashboard that renders all
of the above into:

- A **What's inside** overview with anchor links to every section
- **Maturity Self-Assessment** — score yourself against high-impact controls drawn from Domains A–M, computed locally, exportable as CSV
- **Customisation Wizard** — fill in your organisation's details and download a single ZIP with every customisable file (Office docs **and** the policy-as-code, scripts, sandbox, CI and per-tool drop-ins) pre-filled and folder-structured ready to drop into your repos
- **How it works** — five flow diagrams (Endpoint Protection · SDLC Promotion · Policy-as-code Hardening · AI-built App Sandbox · LLM Application Development Guardrails) plus a per-tool enforcement matrix
- **Step-by-step guides** — interactive tabs for endpoint hardening (macOS / Windows) and the SDLC promotion runbook
- **Control catalogue** — searchable, filterable, with framework mappings on every row
- **Framework crosswalk** — every domain mapped to NIST AI RMF, ISO/IEC 42001, EU AI Act, OWASP LLM Top 10, MITRE ATLAS / D3FEND, NIST CSF 2.0
- **Top risks** — categorised threat list aligned to OWASP LLM Top 10 (2025) and MITRE ATLAS

---

## Frameworks covered

Every control and every section of the Standard is mapped to:

- **NIST AI Risk Management Framework 1.0** — Govern / Map / Measure / Manage
- **ISO/IEC 42001:2023** — AI Management System (AIMS) requirements and Annex A controls
- **ISO/IEC 5338:2023** — AI system life-cycle processes (used as the SDLC backbone)
- **EU AI Act (Regulation 2024/1689)** — risk-tier obligations for providers and deployers
- **NIST SSDF (SP 800-218)** + **SLSA v1.0** — secure SDLC and supply-chain provenance
- **OWASP Top 10 for LLM Applications (2025)** — LLM01–LLM10
- **OWASP Machine Learning Security Top 10**
- **MITRE ATLAS** + **MITRE D3FEND** — adversarial threat techniques and defensive countermeasures
- **NIST Cybersecurity Framework 2.0** — foundational cyber controls
- **NCSC + CISA Guidelines for Secure AI System Development** (Nov 2023)

---

## How to use

### Fastest path — the Customisation Wizard

1. Open `index.html` (locally or via your Pages deployment).
2. Scroll to **Customisation Wizard**, fill in your details (only Organization Name is required).
3. Click **Build my kit (ZIP)**. Everything happens in your browser — your inputs and the templates never leave your device.
4. Open the downloaded `ai-governance-kit-<your-org>.zip`. The folder structure inside (`endpoint-policy/`, `scripts/`, `sandbox/`, `ci/`, `per-tool/`) mirrors what you should drop into your repos and MDM.
5. The bundled `README.txt` lists any tokens that still need a manual touch (e.g. `[REPLACE_WITH_TENANT_SLUG]` in `sandbox/wrangler.toml`).

### Manual path — clone + find-and-replace

1. Clone or download the repository.
2. Open the eight Office templates in `templates/` and run a find-and-replace on the placeholders (each Word document includes a "How to use this template" section listing every placeholder).
3. Adapt `templates/endpoint-policy/policy.yaml` to your DNS, then run `python3 emit.py` to compile vendor-native enforcement files.
4. Wire `templates/ci/.pre-commit-config.yaml` and `templates/ci/ai-app-gates.yml` into your repos.
5. Drop `templates/per-tool/<tool>/` files into the repos using each tool.
6. Have your information security, legal, and privacy functions review and approve before publication.

### Track implementation

The `Maturity Dashboard` sheet of the Hardening workbook auto-calculates
coverage as you mark controls Implemented / Partial / Not Implemented / N/A.
The on-page Self-Assessment provides the same scoring against a
representative subset of the 72 controls so you get a coverage snapshot
without opening Excel.

---

## Deployment (GitHub Pages)

The repository ships with a GitHub Actions workflow at
[`.github/workflows/pages.yml`](.github/workflows/pages.yml) that publishes the
site on every push to `main`.

1. Push the contents to a public GitHub repository (for example `<your-org>/ai-governance-hardening`).
2. In **Settings → Pages**, set **Build and deployment → Source** to **GitHub Actions**.
3. Push to `main`. Within a minute the site is available at `https://<your-org>.github.io/<repo>/`.

The workflow uses `actions/checkout@v4`, `actions/configure-pages@v5`,
`actions/upload-pages-artifact@v3`, and `actions/deploy-pages@v4`. A
`.nojekyll` file is included so all assets serve verbatim with no Jekyll
processing.

---

## What this project is not

- It is not a product of, or endorsed by, any specific vendor.
- It is not legal, regulatory, or privacy advice. Local counsel must review the adapted Standard for jurisdictional fit.
- It is not exhaustive. AI risk evolves quickly; treat the templates as a **baseline to adapt**, not a fixed end-state.

---

## Currency and verification

Vendor menus, file paths, JSON schemas, framework identifiers, and CI tool
versions reflect what was current at the time of release. Before broad
rollout, verify the following against the most recent vendor and standards
documentation:

- **Anthropic Claude Code enterprise policy** — field names, JSON shape, and the machine-wide path of `managed-settings.json` (the kit emits a reasonable shape but Anthropic's docs are authoritative).
- **Microsoft Intune navigation paths** — Microsoft refreshes the Intune admin centre regularly. Steps in this kit assume the layout current at release. Web Content Filtering lives at `security.microsoft.com` (Defender XDR portal), not Intune.
- **Microsoft Defender ASR rule GUIDs** — verify against [learn.microsoft.com/.../attack-surface-reduction-rules-reference](https://learn.microsoft.com/en-us/defender-endpoint/attack-surface-reduction-rules-reference).
- **OWASP Top 10 for LLM Applications** — this kit cites the **2025** edition (released Nov 2024). Re-map IDs if a newer edition has shipped.
- **NIST AI RMF**, **ISO/IEC 42001**, **ISO/IEC 5338**, **EU AI Act** — citations are to published 2023/2024 editions; minor updates may have been issued.
- **MITRE ATLAS / D3FEND technique IDs** — both knowledge graphs evolve; verify at [atlas.mitre.org](https://atlas.mitre.org) and [d3fend.mitre.org](https://d3fend.mitre.org).
- **CI tool versions** (gitleaks, trufflehog, semgrep, trivy, osv-scanner, sigstore, slsa-github-generator) — bump pinned versions at adoption time and re-pin to a digest if your supply-chain policy requires it.

The kit is designed to be a starting point you tailor and verify, not an
authoritative configuration to copy verbatim.

---

## Contributing

Spotted a control we missed, or disagree with a mapping? Issues and pull
requests are welcome. When proposing changes:

- Keep all artefacts vendor-agnostic and generic — no real organisation names, vendor refs, or internal IDs.
- Include the framework mappings (NIST / ISO / EU AI Act / OWASP / MITRE) for any new control.
- Update both the workbook (`templates/AI-Hardening-Controls-v1.0.xlsx`) **and** the dashboard's `CONTROLS` array in `index.html` to keep them in sync.
- If you add a new template that contains placeholders, add it to `WIZ_FILES` in the `index.html` wizard so the customisation flow covers it.

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the full guide.

---

## License

Published under the [MIT License](LICENSE). Use, adapt, redistribute, or
rebrand for commercial or non-commercial purposes. No warranty.

---

## Versioning

The eight templates and the dashboard share a single version number. The
current release is **v1.0**.

---

## Acknowledgements

This kit pools practitioner work from across multiple enterprise security
programmes that have published controls for AI assistants, agentic AI
products, code assistants, productivity copilots, and AI-driven analytics
platforms. The aim of releasing it openly is to lower the cost of safely
adopting AI, particularly for organisations without a dedicated AI security
function.

Built and maintained by **Bazam Chekrian** — Security Architect with **15+
years** of experience across **Banking, Fintech, Healthcare** and **MSSP**.
Works across **DevSecOps**, **AppSec**, **Cloud Security** and hardening —
and applies that same engineering discipline to AI governance and risk for
enterprise AI tools.
[Connect on LinkedIn](https://www.linkedin.com/in/bazamchekrian/).
