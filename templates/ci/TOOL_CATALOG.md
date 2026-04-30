# CI / SDLC Tool Catalogue — suggestions, not requirements

This catalogue is a **landscape map**. None of the tools listed below
are required by the kit. They are *suggestions* organised by category
so you can shop within your budget and existing licences.

The reference workflows in this kit (`templates/ci/.pre-commit-config.yaml`
and `templates/ci/ai-app-gates.yml`) name **one tool per category**
because the example needs to be copy-paste runnable. Those picks are not
endorsements — they are simply the easiest free-tier tools to wire up
for someone starting from zero. If your organisation already pays for
SonarCloud, Snyk, Checkmarx, Sysdig, Apiiro or any of the alternatives
below, **substitute freely**. None of the frameworks the kit aligns to
(NIST SSDF, SLSA, ISO/IEC 5338, NCSC/CISA Secure AI Guidelines) mandate
a specific vendor.

## Legend

| Symbol | Meaning |
| --- | --- |
| 🟢 | **Free / OSS** — fully open source, no paid tier required |
| 🟡 | **Free tier + Paid** — usable for free at small scale, paid for enterprise capacity / features |
| 🔴 | **Paid only** — commercial product, licence required |

The reference-workflow pick for each category is marked **★** so you can
see at a glance what shipping the kit's `ai-app-gates.yml` gives you out
of the box.

---

## 1. Secrets in commits and CI logs

Catch secrets before they reach the remote, and verify any that slip through.

| Tool | License | Notes |
| --- | --- | --- |
| **★ gitleaks** | 🟢 Free / OSS | Pre-commit + CI; fast, large rule pack |
| **★ trufflehog (OSS)** | 🟢 Free / OSS | CI; verifies live credentials, lower noise than pattern-only scanners |
| GitHub Advanced Security — Secret Scanning + Push Protection | 🔴 Paid (free for public repos) | Native, blocks at push time, partner-verified secrets feed |
| GitGuardian | 🟡 Free tier + Paid | SaaS, broader coverage incl. private repos and SaaS scopes |
| Detect-secrets (Yelp) | 🟢 Free / OSS | Python-native, baseline-driven |
| Truffle Security (commercial) | 🔴 Paid | Cloud-managed trufflehog with org-wide visibility |

## 2. SAST and code quality

Static analysis for vulnerabilities and code quality / tech-debt signals.

| Tool | License | Notes |
| --- | --- | --- |
| **★ Semgrep Community** | 🟢 Free / OSS | Fast pattern + dataflow rules; the kit ships an AI-failure rule pack |
| Semgrep Pro | 🔴 Paid | Adds inter-procedural taint analysis, AppSec workflows |
| GitHub CodeQL via GHAS | 🔴 Paid (free for public repos) | Deep dataflow, multi-language; runs as a workflow |
| SonarCloud / SonarQube | 🟡 Free tier + Paid | Quality gate-as-policy; SonarQube Community is free, Cloud and Enterprise tiers add private-repo + advanced rules |
| Snyk Code | 🟡 Free tier + Paid | Low false-positive SAST with CodeAI prioritisation |
| Checkmarx One | 🔴 Paid | Enterprise SAST, regulated estates |
| Veracode Static Analysis | 🔴 Paid | Enterprise SAST, common in finance / public sector |
| Coverity (Synopsys) | 🔴 Paid | Deep static analysis, regulated estates |

## 3. AI-aware PR review (read every diff, comment in PR)

This category did not exist 18 months ago. Worth adding to catch logic
errors and missing guardrails that fixed-rule SAST misses. Treat the
suggestions as **advisory** — the peer-review gate in Stage 2 of the
Promotion Runbook still requires a *human* approver.

| Tool | License | Notes |
| --- | --- | --- |
| CodeRabbit | 🟡 Free tier + Paid | Free for OSS repos; learns repo conventions; richest of the AI reviewers |
| Sourcery | 🟡 Free tier + Paid | Automated refactoring suggestions, Python-strong |
| GitHub Copilot Code Review | 🔴 Paid (Copilot subscription) | Native to GitHub, lighter than CodeRabbit |
| Reviewdog | 🟢 Free / OSS | Meta-tool — posts findings from any linter as PR comments |
| Qodo Merge (formerly PR-Agent) | 🟢 Free / OSS | OSS LLM-powered PR review, brings your own API key |

## 4. Dependency CVE / SCA

