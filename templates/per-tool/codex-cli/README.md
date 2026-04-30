# OpenAI Codex CLI — enterprise hardening

OpenAI's `codex` CLI (open-source, github.com/openai/codex) does not ship a
documented managed-config file format that an MDM admin can push. The
config schema is also young and may change between releases — verify against
the current Codex CLI documentation before deploying any of the below.

## 1. OpenAI Enterprise admin

If your organisation is on an OpenAI Enterprise plan, the platform admin
console (platform.openai.com → Settings) gives you:

- API key issuance and rotation
- Per-project / per-user spending limits
- Allowed model list
- Audit log export
- Data residency / no-train guarantees in the contract
- SSO / SCIM bindings

API keys issued for Codex CLI users should be **per-user**, **scoped to a
single OpenAI project**, and **rotated on a documented cadence**. Do not
issue shared API keys.

## 2. Per-project — `.codex/instructions.md`

Drop a project-level instructions file at `.codex/instructions.md` in every
repository. The Codex CLI reads it on every session and treats its content
as standing instructions. The shape of this file mirrors the Cursor
`.cursorrules` and Copilot `.github/copilot-instructions.md` patterns —
copy `templates/per-tool/cursor/.cursorrules` as a starting point and rename
the trailer to `Co-Authored-By: OpenAI Codex CLI`.

## 3. Sandbox flag — Codex CLI's built-in OS sandbox

Codex CLI ships with a `--sandbox` flag (or equivalent — verify against the
current release) that constrains the agent's filesystem and shell access.
Document a wrapper script that always launches Codex with the flag enabled,
and place that wrapper in the corporate `$PATH` ahead of the raw binary so
developers can't accidentally launch unsandboxed.

## 4. Per-user `~/.codex/config.toml`

Codex CLI's per-user config lives at `~/.codex/config.toml`. There is no
documented machine-wide override path today. Treat this as soft per-user
config: developers can edit it. Use the pre-flight script to detect drift
from the org standard and report to SIEM.

## What this does NOT cover

The universal controls in `endpoint-policy/` cover the rest:

- Filesystem boundary enforced by the OS (firejail wrap on Linux, TCC profile
  on macOS, AppLocker on Windows).
- Network egress allow-list at the corporate proxy.
- Endpoint application allow-listing (only the signed Codex binary may run).

## Tracked controls

The "Codex CLI (OpenAI)" sheet of the AI Hardening Controls workbook is the
single source of truth for implementation status. Specifically:

| Control ID | What it covers |
| --- | --- |
| HRD-A01 / A02 / A05 | Org-bound API keys, no-training confirmation, key rotation |
| HRD-D01 | Sandbox / approval mode (never `--full-auto` outside an isolated container) |
| HRD-E02 | MCP server allow-list at config-file level |
| HRD-G01 | OpenAI Compliance API → SIEM |
| HRD-I01 / I03 / I04 / I05 | Endpoint allow-list, working folder, pre-flight, proxy egress |
| HRD-J01 | Agentic action defaults |
| HRD-L05 / L09 | PR peer review, AI co-author marker |

## References

- Codex CLI repository: github.com/openai/codex
- OpenAI platform admin: platform.openai.com
- OpenAI Enterprise privacy / no-train terms: openai.com/enterprise-privacy
