# GitHub Copilot — enterprise hardening

GitHub Copilot does not ship a managed-config file format that an MDM admin
can push to endpoints. Enforcement happens in three places:

## 1. GitHub Enterprise Cloud — org admin policies

Navigate to your organisation: **Settings → Copilot → Policies**. Set the
following minimums:

| Policy | Recommended value | Why |
| --- | --- | --- |
| Suggestions matching public code | **Block** | Reduces IP / licence-leak risk |
| Allow IP indexing | **Disabled** unless required | Limits data sharing with vendor |
| Telemetry / data collection | **Minimum** the contract requires | Limits prompt / output retention |
| Allowed Copilot Chat models | Pin to vendor-approved list | Avoids unverified models |
| Copilot Cloud Agent | **Disabled by default** — opt-in per repo | Cloud Agent runs in a GitHub VM with autonomous tool calls |

For Copilot Business / Enterprise: also configure **Content Exclusions** at
the organisation level to keep certain repo paths (secrets, customer data,
proprietary IP) out of Copilot's training and indexing scope.

## 2. Per-repository — `.github/copilot-instructions.md`

Drop the file from this directory at `.github/copilot-instructions.md` in
every repository. Copilot Chat reads it and prepends it to every session
inside that repo. Customise the stack-specific guidance section per repo.

This is the closest thing to "global system prompt" Copilot supports today.

## 3. Repository branch protection — Cloud Agent gating

If you allow Cloud Agent / agent-mode at all:

- **Require a non-bot reviewer** on every PR via branch protection.
- **CODEOWNERS** must include a human team for the touched paths.
- **Required status checks** include the AI-app gates workflow
  (`templates/ci/ai-app-gates.yml` from this kit).
- **Restrict who can dismiss pull request reviews** and who can push to
  the protected branch.
- Set **auto-merge: disabled** for any PR opened by `github-actions[bot]`,
  `github-copilot[bot]`, or any service account that proxies the agent.

## What this does NOT cover

- File-system containment of the Copilot CLI / IDE binary — that's the
  universal Dev Drive / TCC / firejail story in `endpoint-policy/`.
- Network egress filtering — that's the corporate proxy / SSE story in
  `endpoint-policy/policy.yaml` and `network-allow-list.txt`.
- Endpoint application allow-listing — that's the EDR / Defender ASR story
  in the AppLocker XML or the macOS profile.

The four universal controls plus the three Copilot-specific controls above
together give you a defensible posture.

## Tracked controls

The "GitHub Copilot" sheet of the AI Hardening Controls workbook is the single
source of truth for implementation status. Specifically:

| Control ID | What it covers |
| --- | --- |
| HRD-A01 / A02 | Enterprise SSO/SCIM, no-training opt-in via Business / Enterprise plan |
| HRD-A04 | Admin role separation |
| HRD-D01 | Repository `.github/copilot-instructions.md` enforcement |
| HRD-E01 | Allowed list of registries the Copilot agent / CLI may reach |
| HRD-G01 | Copilot audit log → SIEM |
| HRD-I01 / I03 / I04 / I05 | Endpoint allow-list, working folder, pre-flight, proxy egress |
| HRD-J01 | Agentic action defaults |
| HRD-L05 / L09 | PR peer review (Copilot-authored PRs detected via co-author marker), AI co-author marker |

## References

- GitHub docs — Configuring GitHub Copilot in your environment:
  https://docs.github.com/en/copilot
- `.github/copilot-instructions.md` reference (Copilot custom instructions):
  https://docs.github.com/en/copilot/customizing-copilot
- Copilot content exclusions API:
  https://docs.github.com/en/copilot/managing-copilot-business
