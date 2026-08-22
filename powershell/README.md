# Shabba for PowerShell

This folder contains the complete Windows PowerShell setup for downloading
YouTube Music tracks and playlists.

## Install

Open PowerShell and run:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
.\powershell\install.ps1
```

The installer uses `winget` to install Python, yt-dlp, and FFmpeg when they are
missing. It installs `ytmusicapi`, imports the Shabba module from your
PowerShell profile, and makes these commands available:

| Command | Purpose |
| --- | --- |
| `dm4a <video-id>` | Download one track as M4A |
| `dmp3 <video-id> [auto]` | Resolve a video to its song/Art Track and download MP3 |
| `dmp3l <video-id> <list-id> [count] [pick]` | Resolve and download playlist tracks |
| `ytids <video-id> <list-id> [count]` | Print playlist indexes, IDs, and titles |

Use video and playlist IDs, not complete URLs:

```powershell
dmp3 abc123
dmp3 abc123 auto
dmp3l abc123 PLxyz789
dmp3l abc123 PLxyz789 50
dmp3l abc123 PLxyz789 20 pick
```

`dmp3l` processes 30 tracks by default. It automatically chooses the top song
match for every playlist item; `pick` prompts for each match instead.

Downloads are saved to `$HOME\Music\New`, and processed IDs are recorded in
`$HOME\.ytdlp\download.txt` to prevent duplicates. Set
`YTDLP_DOWNLOAD_PATH` or `YTDLP_ARCHIVE_PATH` before importing the module to
override these locations.

Shabba reads YouTube Music cookies from the first local Chrome, Edge, or
Firefox profile it finds. Sign in to YouTube Music in that browser before
downloading. To choose one explicitly:

```powershell
$env:YTDLP_COOKIES_BROWSER = 'edge'
Import-Module .\powershell\Shabba.psd1 -Force
```

## Browser-export workflow

After using `browser.js` to save `downloads.json` in the repository root:

```powershell
.\powershell\geturls.ps1
.\powershell\download.ps1
```

Use `.\powershell\install.ps1 -SkipProfile` when you only want to install the
dependencies without modifying your PowerShell profile. You can then load the
commands for the current session:

```powershell
Import-Module .\powershell\Shabba.psd1 -Force
```
