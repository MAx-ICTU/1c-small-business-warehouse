param(
    [string]$Message,
    [string]$RemoteUrl = "",
    [switch]$NoPush
)

$args = @()
if (-not [string]::IsNullOrWhiteSpace($Message)) {
    $args += @("-Message", $Message)
}
if (-not [string]::IsNullOrWhiteSpace($RemoteUrl)) {
    $args += @("-RemoteUrl", $RemoteUrl)
}
if ($NoPush) {
    $args += "-NoPush"
}

powershell -ExecutionPolicy Bypass -File "D:\1cProject\1c-small-business-warehouse\tools\Sync-GitHub.ps1" @args
