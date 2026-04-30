#!/usr/bin/env python3
"""
emit.py — Generate vendor-native enforcement files from policy.yaml.

Outputs (to ./out/):
  - claude/managed-settings.json          Anthropic Claude Desktop / Claude Code
  - claude/managed-mcp.json               Claude MCP allow-list
  - windows/applocker.xml                 Windows AppLocker import
  - windows/network-allow-list.txt        Squid/Zscaler URL filter list
  - macos/aigov-tcc.mobileconfig          macOS Configuration Profile (TCC)
  - linux/firejail-aigov.profile          Linux firejail profile
  - common/policy.json                    Canonical JSON for pre-flight scripts

Usage:
  python3 emit.py [--policy policy.yaml] [--out ./out]

Dependencies:
  pip install pyyaml jsonschema
"""
import argparse
import json
import os
import sys
import uuid
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML not installed. Run: pip install pyyaml", file=sys.stderr)
    sys.exit(1)

try:
    import jsonschema
    HAS_JSONSCHEMA = True
except ImportError:
    HAS_JSONSCHEMA = False


def load_policy(path: Path) -> dict:
    with open(path) as f:
        return yaml.safe_load(f)


def validate_policy(policy: dict, schema_path: Path) -> list:
    errors = []
    if not HAS_JSONSCHEMA:
        return ["jsonschema not installed; skipping schema validation (install with: pip install jsonschema)"]
    try:
        with open(schema_path) as f:
            schema = json.load(f)
        # Pick the best validator available in the installed jsonschema
        ValidatorCls = (
            getattr(jsonschema, "Draft202012Validator", None)
            or getattr(jsonschema, "Draft201909Validator", None)
            or getattr(jsonschema, "Draft7Validator", None)
        )
        if ValidatorCls is None:
            return ["No JSON Schema validator class found in jsonschema package"]
        validator = ValidatorCls(schema)
        for err in validator.iter_errors(policy):
            errors.append(f"{'.'.join(str(p) for p in err.absolute_path)}: {err.message}")
    except FileNotFoundError:
        errors.append(f"Schema not found at {schema_path}")
    return errors


def resolve_paths(paths, working_root, user_home_token="~"):
    """Substitute ${WORKING_ROOT} and ${USER_HOME} placeholders.
    `user_home_token` is what to expand ${USER_HOME} to — by default `~`,
    which Claude Code expands per-user on macOS / Linux. Pass
    `%USERPROFILE%` for Windows-bound emit. Substitutes *both* tokens so
    deny lists in the emitted config are not silently inert."""
    out_paths = []
    for p in paths:
        p2 = p.replace("${WORKING_ROOT}", working_root)
        p2 = p2.replace("${USER_HOME}", user_home_token)
        out_paths.append(p2)
    return out_paths


def emit_claude(policy: dict, out: Path):
    """Emit a managed-settings.json shaped for Anthropic Claude Code's managed-policy
    deployment. The shape below mirrors what Anthropic documents for enterprise
    policy at https://docs.anthropic.com/en/docs/claude-code (verify against the
    current docs before deploying — fields evolve).

    Deployment paths (Claude Code, machine-wide / managed):
      macOS:   /Library/Application Support/ClaudeCode/managed-settings.json
      Windows: C:\\ProgramData\\ClaudeCode\\managed-settings.json
      Linux:   /etc/claude-code/managed-settings.json

    Note: Claude Desktop uses a different mechanism (claude_desktop_config.json
    plus OS-level controls). MCP policy lives inside the same managed-settings
    file via enabledMcpjsonServers / disableAllMcpServers keys — there is no
    separate managed-mcp.json published by Anthropic.
    """
    spec = policy["spec"]
    # Pick a working root for substitution — generator caller can override
    working_root = spec["filesystem"].get("working_root_macos", "${WORKING_ROOT}")

    settings = {
        "_comment": (
            "Generated from " + policy["metadata"]["name"] +
            " v" + policy["metadata"]["version"] +
            ". Verify field names against the current Anthropic Claude Code "
            "enterprise policy documentation before deploying."
        ),
        "permissions": {
            "fileSystem": {
                "allow": resolve_paths(spec["filesystem"]["allow_paths"], working_root),
                # Substitute ${USER_HOME} → "~" so Claude Code (macOS/Linux)
                # expands it per-user. The deny list is otherwise inert.
                # Windows-only deployments should re-emit with user_home_token="%USERPROFILE%".
                "deny":  resolve_paths(spec["filesystem"]["deny_paths"], working_root),
            },
            "network": {
                "default": spec["network_egress"]["default"],
                "allowDomains": spec["network_egress"]["allow_domains"],
            },
            "execution": {
                "allowCommands": spec.get("execution", {}).get("bash_allow", []),
                "denyCommands":  spec.get("execution", {}).get("bash_deny", []),
                "requireConfirmation": spec.get("execution", {}).get("require_human_confirmation_for", []),
            },
        },
        "mcp": {
            "disableAllMcpServers": False,
            "enabledMcpjsonServers": [],   # populate after reviewing the allow-list URL
            "denyServers": spec["mcp"].get("deny_servers", []),
            "blockUnsigned": spec["mcp"].get("block_unsigned", True),
            "allowListUrl": spec["mcp"].get("allow_list_url", ""),
        },
        "scheduledTasks": {
            "enabled": spec.get("scheduled_tasks", {}).get("enabled", False),
        },
        "telemetry": {
            "openTelemetryEndpoint": spec.get("logging", {}).get("otel_collector_endpoint", ""),
            "events": spec.get("logging", {}).get("forward_events", []),
        },
        "identity": {
            "requireSSO": spec.get("identity", {}).get("require_sso", True),
            "denyPersonalAccounts": spec.get("identity", {}).get("deny_personal_accounts", True),
        },
        "_meta": {
            "policyName": policy["metadata"]["name"],
            "policyVersion": policy["metadata"]["version"],
            "owner": policy["metadata"]["owner"],
        },
    }
    (out / "claude").mkdir(parents=True, exist_ok=True)
    with open(out / "claude" / "managed-settings.json", "w") as f:
        json.dump(settings, f, indent=2)


