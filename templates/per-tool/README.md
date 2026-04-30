# Per-tool hardening — beyond Claude Code

The main `endpoint-policy/policy.yaml` flow generates a `managed-settings.json`
that Claude Code consumes when pushed via MDM. **No other AI coding tool
publishes a comparable managed-config file format today.** This directory
fills the gap with what each vendor *does* support.

## The honest enforcement matrix

| Tool | Vendor admin console | Per-repo / per-project drop-in | Per-user config (not for enterprise enforcement) |
| --- | --- | --- | --- |
| **Anthropic Claude Code** | docs.anthropic.com — IAM / managed-settings.json (machine-wide, MDM-deployable) | `.claude/settings.json` (repo-scoped) | `~/.claude/settings.json` |
| **GitHub Copilot** | GitHub Enterprise → Settings → Copilot → Policies; content exclusions via API | `.github/copilot-instructions.md` (drop-in here) | VS Code user settings |
| **Cursor** | Cursor admin panel (cursor.com, enterprise plan) | `.cursorrules` (drop-in here) | `~/.cursor/User/settings.json`, `~/.cursor/mcp.json` |
| **OpenAI Codex CLI** | OpenAI Enterprise admin (platform.openai.com) | `.codex/instructions.md` (project-level) | `~/.codex/config.toml` |
| **ChatGPT Desktop** | OpenAI Enterprise admin only — no file-based config | — | — |
| **M365 Copilot** | Microsoft 365 admin centre + Intune (Purview, DLP, sensitivity labels) | — | — |

## What still applies universally

The four **universal controls** in this kit work the same regardless of which
AI tool the developer is running. They are the actual cage; the per-tool
configs above are belt-and-braces.

1. **Filesystem boundary** — Dev Drive on Windows, APFS sandbox volume on
   macOS, firejail working directory on Linux. Enforced by AppLocker / TCC /
   firejail respectively. Documented in `endpoint-policy/`.
2. **Endpoint application allow-listing** — only approved AI desktop apps and
   browser extensions may run. Enforced by EDR / Defender ASR / Gatekeeper.
3. **Network egress allow-list** — corporate proxy / SSE only admits traffic
   to approved model APIs and registries. Documented in
   `endpoint-policy/policy.yaml`.
4. **Pre-flight verification** — `aigov-preflight.{sh,ps1}` reports drift to
   SIEM regardless of which AI tool is running. Tool-agnostic by design.

## When to use the per-tool drop-ins

| Subdirectory | Use when |
| --- | --- |
| `github-copilot/` | Your developers use Copilot in VS Code / JetBrains / CLI. Drop the `copilot-instructions.md` into every repo's `.github/` folder. |
| `cursor/` | Your developers use Cursor as an IDE. Drop `.cursorrules` at every repo root. |
| `codex-cli/` | Your developers use OpenAI's `codex` CLI. Drop the project-level instructions into `.codex/`. |
| `chatgpt-desktop/` | Your developers use the ChatGPT desktop app. There is no file to drop — it's all admin-console controls; the file in this folder is a checklist. |
