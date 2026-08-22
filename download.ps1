param(
    [string]$DownloadsFile = "$PSScriptRoot\downloads.txt"
)

& "$PSScriptRoot\powershell\download.ps1" @PSBoundParameters
exit $LASTEXITCODE