def emit_applocker(policy: dict, out: Path):
    """Emit Windows AppLocker policy XML — restricts AI tool execution to working folder.
    NOTE: AppLocker is configured in Intune via Devices → Configuration → Custom
    profile pushing OMA-URI ./Vendor/MSFT/AppLocker/ApplicationLaunchRestrictions/.
    The XML emitted here is the inner RuleCollection content, ready to wrap."""
    spec = policy["spec"]
    work_root = spec["filesystem"].get("working_root_windows", "%USERPROFILE%\\ai-workspaces")

    # Filter to Windows-relevant deny paths only:
    #   - Windows-style paths (start with C:, D:, etc.)
    #   - User-home placeholders (the consuming policy substitutes %USERPROFILE%)
    # Skip POSIX-only paths (they would emit meaningless rules on Windows).
    deny_locations = []
    for p in spec["filesystem"]["deny_paths"]:
        if p.startswith("C:") or p.startswith("D:") or p.startswith("%"):
            deny_locations.append(p.replace("/", "\\"))
        elif p.startswith("${USER_HOME}"):
            # Map to %USERPROFILE% for AppLocker
            deny_locations.append(p.replace("${USER_HOME}", "%USERPROFILE%").replace("/", "\\"))
        # Skip /etc, /var, /Library, etc. — these are macOS/Linux-only

    rules = []
    for tool in spec["scope"]["tools"]:
        if "windows" not in tool["platforms"]:
            continue
        rules.append(f'''      <FilePathRule Id="{uuid.uuid4()}" Name="Allow {tool["name"]} in working root" Description="Permit {tool["name"]} from Dev Drive only" UserOrGroupSid="S-1-1-0" Action="Allow">
        <Conditions><FilePathCondition Path="{work_root}\\*" /></Conditions>
      </FilePathRule>''')

    deny_rules = []
    for path in deny_locations[:20]:
        deny_rules.append(f'''      <FilePathRule Id="{uuid.uuid4()}" Name="Deny AI tools in {path}" UserOrGroupSid="S-1-1-0" Action="Deny">
        <Conditions><FilePathCondition Path="{path}\\*" /></Conditions>
      </FilePathRule>''')

    xml = f'''<?xml version="1.0" encoding="utf-8"?>
<!--
  AppLocker policy generated from {policy["metadata"]["name"]} v{policy["metadata"]["version"]}.
  Import via: Set-AppLockerPolicy -XmlPolicy applocker.xml -Merge
  Or via Intune: Devices > Configuration > Endpoint protection > Application control.
-->
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="Enabled">
{chr(10).join(rules)}
{chr(10).join(deny_rules)}
  </RuleCollection>
  <RuleCollection Type="Script" EnforcementMode="AuditOnly">
    <FilePathRule Id="{uuid.uuid4()}" Name="Allow scripts in working root" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions><FilePathCondition Path="{work_root}\\*" /></Conditions>
    </FilePathRule>
  </RuleCollection>
</AppLockerPolicy>
'''
    (out / "windows").mkdir(parents=True, exist_ok=True)
    with open(out / "windows" / "applocker.xml", "w") as f:
        f.write(xml)


