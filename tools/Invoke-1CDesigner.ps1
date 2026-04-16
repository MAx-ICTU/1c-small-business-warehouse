param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("dump-hier", "dump-plain", "load-hier", "load-plain", "update-db", "check")]
    [string]$Action,

    [string]$DesignerExe = "C:\Program Files (x86)\1cv8t\8.3.27.1508\bin\1cv8t.exe",
    [string]$InfoBasePath = "D:\1cProject\1c-small-business-warehouse",
    [string]$DumpDir = "D:\1cProject\1c-small-business-warehouse\cf-src",
    [string]$OutFile = "D:\1cProject\1c-small-business-warehouse\designer_out.txt",
    [string]$ResultFile = "D:\1cProject\1c-small-business-warehouse\designer_result.txt"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-Designer {
    param([string[]]$Arguments)

    if (-not (Test-Path -LiteralPath $DesignerExe)) {
        throw "Designer EXE not found: $DesignerExe"
    }
    if (-not (Test-Path -LiteralPath $InfoBasePath)) {
        throw "InfoBase folder not found: $InfoBasePath"
    }

    $baseArgs = @(
        "DESIGNER",
        "/F", $InfoBasePath,
        "/DisableStartupDialogs",
        "/Out", $OutFile,
        "/DumpResult", $ResultFile
    )

    & $DesignerExe @baseArgs @Arguments

    if (-not (Test-Path -LiteralPath $ResultFile)) {
        throw "Result file was not created: $ResultFile"
    }

    $resultCode = (Get-Content -Raw -LiteralPath $ResultFile).Trim()
    Write-Host "Designer result code: $resultCode"

    if ($resultCode -ne "0") {
        if (Test-Path -LiteralPath $OutFile) {
            Write-Host "---- Designer out ----"
            Get-Content -Raw -LiteralPath $OutFile | Write-Host
            Write-Host "----------------------"
        }
        throw "Designer command failed with code: $resultCode"
    }
}

switch ($Action) {
    "dump-hier" {
        New-Item -ItemType Directory -Force -Path $DumpDir | Out-Null
        Invoke-Designer -Arguments @("/DumpConfigToFiles", $DumpDir, "-Format", "Hierarchical")
    }
    "dump-plain" {
        New-Item -ItemType Directory -Force -Path $DumpDir | Out-Null
        Invoke-Designer -Arguments @("/DumpConfigToFiles", $DumpDir, "-Format", "Plain")
    }
    "load-hier" {
        if (-not (Test-Path -LiteralPath $DumpDir)) {
            throw "Load directory not found: $DumpDir"
        }
        Invoke-Designer -Arguments @("/LoadConfigFromFiles", $DumpDir, "-Format", "Hierarchical", "-updateConfigDumpInfo")
    }
    "load-plain" {
        if (-not (Test-Path -LiteralPath $DumpDir)) {
            throw "Load directory not found: $DumpDir"
        }
        Invoke-Designer -Arguments @("/LoadConfigFromFiles", $DumpDir, "-Format", "Plain", "-updateConfigDumpInfo")
    }
    "update-db" {
        Invoke-Designer -Arguments @("/UpdateDBCfg")
    }
    "check" {
        Invoke-Designer -Arguments @()
    }
}

Write-Host "Done: $Action"
