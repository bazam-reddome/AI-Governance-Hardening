#!/usr/bin/env bash
# =============================================================================
# aigov-preflight.sh — Verify the AI Endpoint Hardening Policy is in force
# Platforms: macOS, Linux
# Reports JSON to stdout; optionally posts to a SIEM webhook.
#
# Usage:
#   ./aigov-preflight.sh [--policy ./out/common/policy.json] [--webhook URL] [--quiet]
#
# Frameworks: NIST SSDF PS.2, NIST AI RMF MEASURE-4.1 (continuous monitoring),
#             ISO/IEC 42001:2023 A.6.2.8 (operational use)
# =============================================================================
set -uo pipefail

POLICY="${POLICY:-./out/common/policy.json}"
WEBHOOK="${WEBHOOK:-}"
QUIET=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --policy)  POLICY="$2"; shift 2;;
    --webhook) WEBHOOK="$2"; shift 2;;
    --quiet)   QUIET=1; shift;;
    -h|--help) cat <<'HELP'
aigov-preflight.sh — Verify the AI Endpoint Hardening Policy is in force.
  Platforms: macOS, Linux
  Reports JSON to stdout; optionally posts to a SIEM webhook.

Usage:
  aigov-preflight.sh [--policy <path>] [--webhook <url>] [--quiet]

Exit codes:
  0  all checks passed
  1  one or more warnings
  2  one or more failures
HELP
    exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

# ---------- helpers ----------
declare -a CHECKS_KEY CHECKS_NAME CHECKS_STATUS CHECKS_DETAIL CHECKS_SEVERITY

add_check() {
  CHECKS_KEY+=("$1")
  CHECKS_NAME+=("$2")
  CHECKS_STATUS+=("$3")
  CHECKS_DETAIL+=("$4")
  CHECKS_SEVERITY+=("$5")
}

json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().rstrip()))' <<< "$1"
}

OS_NAME="$(uname -s)"
HOSTNAME_FQDN="$(hostname -f 2>/dev/null || hostname)"
USER_NAME="${USER:-$(id -un)}"
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# ---------- 1. Policy file present + readable ----------
if [[ -f "$POLICY" ]]; then
  add_check "policy.present" "Policy file exists" "pass" "$POLICY" "info"
else
  add_check "policy.present" "Policy file exists" "fail" "Not found: $POLICY" "high"
fi

# ---------- 2. Working folder exists ----------
WORK_ROOT="${HOME}/ai-workspaces"
if [[ "$OS_NAME" == "Darwin" ]]; then
  WORK_ROOT="/Volumes/AIWorkspaces/ai-workspaces"
  [[ -d "$WORK_ROOT" ]] || WORK_ROOT="${HOME}/ai-workspaces"
fi
if [[ -d "$WORK_ROOT" ]]; then
  add_check "filesystem.working_root" "Working folder exists" "pass" "$WORK_ROOT" "info"
else
  add_check "filesystem.working_root" "Working folder exists" "fail" "Missing: $WORK_ROOT — create per the runbook" "high"
fi

# ---------- 3. Sensitive paths are NOT writable from the AI working dir context ----------
SENS_PATHS=("${HOME}/.ssh" "${HOME}/.aws" "${HOME}/.kube" "${HOME}/.config" "${HOME}/.gnupg")
SENS_DETAIL=""
for p in "${SENS_PATHS[@]}"; do
  if [[ -d "$p" ]]; then
    if [[ "$OS_NAME" == "Darwin" ]]; then
      perm=$(stat -f '%Sp' "$p" 2>/dev/null || echo "?")
    else
      perm=$(stat -c '%A' "$p" 2>/dev/null || echo "?")
    fi
    SENS_DETAIL="${SENS_DETAIL}${p} (${perm}); "
  fi
done
if [[ -n "$SENS_DETAIL" ]]; then
  add_check "filesystem.sensitive" "Sensitive credential dirs accounted for" "info" "${SENS_DETAIL%; }" "medium"