def emit_network_allowlist(policy: dict, out: Path):
    """Emit a flat URL allow-list for Squid / Zscaler / corporate proxy import."""
    spec = policy["spec"]
    domains = spec["network_egress"]["allow_domains"]
    txt = "# AI tool egress allow-list\n"
    txt += f"# Generated from {policy['metadata']['name']} v{policy['metadata']['version']}\n"
    txt += f"# Owner: {policy['metadata']['owner']}\n"
    txt += "# Default = deny. Admit only:\n\n"
    for d in domains:
        txt += f"{d}\n"
    (out / "windows").mkdir(parents=True, exist_ok=True)
    with open(out / "windows" / "network-allow-list.txt", "w") as f:
        f.write(txt)


def emit_macos_tcc(policy: dict, out: Path):
    """Emit a macOS Configuration Profile that scopes TCC for AI apps.

    IMPORTANT: macOS 11+ requires a CodeRequirement designated requirement
    string in TCC profile entries; without it the entry is ignored. The placeholder
    requirement strings below MUST be replaced with the actual designated
    requirements captured via:
        codesign -dr - /Applications/Claude.app
    The script that deploys this profile should be modified to substitute the
    captured CodeRequirement string into each entry below.
    """
    spec = policy["spec"]
    profile_uuid = str(uuid.uuid4()).upper()
    payload_uuid = str(uuid.uuid4()).upper()

    # Default placeholder CodeRequirement — admins replace with the real one
    # captured via `codesign -dr - <app>`. Keeping a marker so it's obvious.
    CR_PLACEHOLDER = "__REPLACE_WITH_CODESIGN_DESIGNATED_REQUIREMENT__"

    # AI tools to include — taken from policy.scope.tools, mapped to common bundle IDs
    bundle_id_map = {
        "claude-desktop":      "com.anthropic.claudefordesktop",
        "claude-code":         "com.anthropic.claudecode",
        "chatgpt-desktop":     "com.openai.chat",
        "cursor":              "com.todesktop.230313mzl4w4u92",
        "github-copilot-cli":  "com.github.copilot",
        "codex-cli":           "com.openai.codex",
    }
    tools_in_scope = []
    for t in spec.get("scope", {}).get("tools", []):
        if "macos" in t.get("platforms", []):
            bid = bundle_id_map.get(t["name"])
            if bid:
                tools_in_scope.append((t["name"], bid))

    if not tools_in_scope:
        # Fallback to Claude Desktop only if no scope match
        tools_in_scope = [("claude-desktop", "com.anthropic.claudefordesktop")]

    def entries_for_service(comment_text=""):
        """Generate <dict> entries for each tool-in-scope, set to Allowed=false."""
        out_lines = []
        for tool_name, bid in tools_in_scope:
            out_lines.append(f'''          <dict>
            <key>Identifier</key><string>{bid}</string>
            <key>IdentifierType</key><string>bundleID</string>
            <key>CodeRequirement</key><string>{CR_PLACEHOLDER}</string>
            <key>Allowed</key><false/>
            <key>Comment</key><string>{comment_text} ({tool_name})</string>
          </dict>''')
        return "\n".join(out_lines)

    plist = f'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!--
  macOS Configuration Profile — Privacy Preferences Policy Control (TCC).
  Generated from {policy["metadata"]["name"]} v{policy["metadata"]["version"]}.

  Deploys via Jamf Pro, Mosyle, Kandji, or Microsoft Intune (macOS Custom profile).
  Effect: AI desktop tools are denied access to Documents, Desktop, Downloads,
  and full-disk; they may only see the sandbox volume the org provisioned.

  REQUIRED before deploy: replace every "{CR_PLACEHOLDER}"
  with the actual codesign designated requirement for that bundle ID:
      codesign -dr - /Applications/Claude.app    # capture the requirement string
  Without a valid CodeRequirement, macOS 11+ will silently ignore TCC entries.

  Bundle IDs used here are best-effort defaults; verify on your fleet via:
      mdls -name kMDItemCFBundleIdentifier /Applications/<App>.app
