param(
    [string]$InputFile = "$PSScriptRoot\downloads.json",
    [string]$OutputFile = "$PSScriptRoot\downloads.txt"
)

if (-not (Test-Path -LiteralPath $InputFile)) {
    Write-Error "Input file not found: $InputFile"
    exit 1
}

$urls = @(
    Get-Content -LiteralPath $InputFile -Raw |
        ConvertFrom-Json |
        ForEach-Object { $_.url } |
        Where-Object { $_ }
)

Set-Content -LiteralPath $OutputFile -Value $urls -Encoding utf8
Write-Host "Saved $($urls.Count) URL(s) to $OutputFile"
