# shabba
For educational purposes.

### Get the urls

1. Load the music in your https://music.youtube.com. For best results, load a playlist.
1. Copy the content in [browser.js](./browser.js) into the browser console.
1. When prompted to save the file, save the file as `downloads.json` in the root of this project.

### Clean the urls

1. Go through `downloads.json` file and remove the objects you don't want to download.
1. Save the final file contents.

### Fetch the URLs for download

On Linux or macOS:

```bash
./geturls.sh
```

This requires [jq](https://jqlang.org/). On Windows PowerShell:

```powershell
.\geturls.ps1
```

Both commands create `downloads.txt`.

### Download the files

The Unix aliases are managed in
[musale/dotfiles](https://github.com/musale/dotfiles). The complete standalone
Windows setup is in [`powershell`](./powershell/README.md). Both use Chrome
cookies by default and save music under `~/Music/New`, with the
duplicate-download archive at `~/.ytdlp/download.txt`. Windows also detects Edge
and Firefox profiles.

On Linux or macOS, load your dotfiles profile and run:

```bash
./download.sh
```

On Windows PowerShell, install the standalone package once and then run:

```powershell
.\powershell\install.ps1
.\download.ps1
```

The available commands in both shells are:

| Command | Purpose |
| --- | --- |
| `dm4a <video-id>` | Download one YouTube Music track as M4A |
| `dmp3 <video-id> [auto]` | Resolve and download one track as MP3 |
| `dmp3l <video-id> <list-id> [count] [pick]` | Resolve and download playlist tracks |
| `ytids <video-id> <list-id> [count]` | List playlist indexes, IDs, and titles |
