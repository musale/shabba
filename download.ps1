param(
    [string]$DownloadsFile = "$PSScriptRoot\downloads.txt"
)

if (-not (Test-Path -LiteralPath $DownloadsFile)) {
    Write-Error "Downloads file not found: $DownloadsFile"
    exit 1
}

$downloadCommand = Get-Command dm4a -ErrorAction SilentlyContinue
if (-not $downloadCommand) {
    Write-Error "dm4a is not available. Load the PowerShell profile from musale/dotfiles first."
    exit 1
}

$failed = 0
foreach ($entry in (Get-Content -LiteralPath $DownloadsFile)) {
    $url = $entry.Trim()
    if (-not $url) {
        continue
    }

    Write-Host "Processing: $url"
    & $downloadCommand $url
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Successfully processed: $url"
    } else {
        Write-Error "Failed to process: $url"
        $failed++
    }
    Write-Host "---"
}

if ($failed -gt 0) {
    Write-Error "Finished with $failed failed download(s)."
    exit 1
}

Write-Host "Finished processing all downloads."
