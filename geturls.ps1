param(
    [string]$InputFile = "$PSScriptRoot\downloads.json",
    [string]$OutputFile = "$PSScriptRoot\downloads.txt"
)

& "$PSScriptRoot\powershell\geturls.ps1" @PSBoundParameters
exit $LASTEXITCODE
