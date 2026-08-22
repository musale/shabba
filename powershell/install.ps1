param(
    [switch]$SkipProfile
)

$ErrorActionPreference = 'Stop'

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'This installer must be run on Windows.'
}
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget is required. Install or update App Installer from the Microsoft Store.'
}

function Refresh-ProcessPath {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machinePath;$userPath"
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory)]
        [string]$Id
    )

    & winget install `
        --exact `
        --id $Id `
        --accept-package-agreements `
        --accept-source-agreements `
        --silent
    if ($LASTEXITCODE -ne 0) {
        throw "winget could not install $Id (exit code $LASTEXITCODE)."
    }
    Refresh-ProcessPath
}

function Test-Python {
    param(
        [Parameter(Mandatory)]
        [string]$Executable,

        [string[]]$Arguments = @()
    )

    $command = Get-Command $Executable -ErrorAction SilentlyContinue
    if (-not $command -or $command.Source -like '*\WindowsApps\python.exe') {
        return $false
    }

    & $Executable @Arguments -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 9) else 1)' 2>$null
    return $LASTEXITCODE -eq 0
}

if (-not (Test-Python 'py' @('-3')) -and -not (Test-Python 'python')) {
    Install-WingetPackage 'Python.Python.3.13'
}
if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
    Install-WingetPackage 'yt-dlp.yt-dlp'
}
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Install-WingetPackage 'yt-dlp.FFmpeg'
}

$pythonExecutable = if (Test-Python 'py' @('-3')) {
    'py'
} elseif (Test-Python 'python') {
    'python'
} else {
    throw 'Python 3.9+ was installed but is not yet available. Open a new PowerShell window and rerun this installer.'
}
$pythonArguments = if ($pythonExecutable -eq 'py') { @('-3') } else { @() }

& $pythonExecutable @pythonArguments -m pip install --upgrade -r "$PSScriptRoot\requirements.txt"
if ($LASTEXITCODE -ne 0) {
    throw "Python dependencies could not be installed (exit code $LASTEXITCODE)."
}

if (-not $SkipProfile) {
    $profilePath = $PROFILE.CurrentUserCurrentHost
    $profileDirectory = Split-Path $profilePath -Parent
    New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null
    if (-not (Test-Path -LiteralPath $profilePath)) {
        New-Item -ItemType File -Path $profilePath -Force | Out-Null
    }

    $escapedModulePath = (Join-Path $PSScriptRoot 'Shabba.psd1').Replace("'", "''")
    $importLine = "Import-Module '$escapedModulePath' -Force"
    $profileContents = Get-Content -LiteralPath $profilePath -Raw
    if ($profileContents -notmatch [regex]::Escape($importLine)) {
        Add-Content -LiteralPath $profilePath -Value "`n# Shabba YouTube Music commands`n$importLine"
        Write-Host "Added Shabba to $profilePath"
    }
}

Import-Module "$PSScriptRoot\Shabba.psd1" -Force
Write-Host 'Installed Shabba. Commands: dmp3, dm4a, dmp3l, ytids'
