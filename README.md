# shabba
For educational purposes.

### Get the urls

1. Load the music in your https://music.youtube.com. For best results, load a playlist.
1. Copy the content in [browser.js](./browser.js) into the browser console.
1. When prompted to save the file, save the file as `downloads.json` in the root of this project.

### Clean the urls

1. Go through `downloads.json` file and remove the objects you don't want to download.
1. Save the final file contents.

### Fetch the urls for download

1. Make sure you have [jq](https://jqlang.org/) installed.
1. Run `jq -r '.[].url' downloads.json > downloads.txt` or [./geturls.sh](./geturls.sh)
1. You have a new file `downloads.txt`

### Download the files

1. Make sure you have [gxargs](https://man.freebsd.org/cgi/man.cgi?query=gxargs&sektion=1&apropos=0&manpath=FreeBSD+6.0-RELEASE+and+Ports) installed. This is to allow us to run max processes. In Mac OS, run `brew install findutils` to install it.
1. Set up your environment:
    ```bash
    YTDLP_DOWNLOAD_PATH=/path/to/your/downloads/folder
    YTDLP_ARCHIVE_PATH=/path/to/your/archive/file.txt #enables you to avoid download duplications
    ```

1. run the following command to download `m4a` format. If you need mp3 or other format, change `mp4` to your preference:
    ```bash
    cat downloads.txt | gxargs -P 4 -I {}   yt-dlp --throttled-rate 100K --no-mtime --audio-multistreams -P $YTDLP_DOWNLOAD_PATH --download-archive $YTDLP_ARCHIVE_PATH -f ba --extract-audio --embed-thumbnail --embed-metadata -o "%(title)s.%(ext)s" --audio-format m4a "{}"
    ```