Detect known-vulnerable dependencies and notify on upstream CVE drops.

| Tool | License | Notes |
| --- | --- | --- |
| **★ OSV-Scanner** | 🟢 Free / OSS | Google, OSV.dev backend; broad ecosystem coverage |
| **★ Trivy fs / image** | 🟢 Free / OSS | Aqua Security; OS + libs + IaC in one binary |
| GitHub Advanced Security — Dependency Review + Dependabot | 🔴 Paid (free for public repos) | PR-blocking + automated upgrades |
| Snyk Open Source | 🟡 Free tier + Paid | Combined CVE + licence + reachability |
| Sonatype Nexus Lifecycle / IQ | 🔴 Paid | Enterprise; supports policy-as-code |
| Mend (formerly WhiteSource) | 🔴 Paid | Enterprise SCA + remediation guidance |
| JFrog Xray | 🔴 Paid | Pairs with Artifactory |

## 5. Licence compliance

Catch licence-incompatible dependencies before they reach production.

| Tool | License | Notes |
| --- | --- | --- |
| **★ FOSSA Community** | 🟡 Free tier + Paid | Free for OSS projects, Paid for private |
| **★ ScanCode Toolkit** | 🟢 Free / OSS | Audit-grade scanner used in regulated environments |
| Snyk Open Source | 🟡 Free tier + Paid | Combined licence + CVE |
| Black Duck (Synopsys) | 🔴 Paid | Deepest licence + policy engine |
| FOSSology | 🟢 Free / OSS | Audit-grade licence reviewer; large rule pack |

## 6. Container / OCI image scanning

Vulnerability and config scanning for built images.

| Tool | License | Notes |
| --- | --- | --- |
| **★ Trivy image** | 🟢 Free / OSS | Default in `ai-app-gates.yml` when a Dockerfile is present |
| Grype + Syft | 🟢 Free / OSS | Anchore project; integrates with Anchore Enterprise |
| Snyk Container | 🟡 Free tier + Paid | Base-image upgrade suggestions, shift-left container hardening |
| Sysdig Secure | 🔴 Paid | Runtime + image + posture in one platform |
| Aqua Trivy Premium / Aqua Enterprise | 🔴 Paid | Commercial Trivy + policy + runtime |
| Anchore Enterprise | 🔴 Paid | Policy-driven container scanner |
| Wiz | 🔴 Paid | CNAPP — image + cloud + runtime correlation |

## 7. Infrastructure-as-Code (IaC) scanning

If your AI-built apps deploy via Terraform / Bicep / CloudFormation /
Kubernetes manifests, this category is mandatory. None of the kit's
default gates cover IaC — pick one.

| Tool | License | Notes |
| --- | --- | --- |
| Checkov | 🟢 Free / OSS | Bridgecrew (now part of Prisma Cloud); broad coverage, easy to tune. The optional-gates.yml example uses this. |
| tfsec | 🟢 Free / OSS | Terraform-only, fast (now folded into Trivy) |
| KICS | 🟢 Free / OSS | Checkmarx OSS; very large rule pack |
| Terrascan (Tenable) | 🟢 Free / OSS | OPA-aligned policy-as-code |
| Snyk IaC | 🟡 Free tier + Paid | Combined misconfig + CVE for IaC |
| Bridgecrew / Prisma Cloud Code Security | 🔴 Paid | Commercial Checkov with policy + remediation |

## 8. DAST and runtime testing

For AI-built apps that expose HTTP APIs or browser front-ends. Run after
deploy-to-staging, not as a pre-merge gate.

| Tool | License | Notes |
| --- | --- | --- |
| OWASP ZAP | 🟢 Free / OSS | Scriptable, GitHub Action available |
| Burp Suite Enterprise | 🔴 Paid | Better at modern SPAs and JS-heavy apps |
| StackHawk | 🟡 Free tier + Paid | DAST built for CI |
| Invicti / Acunetix | 🔴 Paid | Enterprise DAST, broad coverage |
| Nuclei | 🟢 Free / OSS | Templated vulnerability scanner |

## 9. SBOM generation and signing

Produce a CycloneDX or SPDX SBOM and attach it to the build artefact.

| Tool | License | Notes |
| --- | --- | --- |
| **★ Syft → CycloneDX with AI/ML extension** | 🟢 Free / OSS | Default in `ai-app-gates.yml` |
| CycloneDX-cli | 🟢 Free / OSS | Direct generator with deep ecosystem support |
| Anchore SBOM Action | 🟢 Free / OSS | For OCI images |
| SPDX format | 🟢 Free / OSS | Alternative SBOM format if downstream consumers prefer it |
| FOSSA SBOM | 🟡 Free tier + Paid | Managed SBOM service |

