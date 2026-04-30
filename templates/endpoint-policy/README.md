# Endpoint Hardening Profile

Policy-as-code source of truth for AI coding-tool containment on developer endpoints.

## Files

| File | Purpose |
| --- | --- |
| `policy.yaml` | The source-of-truth policy. Edit this. |
| `policy.schema.json` | JSON Schema. Validates `policy.yaml` before emit. |
| `emit.py` | Generator that produces vendor-native enforcement files. |
| `out/` (after running `emit.py`) | Vendor configs ready to deploy via MDM / proxy / config management. |

## Workflow

```bash
# 1. Tailor policy.yaml — replace [Organization Name], adjust allow-lists.
# 2. Validate + emit
pip install pyyaml jsonschema
python3 emit.py --policy policy.yaml --out ./out
# 3. Deploy:
#    - claude/managed-settings.json — push via Intune / Jamf to the Claude Code
#      machine-wide policy path (verify against Anthropic's current docs):
#         macOS:   /Library/Application Support/ClaudeCode/managed-settings.json
#         Windows: C:\ProgramData\ClaudeCode\managed-settings.json
#         Linux:   /etc/claude-code/managed-settings.json
#      Claude Desktop uses a different mechanism — OS-level controls govern it.
#    - windows/applocker.xml — push via Intune Custom OMA-URI to
#      ./Vendor/MSFT/AppLocker/ApplicationLaunchRestrictions/...
#      (or for testing: Set-AppLockerPolicy -XmlPolicy applocker.xml -Merge)
#    - windows/network-allow-list.txt — import to Squid / Zscaler / corporate proxy
#    - macos/aigov-tcc.mobileconfig — REPLACE the CodeRequirement placeholders
#      with values captured via `codesign -dr - <app>`, then push via Jamf /
#      Mosyle / Intune (macOS Custom profile)
#    - linux/firejail-aigov.profile — drop in /etc/firejail/, wrap CLI tools
# 4. Verify with the pre-flight scripts (../scripts/aigov-preflight.{sh,ps1}).
```

## Frameworks referenced

- NIST AI RMF 1.0 — MANAGE-1.3, MANAGE-2.1
- ISO/IEC 42001:2023 — A.6.2.5, A.6.2.7, A.7.5
- ISO/IEC 5338:2023 — AI lifecycle (Operations)
- OWASP LLM Top 10 — LLM02 / LLM03 / LLM05 / LLM06
- OWASP ML Top 10 — ML06 (AI Supply Chain Attacks)
- MITRE ATLAS — Initial Access, Execution, Exfiltration
- MITRE D3FEND — Executable Allowlisting, Outbound Traffic Filtering, File Analysis (verify current technique IDs at d3fend.mitre.org)
- NIST SP 800-218 (SSDF) — PS.1, PS.2, PW.4
- NCSC / CISA Guidelines for Secure AI System Development (Nov 2023)

## Honest enforcement scope

| Layer | Direct enforcement? |
| --- | --- |
| Claude Code (managed policy) | **Yes** — via `managed-settings.json` deployed by MDM to the machine-wide Claude Code path. MCP allow-list lives in the same file (`enabledMcpjsonServers` / `disableAllMcpServers` / `allowListUrl`). Verify field names against current Anthropic docs. |
| Claude Desktop | **Indirect** — Claude Desktop does not consume `managed-settings.json` the same way Claude Code does; enforcement falls to OS-level controls (TCC profile + proxy egress) plus org-side admin-console settings on the Anthropic web tenant. |
| Windows app execution | **Yes** — AppLocker (or WDAC for stricter shops) enforces. Configure via Intune Custom profile pushing OMA-URI to `./Vendor/MSFT/AppLocker/...`. |
| Network egress | **Yes** — corporate proxy / SSE / firewall enforces, given that proxy bypass is blocked at the OS level. |
| macOS app sandbox | **Yes** — TCC mobileconfig (with valid CodeRequirement strings — see deploy step) + APFS sandbox volume. macOS 11+ silently ignores TCC entries without `CodeRequirement`. |
| Linux CLI containment | **Yes** — firejail wraps the binary; ensure firejail is installed before launching the AI tool. |
| ChatGPT / Cursor / Codex / Copilot CLI | **Partial** — these vendors do not (yet) document a managed-config schema. Enforcement falls to OS-level controls (TCC, AppLocker), proxy egress, and pre-flight detection of drift. |

The pre-flight script is the catch-all that reports drift to your SIEM regardless of the layer that failed. Treat it as the source of truth for endpoint health, not the individual configs.
