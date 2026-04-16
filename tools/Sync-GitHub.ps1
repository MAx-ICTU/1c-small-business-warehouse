param(
    [string]$Message,
    [string]$RemoteName = "origin",
    [string]$RemoteUrl = "",
    [string]$Branch = "",
    [switch]$NoPush
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-GitExe {
    $candidates = @(
        "C:\Program Files\Git\cmd\git.exe",
        "C:\Program Files\Git\bin\git.exe"
    )
    foreach ($path in $candidates) {
        if (Test-Path -LiteralPath $path) {
            return $path
        }
    }
    throw "git.exe not found. Install Git first."
}

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Args,
        [switch]$AllowFail
    )

    $git = Get-GitExe
    & $git @Args
    if (-not $AllowFail -and $LASTEXITCODE -ne 0) {
        throw "Git command failed: git $($Args -join ' ')"
    }
    return $LASTEXITCODE
}

function Test-GitRemoteExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RemoteName
    )

    $git = Get-GitExe
    & $git remote get-url $RemoteName | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Get-GitConfigValue {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Args
    )

    $git = Get-GitExe
    $output = & $git @Args
    if ($LASTEXITCODE -ne 0 -or $null -eq $output) {
        return ""
    }
    return ([string]$output).Trim()
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $repoRoot
Set-Location $repoRoot

if (-not (Test-Path -LiteralPath (Join-Path $repoRoot ".git"))) {
    [void](Invoke-Git -Args @("init", "-b", "main"))
}

$name = Get-GitConfigValue -Args @("config", "--global", "--get", "user.name")
$email = Get-GitConfigValue -Args @("config", "--global", "--get", "user.email")

if ([string]::IsNullOrWhiteSpace($name)) {
    [void](Invoke-Git -Args @("config", "--local", "user.name", "MAx-ICTU"))
}
if ([string]::IsNullOrWhiteSpace($email)) {
    [void](Invoke-Git -Args @("config", "--local", "user.email", "80310916+MAx-ICTU@users.noreply.github.com"))
}

if (-not [string]::IsNullOrWhiteSpace($RemoteUrl)) {
    $hasRemote = Test-GitRemoteExists -RemoteName $RemoteName
    if (-not $hasRemote) {
        [void](Invoke-Git -Args @("remote", "add", $RemoteName, $RemoteUrl))
    } else {
        [void](Invoke-Git -Args @("remote", "set-url", $RemoteName, $RemoteUrl))
    }
}

[void](Invoke-Git -Args @("add", "-A"))

& (Get-GitExe) diff --cached --quiet
$hasStagedChanges = $LASTEXITCODE -ne 0

if ($hasStagedChanges) {
    if ([string]::IsNullOrWhiteSpace($Message)) {
        $Message = "chore: auto sync $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    }
    [void](Invoke-Git -Args @("commit", "-m", $Message))
} else {
    Write-Host "No staged changes. Nothing to commit."
}

if ($NoPush) {
    Write-Host "Push skipped by -NoPush."
    exit 0
}

if ([string]::IsNullOrWhiteSpace($Branch)) {
    $Branch = (& (Get-GitExe) rev-parse --abbrev-ref HEAD).Trim()
}
if ([string]::IsNullOrWhiteSpace($Branch) -or $Branch -eq "HEAD") {
    $Branch = "main"
}

$hasRemote = Test-GitRemoteExists -RemoteName $RemoteName
if (-not $hasRemote) {
    Write-Host "Remote '$RemoteName' is not configured. Set -RemoteUrl to enable push."
    exit 0
}

$upstreamCheck = (Invoke-Git -Args @("rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}") -AllowFail)
if ($upstreamCheck -ne 0) {
    [void](Invoke-Git -Args @("push", "-u", $RemoteName, $Branch))
} else {
    [void](Invoke-Git -Args @("push", $RemoteName, $Branch))
}

Write-Host "Sync complete."
