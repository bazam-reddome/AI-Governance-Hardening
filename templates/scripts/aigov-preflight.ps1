<#
.SYNOPSIS
  AI Governance Pre-flight check (Windows / PowerShell).

.DESCRIPTION
  Verifies the AI Endpoint Hardening Policy is in force on a Windows
  developer endpoint. Outputs JSON; optionally posts to a SIEM webhook.

.PARAMETER Policy
  Path to the canonical policy JSON (output of emit.py).

.PARAMETER Webhook
  Optional SIEM webhook URL.

.PARAMETER Quiet
  Suppress human-readable output. JSON file path is still printed.

.EXAMPLE
  .\aigov-preflight.ps1 -Policy .\out\common\policy.json
  .\aigov-preflight.ps1 -Webhook https://siem.example.com/ingest/aigov

.NOTES
  Frameworks: NIST SSDF PS.2, NIST AI RMF MEASURE-4.1 (continuous monitoring),
              ISO/IEC 42001:2023 A.6.2.8 (operational use).
#>
param(
  [string]$Policy = ".\out\common\policy.json",
  [string]$Webhook = "",
  [switch]$Quiet
)

$ErrorActionPreference = "SilentlyContinue"

$Checks = @()

function Add-Check([string]$Key, [string]$Name, [string]$Status, [string]$Detail, [string]$Severity = "info") {
  $script:Checks += [PSCustomObject]@{
    key      = $Key
    name     = $Name
    status   = $Status
    severity = $Severity
    detail   = $Detail
  }
}

# ---------- 1. Policy file present ----------
if (Test-Path $Policy) {
  Add-Check "policy.present" "Policy file exists" "pass" $Policy "info"
} else {
  Add-Check "policy.present" "Policy file exists" "fail" "Not found: $Policy" "high"
}

# ---------- 2. Dev Drive present ----------
$devDrives = Get-Volume 2>$null | Where-Object { $_.FileSystemType -eq "ReFS" -and $_.OperationalStatus -eq "OK" } | Select-Object -First 1
if ($devDrives) {
  Add-Check "windows.dev_drive" "Windows Dev Drive present" "pass" "$($devDrives.DriveLetter):\ (ReFS)" "info"
  $devRoot = "$($devDrives.DriveLetter):\ai-workspaces"
  if (Test-Path $devRoot) {
    Add-Check "filesystem.working_root" "Working folder on Dev Drive" "pass" $devRoot "info"
  } else {
    Add-Check "filesystem.working_root" "Working folder on Dev Drive" "warn" "Create $devRoot" "high"
  }
} else {
  Add-Check "windows.dev_drive" "Windows Dev Drive present" "warn" "No ReFS Dev Drive detected — see runbook" "high"
  Add-Check "filesystem.working_root" "Working folder configured" "skip" "Pending Dev Drive creation" "info"
}

# ---------- 3. AppLocker policy active ----------
try {
  $alSvc = Get-Service AppIDSvc -ErrorAction Stop
  if ($alSvc.Status -eq "Running") {
    Add-Check "windows.applocker_service" "AppLocker service running" "pass" "AppIDSvc Running" "info"
  } else {
    Add-Check "windows.applocker_service" "AppLocker service running" "fail" "AppIDSvc state: $($alSvc.Status)" "high"
  }
} catch {
  Add-Check "windows.applocker_service" "AppLocker service running" "warn" "AppIDSvc not present (Home edition?)" "medium"
}

# ---------- 4. Defender ASR rules ----------
try {
  $asr = (Get-MpPreference).AttackSurfaceReductionRules_Ids
  if ($asr -and $asr.Count -gt 0) {
    Add-Check "defender.asr_rules" "Defender ASR rules configured" "pass" "$($asr.Count) rules" "info"
  } else {
    Add-Check "defender.asr_rules" "Defender ASR rules configured" "warn" "No ASR rules — recommend enabling at least 'Block credential stealing from lsass'" "medium"
  }
} catch {
  Add-Check "defender.asr_rules" "Defender ASR rules configured" "skip" "Get-MpPreference unavailable" "info"
}

# ---------- 5. Claude Code managed-settings.json present ----------
# Machine-wide managed-policy path documented for Claude Code on Windows:
#   C:\ProgramData\ClaudeCode\managed-settings.json
# (Claude Desktop uses a different mechanism; OS-level controls govern it.)
$claudePath = Join-Path $env:ProgramData "ClaudeCode\managed-settings.json"
if (Test-Path $claudePath) {
  Add-Check "claude.managed_settings" "Claude Code managed-settings.json present" "pass" $claudePath "info"
} else {
  Add-Check "claude.managed_settings" "Claude Code managed-settings.json present" "warn" "Missing $claudePath (deploy via Intune)" "medium"
}

