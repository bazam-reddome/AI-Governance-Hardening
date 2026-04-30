# Cursor — enterprise hardening

Cursor (the IDE, a fork of VS Code) does not ship a managed-config file that
an MDM admin can push to endpoints. Enforcement is layered:

## 1. Cursor admin panel (Cursor Business / Enterprise plan)

If your organisation is on a Cursor Business or Enterprise plan, log in to
the Cursor admin panel (typically at `cursor.com/admin` — verify the current
URL in your subscription email). From there you can set:

- Org-wide privacy mode (do-not-train / no-data-retention)
- Allowed model list
- SSO / SCIM bindings
- Audit log export to your SIEM (where supported)

For non-enterprise plans, the per-user privacy toggle in Cursor's settings
is the only vendor-side control — and it relies on the user not changing it.
Treat that as a soft control; enforce hard via the universal controls.

## 2. Per-repository — `.cursorrules`

Drop the `.cursorrules` file from this directory at the root of every
repository. Cursor reads it on every session and prepends its contents to
the AI agent's standing instructions (Composer, Cmd-K edits, agent mode).

Customise the "Project stack" section per repo.

## 3. Endpoint allow-listing — Cursor binary management

Add the Cursor binary to the approved AI-tool allow-list maintained by
`endpoint-policy/policy.yaml` → `scope.tools`. The TCC / AppLocker / firejail
emitters then include Cursor in the boundary configuration the same way they
include Claude Desktop and ChatGPT desktop.

The macOS bundle ID for Cursor is `com.todesktop.230313mzl4w4u92` (verify on
your fleet via `mdls -name kMDItemCFBundleIdentifier /Applications/Cursor.app`).

## 4. MCP allow-list — Cursor `mcp.json`

Cursor stores per-user MCP servers in `~/.cursor/mcp.json`. There is no
machine-wide path published for managed enterprise deployment today.
Practical options:

- **Document the allow-list publicly.** The org's allow-list URL is in
  `endpoint-policy/policy.yaml` under `mcp.allow_list_url` — surface it to
  developers in onboarding so they install only approved MCP servers.
- **Use the pre-flight script** to detect the presence of disallowed entries
  in `~/.cursor/mcp.json` and report drift to SIEM. (Add a check to
  `aigov-preflight.sh` that parses the file and compares against the
  allow-list — straightforward extension.)

## What this does NOT cover

The universal controls in `endpoint-policy/` cover everything else:

- Filesystem containment of the Cursor process (TCC on macOS, AppLocker on
  Windows).
- Network egress filtering (corporate proxy / SSE).
- Endpoint application allow-listing (only signed Cursor binary may run).
- Pre-flight verification (drift detection to SIEM).

## Tracked controls

The "Cursor" sheet of the AI Hardening Controls workbook is the single source
of truth for implementation status. Specifically:

| Control ID | What it covers |
| --- | --- |
| HRD-A01 / A02 / A04 | SSO/SCIM bindings, training opt-out, admin role separation |
| HRD-D01 | Repository `.cursorrules` enforcement |
| HRD-E01 | MCP server allow-list |
| HRD-G01 | Audit log export to SIEM |
| HRD-I01 / I03 / I04 / I05 | Endpoint allow-list, working folder, pre-flight, proxy egress |
| HRD-J01 | Agentic action defaults |
| HRD-L05 / L09 | PR peer review, AI co-author marker |
| HRD-M03 | Prompt-injection guard required when building LLM features |

## References

- Cursor `.cursorrules` documentation: cursor.com/docs (search "cursorrules")
- Cursor enterprise admin: cursor.com/business
