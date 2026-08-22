$script:ResolverPath = Join-Path $PSScriptRoot 'ytmusic-resolve.py'

if (-not $env:YTDLP_DOWNLOAD_PATH) {
    $env:YTDLP_DOWNLOAD_PATH = Join-Path $HOME 'Music\New'
}
if (-not $env:YTDLP_ARCHIVE_PATH) {
    $env:YTDLP_ARCHIVE_PATH = Join-Path $HOME '.ytdlp\download.txt'
}

function Test-ShabbaPython {
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

function Get-ShabbaPython {
    if (Test-ShabbaPython 'py' @('-3')) {
        return [pscustomobject]@{
            Executable = 'py'
            Arguments = @('-3')
        }
    }
    if (Test-ShabbaPython 'python') {
        return [pscustomobject]@{
            Executable = 'python'
            Arguments = @()
        }
    }

    throw 'Python 3 is not installed or is not available on PATH. Run powershell\install.ps1.'
}

function Get-ShabbaCookiesBrowser {
    if ($env:YTDLP_COOKIES_BROWSER) {
        return $env:YTDLP_COOKIES_BROWSER
    }

    $browserProfiles = @(
        @{ Name = 'chrome'; Path = (Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data') }
        @{ Name = 'edge'; Path = (Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\User Data') }
        @{ Name = 'firefox'; Path = (Join-Path $env:APPDATA 'Mozilla\Firefox\Profiles') }
    )
    $browser = $browserProfiles |
        Where-Object { Test-Path -LiteralPath $_.Path } |
        Select-Object -First 1
    if (-not $browser) {
        throw 'No supported browser profile was found. Sign in to YouTube Music using Chrome, Edge, or Firefox, or set YTDLP_COOKIES_BROWSER.'
    }

    return $browser.Name
}

function Invoke-ShabbaYtDlpAudio {
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet('mp3', 'm4a')]
        [string]$Format,

        [Parameter(Mandatory, Position = 1, ValueFromRemainingArguments)]
        [string[]]$Url
    )

    if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
        throw 'yt-dlp is not installed or is not available on PATH. Run powershell\install.ps1.'
    }
    if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        throw 'FFmpeg is not installed or is not available on PATH. Run powershell\install.ps1.'
    }

    $archiveDirectory = Split-Path $env:YTDLP_ARCHIVE_PATH -Parent
    New-Item -ItemType Directory -Path $env:YTDLP_DOWNLOAD_PATH -Force | Out-Null
    New-Item -ItemType Directory -Path $archiveDirectory -Force | Out-Null
    $cookiesBrowser = Get-ShabbaCookiesBrowser

    & yt-dlp `
        --cookies-from-browser $cookiesBrowser `
        --sleep-requests 1 `
        --sleep-interval 5 `
        --max-sleep-interval 15 `
        --retries 10 `
        --throttled-rate 100K `
        --no-mtime `
        --audio-multistreams `
        -P $env:YTDLP_DOWNLOAD_PATH `
        --download-archive $env:YTDLP_ARCHIVE_PATH `
        -f ba `
        --extract-audio `
        --embed-thumbnail `
        --convert-thumbnails jpg `
        --embed-metadata `
        -o '%(title)s.%(ext)s' `
        --audio-format $Format `
        @Url

    if ($LASTEXITCODE -ne 0) {
        throw "yt-dlp failed with exit code $LASTEXITCODE."
    }
}

function Save-ShabbaMp3 {
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$VideoId,

        [Parameter(Position = 1)]
        [ValidateSet('auto')]
        [string]$Mode
    )

    $python = Get-ShabbaPython
    $resolveArguments = @($python.Arguments) + @($script:ResolverPath)
    if ($Mode -eq 'auto') {
        $resolveArguments += '--auto'
    }
    $resolveArguments += $VideoId

    $resolvedIds = @(& $python.Executable @resolveArguments)
    if ($LASTEXITCODE -ne 0) {
        throw "Could not resolve a YouTube Music song for '$VideoId'."
    }

    $resolvedId = $resolvedIds |
        ForEach-Object { "$_".Trim() } |
        Where-Object { $_ } |
        Select-Object -Last 1
    if (-not $resolvedId) {
        throw "No YouTube Music song was resolved for '$VideoId'."
    }

    Invoke-ShabbaYtDlpAudio mp3 "https://music.youtube.com/watch?v=$resolvedId"
}

function Save-ShabbaM4a {
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$VideoId
    )

    Invoke-ShabbaYtDlpAudio m4a "https://music.youtube.com/watch?v=$VideoId"
}

function Save-ShabbaMp3List {
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$VideoId,

        [Parameter(Mandatory, Position = 1)]
        [string]$ListId,

        [Parameter(Position = 2)]
        [ValidateRange(1, 5000)]
        [int]$Count = 30,

        [Parameter(Position = 3)]
        [ValidateSet('pick')]
        [string]$Mode
    )

    if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
        throw 'yt-dlp is not installed or is not available on PATH. Run powershell\install.ps1.'
    }

    $cookiesBrowser = Get-ShabbaCookiesBrowser
    $url = "https://music.youtube.com/watch?v=$VideoId&list=$ListId"
    $ids = @(
        & yt-dlp `
            --cookies-from-browser $cookiesBrowser `
            --flat-playlist `
            --playlist-items "1-$Count" `
            --print '%(id)s' `
            $url
    )
    if ($LASTEXITCODE -ne 0) {
        throw "Could not read playlist '$ListId'."
    }

    foreach ($id in $ids) {
        $cleanId = "$id".Trim()
        if (-not $cleanId) {
            continue
        }

        if ($Mode -eq 'pick') {
            Save-ShabbaMp3 $cleanId
        } else {
            Save-ShabbaMp3 $cleanId auto
        }
    }
}

function Get-ShabbaYtIds {
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$VideoId,

        [Parameter(Mandatory, Position = 1)]
        [string]$ListId,

        [Parameter(Position = 2)]
        [ValidateRange(1, 5000)]
        [int]$Count = 30
    )

    if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
        throw 'yt-dlp is not installed or is not available on PATH. Run powershell\install.ps1.'
    }

    $cookiesBrowser = Get-ShabbaCookiesBrowser
    & yt-dlp `
        --cookies-from-browser $cookiesBrowser `
        --flat-playlist `
        --playlist-items "1-$Count" `
        --print '%(playlist_index)s  %(id)s  %(title)s' `
        "https://music.youtube.com/watch?v=$VideoId&list=$ListId"

    if ($LASTEXITCODE -ne 0) {
        throw "Could not read playlist '$ListId'."
    }
}

Set-Alias -Name dmp3 -Value Save-ShabbaMp3
Set-Alias -Name dm4a -Value Save-ShabbaM4a
Set-Alias -Name dmp3l -Value Save-ShabbaMp3List
Set-Alias -Name ytids -Value Get-ShabbaYtIds

Export-ModuleMember `
    -Function Invoke-ShabbaYtDlpAudio, Save-ShabbaMp3, Save-ShabbaM4a, Save-ShabbaMp3List, Get-ShabbaYtIds `
    -Alias dmp3, dm4a, dmp3l, ytids