else
  add_check "filesystem.sensitive" "Sensitive credential dirs accounted for" "pass" "No standard credential dirs present" "info"
fi

# ---------- 4. Claude Code managed-settings.json present ----------
# Anthropic Claude Code's managed-policy file lives at a machine-wide path:
#   macOS:   /Library/Application Support/ClaudeCode/managed-settings.json
#   Linux:   /etc/claude-code/managed-settings.json
# (Claude Desktop uses a different mechanism; OS-level controls govern it.)
CLAUDE_CONFIG=""
if [[ "$OS_NAME" == "Darwin" ]]; then
  CLAUDE_CONFIG="/Library/Application Support/ClaudeCode/managed-settings.json"
elif [[ "$OS_NAME" == "Linux" ]]; then
  CLAUDE_CONFIG="/etc/claude-code/managed-settings.json"
fi
if [[ -n "$CLAUDE_CONFIG" ]]; then
  if [[ -f "$CLAUDE_CONFIG" ]]; then
    add_check "claude.managed_settings" "Claude Code managed-settings.json present" "pass" "$CLAUDE_CONFIG" "info"
  else
    add_check "claude.managed_settings" "Claude Code managed-settings.json present" "warn" "Not found at $CLAUDE_CONFIG (deploy via MDM)" "medium"
  fi
fi

# ---------- 6. Egress proxy / corporate proxy detected ----------
PROXY_DETECTED="${HTTPS_PROXY:-${https_proxy:-}}"
if [[ -n "$PROXY_DETECTED" ]]; then
  add_check "network.egress_proxy" "Outbound proxy configured" "pass" "$PROXY_DETECTED" "info"
else
  add_check "network.egress_proxy" "Outbound proxy configured" "warn" "HTTPS_PROXY not set; egress not inspected" "medium"
fi

# ---------- 7. SSH and Cloud creds not loaded into AI tool environment ----------
LEAK_VARS=()
for v in AWS_SECRET_ACCESS_KEY GITHUB_TOKEN ANTHROPIC_API_KEY OPENAI_API_KEY AZURE_CLIENT_SECRET; do
  if [[ -n "${!v:-}" ]]; then LEAK_VARS+=("$v"); fi
done
if [[ ${#LEAK_VARS[@]} -gt 0 ]]; then
  add_check "env.secrets_loaded" "Sensitive env vars not in shell" "warn" "Found in env: ${LEAK_VARS[*]}" "high"
else
  add_check "env.secrets_loaded" "Sensitive env vars not in shell" "pass" "No high-risk secrets in current env" "info"
fi

# ---------- 8. SIP / Gatekeeper / firejail ----------
if [[ "$OS_NAME" == "Darwin" ]]; then
  SIP="$(csrutil status 2>/dev/null | head -1)"
  if [[ "$SIP" == *"enabled"* ]]; then
    add_check "macos.sip" "macOS SIP enabled" "pass" "$SIP" "info"
  else
    add_check "macos.sip" "macOS SIP enabled" "fail" "$SIP" "high"
  fi
elif [[ "$OS_NAME" == "Linux" ]]; then
  if command -v firejail >/dev/null 2>&1; then
    add_check "linux.firejail" "firejail installed" "pass" "$(firejail --version | head -1)" "info"
  else
    add_check "linux.firejail" "firejail installed" "warn" "firejail not installed; AI CLI sandboxing limited" "medium"
  fi
fi

# ---------- 9. AI tool processes inventory ----------
PROCS="$(ps -eo comm 2>/dev/null | grep -Ei 'claude|cursor|codex|copilot' | sort -u | tr '\n' ',' | sed 's/,$//')"
if [[ -n "$PROCS" ]]; then
  add_check "inventory.ai_processes" "AI tools running" "info" "$PROCS" "info"
else
  add_check "inventory.ai_processes" "AI tools running" "info" "None detected" "info"
fi

# ---------- 10. Dev Drive (Windows-only — skip with N/A on this platform) ----------
add_check "windows.dev_drive" "Windows Dev Drive in use" "skip" "Not Windows — N/A" "info"

# ---------- emit JSON ----------
PASS=0; FAIL=0; WARN=0; SKIP=0
for s in "${CHECKS_STATUS[@]}"; do
  case "$s" in
    pass) PASS=$((PASS+1));;
    fail) FAIL=$((FAIL+1));;
    warn) WARN=$((WARN+1));;
    skip) SKIP=$((SKIP+1));;
  esac
