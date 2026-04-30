# Security Policy

## Supported Versions

Only the latest commit on `main` is actively maintained.

| Branch / Version | Supported |
|-----------------|-----------|
| `main` (latest) | ✅ Yes    |
| All prior tags  | ❌ No     |

---

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Please report security issues via **GitHub's private vulnerability reporting** feature:

1. Navigate to <https://github.com/bazam-reddome/AI-Governance-Hardening/security/advisories>
2. Click **"Report a vulnerability"**
3. Complete the advisory form with as much detail as possible

Alternatively, you may e-mail **bazam@reddome.org** with the subject line:  
`[SECURITY] AI-Governance-Hardening — <brief description>`

### What to include

- Affected file(s) / section(s)
- Steps to reproduce or proof-of-concept
- Potential impact / attack scenario
- Suggested remediation (if any)

---

## Response SLA

| Milestone                     | Target      |
|-------------------------------|-------------|
| Acknowledgement               | ≤ 48 hours  |
| Triage & severity assessment  | ≤ 5 days    |
| Fix or documented mitigation  | ≤ 30 days   |
| Public disclosure             | After fix   |

---

## Scope

This repository contains **governance documentation, HTML/JavaScript, CI workflow files, and Office templates**.  
The primary security concerns are:

- **Workflow / CI supply-chain**: malicious changes to `.github/workflows/` or pinned action SHAs
- **Secret leakage**: accidental commit of credentials, API keys, or PII in templates or scripts
- **Content integrity**: misleading or harmful advice in governance/hardening documentation

Issues outside this scope (e.g., vulnerabilities in upstream GitHub Actions used by this project) should be reported to those upstream projects directly.

---

## Disclosure Policy

This project follows a **coordinated disclosure** model.  
Credit will be given to reporters in the release notes unless anonymity is requested.

---

*Maintained by Bazam Chekrian — Security Architect, Reddome*