## 10. Build provenance and artefact signing

Attestations and signatures so downstream consumers can verify what was
built, where, and from what source.

| Tool | License | Notes |
| --- | --- | --- |
| **★ Sigstore cosign** | 🟢 Free / OSS | Keyless OIDC signing; the kit's default |
| **★ SLSA generator (slsa-framework)** | 🟢 Free / OSS | Provenance attestations at SLSA L3 |
| in-toto attestations | 🟢 Free / OSS | For layered build pipelines |
| Notary v2 (Notation) | 🟢 Free / OSS | OCI-native signing, enterprise registries |
| Chainguard Enforce | 🔴 Paid | Commercial cosign + policy |

## 11. AI-specific guardrail testing in CI

Eval harness for prompt-injection battery, hallucination tests,
groundedness checks, bias and drift. Distinct from SAST — these test
runtime LLM behaviour, not source-code patterns.

| Tool | License | Notes |
| --- | --- | --- |
| Promptfoo | 🟡 Free tier + Paid | OSS CLI + paid cloud; declarative test cases |
| DeepEval | 🟢 Free / OSS | Python, pytest-style LLM eval framework |
| LangSmith | 🟡 Free tier + Paid | LangChain — observability + eval harness |
| LangFuse | 🟡 Free tier + Paid | OSS + cloud; observability for any LLM stack |
| Patronus AI | 🟡 Free tier + Paid | Hallucination + safety scoring |
| Vectara HEM | 🟡 Free tier + Paid | Hallucination evaluation for RAG outputs |
| Lakera Guard | 🟡 Free tier + Paid | Prompt-injection + content safety |
| NeMo Guardrails (NVIDIA) | 🟢 Free / OSS | OSS guardrails framework |
| Azure AI Content Safety | 🟡 Free tier + Paid | Microsoft cloud; pay per request |
| OpenAI Moderation | 🟡 Free tier + Paid | Free for OpenAI customers via API |
| Microsoft Presidio | 🟢 Free / OSS | PII detection / redaction |

## 12. Kubernetes admission control + image-signature verification

The last opportunity to catch a bad image before it runs production traffic.
See `templates/sandbox/k8s/kyverno-policies.yaml` for a working baseline.

| Tool | License | Notes |
| --- | --- | --- |
| **★ Kyverno** | 🟢 Free / OSS | YAML-native, easy to author, large community policy library; the kit ships a policy bundle |
| OPA Gatekeeper | 🟢 Free / OSS | Rego-based, deeper ecosystem, common in regulated estates |
| Sigstore policy-controller | 🟢 Free / OSS | Focused on image-signature verification (Kubernetes-native cosign verify) |
| Connaisseur | 🟢 Free / OSS | Image signature admission controller, SLSA-aware |
| Nirmata Enterprise (Kyverno commercial) | 🔴 Paid | Commercial Kyverno + multi-cluster fleet management |

Pick **one** admission framework — running Kyverno and Gatekeeper in the
same cluster is rarely worth the operational cost.

## 13. Kubernetes runtime security

Detect attacks that *succeed* despite admission controls. Eventing layer
that feeds your SIEM.

| Tool | License | Notes |
| --- | --- | --- |
| Falco | 🟢 Free / OSS | Sysdig open source; syscall-based, large rule library |
| KubeArmor | 🟢 Free / OSS | eBPF + LSM; can detect AND prevent at runtime |
| Tetragon (Cilium) | 🟢 Free / OSS | eBPF observability + enforcement; integrates with Cilium NetworkPolicy |
| Sysdig Secure | 🔴 Paid | Commercial Falco; runtime + image + posture |
| Aqua Enterprise | 🔴 Paid | Commercial; broad runtime + container coverage |
| Datadog Cloud Workload Security | 🔴 Paid | Native to Datadog stacks |
| SentinelOne Singularity Cloud | 🔴 Paid | Commercial CWPP |

## 14. Application Security Posture Management (ASPM)

Optional layer. Aggregates findings across the categories above into a
single risk view with prioritisation by reachability and exploitability.
Not a pre-merge gate — an oversight layer for security leadership.