# ---------- 6. Egress proxy detected ----------
$proxy = $env:HTTPS_PROXY
if (-not $proxy) { $proxy = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyServer -ErrorAction SilentlyContinue).ProxyServer }
if ($proxy) {
  Add-Check "network.egress_proxy" "Outbound proxy configured" "pass" $proxy "info"
} else {
  Add-Check "network.egress_proxy" "Outbound proxy configured" "warn" "No proxy detected — egress not inspected" "medium"
}

# ---------- 7. BitLocker on system drive ----------
try {
  $sysDrive = $env:SystemDrive.TrimEnd(':')
  $bl = Get-BitLockerVolume -MountPoint "$sysDrive`:" -ErrorAction Stop
  if ($bl.ProtectionStatus -eq "On") {
    Add-Check "windows.bitlocker" "System drive encrypted" "pass" "BitLocker On" "info"
  } else {
    Add-Check "windows.bitlocker" "System drive encrypted" "fail" "BitLocker $($bl.ProtectionStatus)" "high"
  }
} catch {
  Add-Check "windows.bitlocker" "System drive encrypted" "skip" "Get-BitLockerVolume unavailable" "info"
}

# ---------- 8. Sensitive env vars not loaded ----------
$risky = @("AWS_SECRET_ACCESS_KEY","GITHUB_TOKEN","ANTHROPIC_API_KEY","OPENAI_API_KEY","AZURE_CLIENT_SECRET")
$leaks = $risky | Where-Object { [Environment]::GetEnvironmentVariable($_) }
if ($leaks) {
  Add-Check "env.secrets_loaded" "No secrets in shell env" "warn" "Found: $($leaks -join ', ')" "high"
} else {
  Add-Check "env.secrets_loaded" "No secrets in shell env" "pass" "Clean" "info"
}

# ---------- 9. AI tool processes inventory ----------
$proc = Get-Process | Where-Object { $_.ProcessName -match 'claude|cursor|codex|copilot' } | Select-Object -ExpandProperty ProcessName -Unique
if ($proc) {
  Add-Check "inventory.ai_processes" "AI tools running" "info" ($proc -join ", ") "info"
} else {
  Add-Check "inventory.ai_processes" "AI tools running" "info" "None detected" "info"
}

# ---------- summary ----------
$pass = ($Checks | Where-Object status -EQ pass).Count
$warn = ($Checks | Where-Object status -EQ warn).Count
$fail = ($Checks | Where-Object status -EQ fail).Count
$skip = ($Checks | Where-Object status -EQ skip).Count
$overall = "pass"
if ($warn -gt 0) { $overall = "warn" }
if ($fail -gt 0) { $overall = "fail" }

$report = [PSCustomObject]@{
  timestamp   = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  hostname    = $env:COMPUTERNAME
  user        = $env:USERNAME
  os          = "Windows"
  policy_path = $Policy
  summary     = [PSCustomObject]@{
    overall = $overall; pass = $pass; warn = $warn; fail = $fail; skip = $skip
  }
  checks      = $Checks
}

$json = $report | ConvertTo-Json -Depth 5
$jsonFile = Join-Path $env:TEMP "aigov-preflight-$(Get-Date -Format yyyyMMddHHmmss).json"
Set-Content -Path $jsonFile -Value $json -Encoding UTF8

if (-not $Quiet) {
  Write-Host "AI Governance Pre-flight"
  Write-Host "  host:    $($env:COMPUTERNAME)"
  Write-Host "  os:      Windows"
  Write-Host "  user:    $($env:USERNAME)"
  Write-Host "  overall: $overall  ($pass pass / $warn warn / $fail fail / $skip skip)"
  Write-Host
  foreach ($c in $Checks) {
    $icon = "  "
    switch ($c.status) {
      "pass" { $icon = "OK"; $color = "Green" }
      "warn" { $icon = "!!"; $color = "Yellow" }
      "fail" { $icon = "XX"; $color = "Red" }
      "skip" { $icon = "--"; $color = "Gray" }
      default { $icon = "..", $color = "Cyan" }
    }
    Write-Host ("  [{0}] {1,-32} {2}" -f $icon, $c.name, $c.detail) -ForegroundColor $color
  }
  Write-Host ""
  Write-Host "JSON: $jsonFile"
}

if ($Webhook) {
  try {
    Invoke-RestMethod -Method Post -Uri $Webhook -Body $json -ContentType "application/json" | Out-Null
    if (-not $Quiet) { Write-Host "Posted to webhook: $Webhook" -ForegroundColor Cyan }
  } catch {
    Write-Warning "Webhook POST failed: $_"
  }
}

switch ($overall) {
  "pass" { exit 0 }
  "warn" { exit 1 }
  "fail" { exit 2 }
}
