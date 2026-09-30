<#
.SYNOPSIS
  Installs OmniRoute on Windows and points Claude Code at it.

.DESCRIPTION
  1. Checks Node.js (OmniRoute needs >=22.22.2 <23, or 24.x-26.x); installs Node LTS with winget if needed.
  2. Installs OmniRoute globally with npm.
  3. Starts OmniRoute in its own window and waits for http://localhost:20128.
  4. Opens the dashboard so you can connect a provider and copy your API key.
  5. Verifies the key against /v1/models.
  6. Writes ANTHROPIC_BASE_URL / ANTHROPIC_AUTH_TOKEN into Claude Code settings.

.PARAMETER Scope
  Project (default): writes <repo>\.claude\settings.local.json (git-ignored).
  User: writes %USERPROFILE%\.claude\settings.json (all projects).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\setup-omniroute.ps1
  powershell -ExecutionPolicy Bypass -File scripts\setup-omniroute.ps1 -Scope User
#>
param(
    [ValidateSet('Project', 'User')]
    [string]$Scope = 'Project'
)

$ErrorActionPreference = 'Stop'
$BaseUrl = 'http://localhost:20128'

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "    $msg" -ForegroundColor Green }
function Write-Warn2($msg) { Write-Host "    $msg" -ForegroundColor Yellow }

function Update-SessionPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
}

function Test-NodeVersionOk {
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) { return $false }
    $raw = (& node -v).Trim().TrimStart('v')
    $v = [version]$raw
    if ($v.Major -eq 22) { return ($v -ge [version]'22.22.2') }
    return ($v.Major -ge 24 -and $v.Major -le 26)
}

function Test-OmniRouteUp {
    try {
        Invoke-WebRequest -Uri $BaseUrl -UseBasicParsing -TimeoutSec 3 | Out-Null
        return $true
    } catch {
        # Any HTTP response (even 401/404) means the server is listening.
        return ($null -ne $_.Exception.Response)
    }
}

# 1. Node.js ---------------------------------------------------------------
Write-Step 'Checking Node.js'
if (Test-NodeVersionOk) {
    Write-Ok "Node $(& node -v) is supported."
} else {
    if (Get-Command node -ErrorAction SilentlyContinue) {
        Write-Warn2 "Node $(& node -v) is not supported by OmniRoute (needs 22.22.2+ on 22.x, or 24-26)."
    } else {
        Write-Warn2 'Node.js is not installed.'
    }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget not found. Install Node.js 24 LTS from https://nodejs.org, then run this script again.'
    }
    Write-Ok 'Installing Node.js LTS with winget (accept any prompts)...'
    winget install -e --id OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
    Update-SessionPath
    if (-not (Test-NodeVersionOk)) {
        throw 'Node.js still not usable. Close this window, open a new PowerShell and run the script again.'
    }
    Write-Ok "Node $(& node -v) installed."
}

# 2. OmniRoute -------------------------------------------------------------
Write-Step 'Installing OmniRoute (npm install -g omniroute)'
& npm install -g omniroute
if ($LASTEXITCODE -ne 0) { throw 'npm install -g omniroute failed. See the output above.' }
Update-SessionPath
Write-Ok 'OmniRoute installed.'

# 3. Start server ----------------------------------------------------------
Write-Step "Starting OmniRoute on $BaseUrl"
if (Test-OmniRouteUp) {
    Write-Ok 'OmniRoute is already running.'
} else {
    Start-Process -FilePath 'cmd.exe' -ArgumentList '/k', 'title OmniRoute && omniroute'
    Write-Ok 'Started in a new window (keep that window open while you work).'
    $deadline = (Get-Date).AddSeconds(90)
    while (-not (Test-OmniRouteUp)) {
        if ((Get-Date) -gt $deadline) { throw "OmniRoute did not respond on $BaseUrl within 90 seconds. Check the OmniRoute window for errors." }
        Start-Sleep -Seconds 2
    }
    Write-Ok 'OmniRoute is up.'
}

# 4. Dashboard: provider + key --------------------------------------------
Write-Step 'Connect a provider and copy your API key'
Start-Process $BaseUrl
Write-Host @"
    The dashboard just opened in your browser.
      a) Go to Providers and connect at least one provider
         (free options such as OpenCode Free or Kilo AI need no signup).
      b) Go to Dashboard -> Endpoints (or API Manager) and copy your API key.
"@

$key = $null
while (-not $key) {
    $secure = Read-Host '    Paste your OmniRoute API key (input hidden)' -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { $candidate = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr).Trim() }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    if (-not $candidate) { Write-Warn2 'Empty key, try again.'; continue }

    # 5. Verify key ----------------------------------------------------------
    try {
        $resp = Invoke-RestMethod -Uri "$BaseUrl/v1/models" -Headers @{ Authorization = "Bearer $candidate" } -TimeoutSec 15
        $count = @($resp.data).Count
        if ($count -eq 0) {
            Write-Warn2 'Key accepted, but no models are listed. Connect a provider in the dashboard, then paste the key again.'
            continue
        }
        Write-Ok "Key works. $count model(s) available."
        $key = $candidate
    } catch {
        Write-Warn2 "Key check failed: $($_.Exception.Message)"
        Write-Warn2 'Make sure you copied the full key, then try again.'
    }
}

# 6. Claude Code settings --------------------------------------------------
Write-Step "Writing Claude Code settings ($Scope scope)"
if ($Scope -eq 'User') {
    $settingsPath = Join-Path $env:USERPROFILE '.claude\settings.json'
} else {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $settingsPath = Join-Path $repoRoot '.claude\settings.local.json'
}
$dir = Split-Path -Parent $settingsPath
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

$settings = $null
if (Test-Path $settingsPath) {
    Copy-Item $settingsPath "$settingsPath.bak" -Force
    Write-Ok "Backed up existing file to $settingsPath.bak"
    $raw = Get-Content $settingsPath -Raw
    if ($raw -and $raw.Trim()) { $settings = $raw | ConvertFrom-Json }
}
if (-not $settings) { $settings = [pscustomobject]@{} }
if (-not ($settings.PSObject.Properties.Name -contains 'env') -or -not $settings.env) {
    $settings | Add-Member -NotePropertyName env -NotePropertyValue ([pscustomobject]@{}) -Force
}
# No /v1 here: Claude Code appends /v1/messages itself.
$settings.env | Add-Member -NotePropertyName ANTHROPIC_BASE_URL -NotePropertyValue $BaseUrl -Force
$settings.env | Add-Member -NotePropertyName ANTHROPIC_AUTH_TOKEN -NotePropertyValue $key -Force

$json = $settings | ConvertTo-Json -Depth 20
[IO.File]::WriteAllText($settingsPath, $json, (New-Object Text.UTF8Encoding $false))
Write-Ok "Saved $settingsPath"

# Done ---------------------------------------------------------------------
Write-Step 'All set'
Write-Host @"
    Next:
      - Keep the OmniRoute window open (or run 'omniroute' again after a reboot).
      - Restart Claude Code, then test with:   claude "say hello"
"@
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Warn2 "Claude Code ('claude') was not found on PATH. Install it first: npm install -g @anthropic-ai/claude-code"
}