| Tool | License | Notes |
| --- | --- | --- |
| Apiiro | 🔴 Paid | Risk graph across SAST + SCA + secrets + IaC |
| Legit Security | 🔴 Paid | Pipeline + posture |
| Endor Labs | 🔴 Paid | SCA + reachability-prioritised |
| ArmorCode | 🔴 Paid | ASPM aggregator |
| Cycode | 🔴 Paid | ASPM + supply-chain |
| OpenSSF Scorecard | 🟢 Free / OSS | Project-level supply-chain hygiene scoring (lighter than commercial ASPM, but free) |

---

## How this fits the SDLC stages

The Promotion Runbook (`AI-Built-App-Promotion-Runbook-v1.0.docx`) defines
six stages. Each stage has a recommended set of categories from this
catalogue — *recommendations*, not requirements. You may collapse or
combine stages to fit your delivery model.

| Stage | Suggested categories |
| --- | --- |
| 1 — Generate (developer) | Pre-commit hooks: 1, 2 (light) |
| 2 — Pre-merge gates (CI + peer review) | 1, 2, 3, 4, 5, 7 |
| 3 — Build, sign, publish | 6, 9, 10 |
| 4 — Security review (manual) | Output of all above; AI Code Review Checklist |
| 5 — Sandbox deploy + soak | 8, 11, 12, 13 |
| 6 — Production deploy | Continuous: 11 (eval harness), 12 (admission), 13 (runtime), 14 (ASPM) |

## Free-only stack — if you have zero budget

Every category can be covered with 🟢 Free / OSS tools. This is the stack
the kit's reference workflow ships:

| Category | Free pick |
| --- | --- |
| 1 — Secrets | gitleaks + trufflehog (OSS) |
| 2 — SAST | Semgrep Community + p/llm-security |
| 3 — AI PR review | Qodo Merge (BYO API key) or Reviewdog |
| 4 — Dependency CVE | OSV-Scanner + Trivy |
| 5 — Licence | ScanCode Toolkit |
| 6 — Container | Trivy image |
| 7 — IaC | Checkov / KICS / Terrascan |
| 8 — DAST | OWASP ZAP / Nuclei |
| 9 — SBOM | Syft → CycloneDX |
| 10 — Signing | Sigstore cosign + SLSA generator |
| 11 — Eval harness | DeepEval / Promptfoo OSS / NeMo Guardrails |
| 12 — K8s admission | Kyverno or OPA Gatekeeper |
| 13 — K8s runtime | Falco or Tetragon |
| 14 — Posture | OpenSSF Scorecard |

## Common enterprise stack — if you already pay for security tooling

| Category | Common enterprise pick |
| --- | --- |
| 1 — Secrets | GHAS Secret Scanning + Push Protection / GitGuardian |
| 2 — SAST | SonarCloud / Snyk Code / Checkmarx / GHAS CodeQL |
| 3 — AI PR review | CodeRabbit |
| 4 — Dependency CVE | Snyk Open Source / GHAS Dependabot / Sonatype IQ |
| 5 — Licence | Black Duck / Snyk Open Source |
| 6 — Container | Snyk Container / Sysdig Secure / Wiz |
| 7 — IaC | Snyk IaC / Bridgecrew / Prisma Cloud |
| 8 — DAST | Burp Enterprise / Invicti |
| 9 — SBOM | (typically same — CycloneDX is the standard) |
| 10 — Signing | Sigstore cosign + SLSA generator (free; rarely replaced) |
| 11 — Eval harness | LangSmith / Patronus / Lakera Guard |
| 12 — K8s admission | Kyverno (free) or Nirmata Enterprise |
| 13 — K8s runtime | Sysdig Secure / Aqua Enterprise / Datadog CWS |
| 14 — Posture (ASPM) | Apiiro / Legit / Endor Labs |

---

## Bottom line

The kit's reference workflow (`ai-app-gates.yml`) ships a fully-free OSS
stack so anyone can use the kit on day one without procurement. The
categories above exist so you can tell quickly *what equivalent tools
exist*, *what they cost*, and *which already-licensed tool in your
organisation maps to which gate*. **Substitute, replace, or skip
freely** — none of these is enforced by the kit.

See `optional-gates.yml` in this directory for copy-pasteable GitHub
Actions jobs demonstrating how to wire SonarCloud, GitHub CodeQL (GHAS),
CodeRabbit, Snyk, Checkov, GHAS Dependency Review and Promptfoo as
additional jobs alongside the default workflow.
