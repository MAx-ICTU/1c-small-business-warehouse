param(
    [string]$ConfigXmlPath = "D:\1cProject\1c-small-business-warehouse\cf-src\Configuration.xml",
    [string]$RootDir = "D:\1cProject\1c-small-business-warehouse\cf-src"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $ConfigXmlPath)) {
    throw "Configuration.xml not found: $ConfigXmlPath"
}

$xmlText = Get-Content -Raw -LiteralPath $ConfigXmlPath

function Get-TagCount {
    param([string]$Tag)
    return ([regex]::Matches($xmlText, "<$Tag>")).Count
}

$expected = @(
    [PSCustomObject]@{ Name = "Subsystem"; MinCount = 7; Actual = (Get-TagCount -Tag "Subsystem") },
    [PSCustomObject]@{ Name = "Catalog"; MinCount = 5; Actual = (Get-TagCount -Tag "Catalog") },
    [PSCustomObject]@{ Name = "Enum"; MinCount = 2; Actual = (Get-TagCount -Tag "Enum") },
    [PSCustomObject]@{ Name = "Document"; MinCount = 5; Actual = (Get-TagCount -Tag "Document") },
    [PSCustomObject]@{ Name = "AccumulationRegister"; MinCount = 2; Actual = (Get-TagCount -Tag "AccumulationRegister") },
    [PSCustomObject]@{ Name = "InformationRegister"; MinCount = 1; Actual = (Get-TagCount -Tag "InformationRegister") }
)

$expected | Format-Table -AutoSize

$failed = @($expected | Where-Object { $_.Actual -lt $_.MinCount })
if ($failed.Count -gt 0) {
    Write-Error "Stage 1 check failed by tag count"
    exit 1
}

$pathsToCheck = @(
    "Subsystems",
    "Catalogs",
    "Documents",
    "Enums",
    "AccumulationRegisters",
    "InformationRegisters"
)

foreach ($relative in $pathsToCheck) {
    $full = Join-Path $RootDir $relative
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Error "Expected directory missing: $full"
        exit 1
    }
}

Write-Host "Stage 1 check passed."