-->
<plist version="1.0">
<dict>
  <key>PayloadDisplayName</key><string>AI Endpoint Containment</string>
  <key>PayloadIdentifier</key><string>com.aigov.endpoint.containment</string>
  <key>PayloadType</key><string>Configuration</string>
  <key>PayloadUUID</key><string>{profile_uuid}</string>
  <key>PayloadVersion</key><integer>1</integer>
  <key>PayloadOrganization</key><string>{policy["metadata"]["owner"]}</string>
  <key>PayloadContent</key>
  <array>
    <dict>
      <key>PayloadType</key><string>com.apple.TCC.configuration-profile-policy</string>
      <key>PayloadIdentifier</key><string>com.aigov.endpoint.tcc</string>
      <key>PayloadUUID</key><string>{payload_uuid}</string>
      <key>PayloadVersion</key><integer>1</integer>
      <key>PayloadDisplayName</key><string>TCC: AI Tool Containment</string>
      <key>Services</key>
      <dict>
        <key>SystemPolicyAllFiles</key>
        <array>
{entries_for_service("Deny full-disk access")}
        </array>
        <key>SystemPolicyDocumentsFolder</key>
        <array>
{entries_for_service("Deny Documents")}
        </array>
        <key>SystemPolicyDesktopFolder</key>
        <array>
{entries_for_service("Deny Desktop")}
        </array>
        <key>SystemPolicyDownloadsFolder</key>
        <array>
{entries_for_service("Deny Downloads")}
        </array>
      </dict>
    </dict>
  </array>
</dict>
</plist>
'''
    (out / "macos").mkdir(parents=True, exist_ok=True)
    with open(out / "macos" / "aigov-tcc.mobileconfig", "w") as f:
        f.write(plist)


def emit_firejail(policy: dict, out: Path):
    """Emit a Linux firejail profile for AI CLI tools."""
    spec = policy["spec"]
    deny = spec["filesystem"]["deny_paths"]
    blacklist = "\n".join(f"blacklist {p.replace('${USER_HOME}', '${HOME}')}" for p in deny if not p.startswith("C:"))
    profile = f'''# firejail profile for AI CLI tools (Claude Code, Codex CLI, Copilot CLI)
# Generated from {policy["metadata"]["name"]} v{policy["metadata"]["version"]}
# Place at /etc/firejail/aigov.profile and invoke with:
#   firejail --profile=/etc/firejail/aigov.profile claude

include disable-common.inc
include disable-programs.inc

caps.drop all
seccomp
nonewprivs
noroot

# Deny dangerous paths
{blacklist}

# Allow only the working folder
whitelist ${{HOME}}/ai-workspaces
read-only ${{HOME}}

# Network: route through proxy only (configure proxy at OS level)
protocol unix,inet,inet6
'''
    (out / "linux").mkdir(parents=True, exist_ok=True)
    with open(out / "linux" / "firejail-aigov.profile", "w") as f:
        f.write(profile)


def emit_canonical_json(policy: dict, out: Path):
    """Emit canonical JSON for the pre-flight scripts to consume."""
    (out / "common").mkdir(parents=True, exist_ok=True)
    with open(out / "common" / "policy.json", "w") as f:
        json.dump(policy, f, indent=2)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--policy", default="policy.yaml", help="Path to policy.yaml")
    ap.add_argument("--schema", default="policy.schema.json", help="Path to policy.schema.json")
    ap.add_argument("--out", default="./out", help="Output directory")
    ap.add_argument("--no-validate", action="store_true", help="Skip schema validation")
    args = ap.parse_args()

    policy_path = Path(args.policy)
    schema_path = Path(args.schema)
    out_path = Path(args.out)

    print(f"Loading policy: {policy_path}")
    policy = load_policy(policy_path)

    if not args.no_validate:
        print(f"Validating against: {schema_path}")
        errors = validate_policy(policy, schema_path)
        if errors:
            print("VALIDATION ISSUES:")
            for e in errors:
                print(f"  - {e}")
            if any("jsonschema not installed" not in e for e in errors):
                sys.exit(2)
        else:
            print("  Policy is valid.")

    print(f"\nEmitting to: {out_path}")
    emit_claude(policy, out_path)
    print("  + claude/managed-settings.json (Claude Code enterprise policy shape)")
    emit_applocker(policy, out_path)
    print("  + windows/applocker.xml")
    emit_network_allowlist(policy, out_path)
    print("  + windows/network-allow-list.txt")
    emit_macos_tcc(policy, out_path)
    print("  + macos/aigov-tcc.mobileconfig")
    emit_firejail(policy, out_path)
    print("  + linux/firejail-aigov.profile")
    emit_canonical_json(policy, out_path)
    print("  + common/policy.json")
    print("\nDone. Review outputs and deploy via your MDM / proxy / config-management tooling.")


if __name__ == "__main__":
    main()
