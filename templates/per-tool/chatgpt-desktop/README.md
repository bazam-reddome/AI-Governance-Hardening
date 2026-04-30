# ChatGPT Desktop — enterprise hardening

The ChatGPT desktop app (macOS / Windows) does not expose a managed-config
file. There is no `.json` or `.plist` an MDM admin can push to control its
behaviour. Enforcement is **entirely** vendor admin + OS-level + proxy.

This file is therefore a **checklist**, not a drop-in config.

## 1. OpenAI Enterprise admin (web)

The canonical place for ChatGPT controls is the OpenAI workspace admin at
**chatgpt.com/admin** (verify the current URL in your subscription email).
Configure:

- [ ] **Workspace bound to corporate IdP** — SSO via SAML / OIDC
- [ ] **MFA enforced** — phishing-resistant where the IdP supports it
- [ ] **SCIM provisioning live** — leavers deprovisioned within 24h
- [ ] **Connectors** — disable all unused; tighten scopes on the rest
- [ ] **GPTs (custom)** — disable user creation if scope is unbounded;
       restrict GPT Store access
- [ ] **Compliance API enabled** — pull conversation, file and admin events
       to your SIEM
- [ ] **Workspace data isolation** — confirmed in workspace settings
- [ ] **Training opt-out** — confirm "data not used for training" is set
- [ ] **Region pinning** — set if available and aligned to regulatory footprint
- [ ] **Plugins / Apps** — restrict to allow-listed list
- [ ] **Browser-use (Atlas / agent mode)** — disable for general users
       or restrict to non-sensitive use cases

The corresponding hardening checklist row on the **ChatGPT (OpenAI)** sheet
of the Hardening workbook tracks each of these for ongoing review.

## 2. Endpoint application allow-listing

The ChatGPT desktop app should only run on managed devices, signed by
OpenAI. Add it to:

- macOS: **TCC profile** (deny Documents / Desktop / Downloads access). The
   `endpoint-policy/policy.yaml` → `scope.tools` already lists it as
   `chatgpt-desktop`.
- Windows: **AppLocker** rule allowing the signed binary from the standard
   install path; deny binaries copied to `%USERPROFILE%`.

## 3. Network egress

ChatGPT desktop traffic should pass through the corporate proxy / SSE.
Enforce egress to `chatgpt.com`, `api.openai.com`, `cdn.openai.com`,
`models.cdn.openai.com` only. Block other outbound from the binary.

## 4. Pre-flight verification

The pre-flight script reports whether the ChatGPT desktop process is running
on the endpoint and forwards the inventory to SIEM. There is nothing more
to verify on disk because there is no on-disk config to inspect.

## What this does NOT cover

There is no equivalent to Claude Code's `managed-settings.json` for ChatGPT
desktop. If your threat model requires file-level enforcement of model
behaviour on the endpoint, ChatGPT desktop is not the right tool — Claude
Code is.

## Tracked controls

The "ChatGPT Desktop" sheet of the AI Hardening Controls workbook is the
single source of truth for implementation status. Specifically:

| Control ID | What it covers |
| --- | --- |
| HRD-A01 / A02 | Workspace SSO/SCIM, training opt-out, data isolation |
| HRD-A04 / A05 | Admin role separation, connector + GPT controls |
| HRD-B03 | Browser-use / Atlas / agent-mode restriction |
| HRD-G01 | Compliance API → SIEM |
| HRD-I01 / I03 / I04 / I05 | Endpoint allow-list, working folder, pre-flight, proxy egress |
| HRD-J01 | Agentic action defaults |
| HRD-K01 | AUP acknowledgement |

## References

- OpenAI Enterprise privacy: openai.com/enterprise-privacy
- OpenAI workspace admin docs: help.openai.com (search "workspace admin")
- Compliance API: platform.openai.com/docs/api-reference/compliance