done

OVERALL="pass"
[[ $WARN -gt 0 ]] && OVERALL="warn"
[[ $FAIL -gt 0 ]] && OVERALL="fail"

JSON_FILE="$(mktemp)"
{
  echo "{"
  echo "  \"timestamp\": \"$NOW\","
  echo "  \"hostname\": $(json_escape "$HOSTNAME_FQDN"),"
  echo "  \"user\": $(json_escape "$USER_NAME"),"
  echo "  \"os\": $(json_escape "$OS_NAME"),"
  echo "  \"policy_path\": $(json_escape "$POLICY"),"
  echo "  \"summary\": { \"overall\": \"$OVERALL\", \"pass\": $PASS, \"warn\": $WARN, \"fail\": $FAIL, \"skip\": $SKIP },"
  echo "  \"checks\": ["
  N=${#CHECKS_KEY[@]}
  for ((i=0; i<N; i++)); do
    sep=","; [[ $i -eq $((N-1)) ]] && sep=""
    echo "    {"
    echo "      \"key\": $(json_escape "${CHECKS_KEY[$i]}"),"
    echo "      \"name\": $(json_escape "${CHECKS_NAME[$i]}"),"
    echo "      \"status\": $(json_escape "${CHECKS_STATUS[$i]}"),"
    echo "      \"severity\": $(json_escape "${CHECKS_SEVERITY[$i]}"),"
    echo "      \"detail\": $(json_escape "${CHECKS_DETAIL[$i]}")"
    echo "    }$sep"
  done
  echo "  ]"
  echo "}"
} > "$JSON_FILE"

if [[ $QUIET -eq 0 ]]; then
  echo "AI Governance Pre-flight"
  echo "  host:    $HOSTNAME_FQDN"
  echo "  os:      $OS_NAME"
  echo "  user:    $USER_NAME"
  echo "  overall: $OVERALL  ($PASS pass / $WARN warn / $FAIL fail / $SKIP skip)"
  echo
  for ((i=0; i<${#CHECKS_KEY[@]}; i++)); do
    icon="  "
    case "${CHECKS_STATUS[$i]}" in
      pass) icon="\033[32m✓\033[0m";;
      warn) icon="\033[33m!\033[0m";;
      fail) icon="\033[31m✗\033[0m";;
      skip) icon="\033[90m·\033[0m";;
      info) icon="\033[34m·\033[0m";;
    esac
    printf "  %b %-32s %s\n" "$icon" "${CHECKS_NAME[$i]}" "${CHECKS_DETAIL[$i]}"
  done
  echo
  echo "JSON: $JSON_FILE"
fi

# ---------- POST to webhook (optional) ----------
if [[ -n "$WEBHOOK" ]]; then
  if command -v curl >/dev/null 2>&1; then
    if curl -s -f -X POST -H 'Content-Type: application/json' --data @"$JSON_FILE" "$WEBHOOK" >/dev/null; then
      [[ $QUIET -eq 0 ]] && echo "Posted to webhook: $WEBHOOK"
    else
      echo "WARN: failed to POST to $WEBHOOK (curl exit $?)" >&2
    fi
  else
    echo "WARN: curl unavailable; skipping webhook" >&2
  fi
fi

# Exit code: 0 pass, 1 warn, 2 fail
case "$OVERALL" in
  pass) exit 0;;
  warn) exit 1;;
  fail) exit 2;;
esac
