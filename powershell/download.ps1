param(
    [string]$DownloadsFile = (Join-Path (Split-Path $PSScriptRoot -Parent) 'downloads.txt')
)

Import-Module "$PSScriptRoot\Shabba.psd1" -Force

if (-not (Test-Path -LiteralPath $DownloadsFile)) {
    Write-Error "Downloads file not found: $DownloadsFile"
    exit 1
}

$failed = 0
foreach ($entry in (Get-Content -LiteralPath $DownloadsFile)) {
    $url = $entry.Trim()
    if (-not $url) {
        continue
    }

    Write-Host "Processing: $url"
    try {
        $videoId = ([uri]$url).Query.TrimStart('?').Split('&') |
            Where-Object { $_ -like 'v=*' } |
            ForEach-Object { $_.Substring(2) } |
            Select-Object -First 1
        if (-not $videoId) {
            throw "No video ID found in '$url'."
        }

        dm4a $videoId
        Write-Host "Successfully processed: $url"
    } catch {
        Write-Error "Failed to process '$url': $_"
        $failed++
    }
    Write-Host '---'
}

if ($failed -gt 0) {
    Write-Error "Finished with $failed failed download(s)."
    exit 1
}

Write-Host 'Finished processing all downloads.'
exit 0
