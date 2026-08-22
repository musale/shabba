#!/usr/bin/env python3
"""Resolve a YouTube Music video ID to a song/Art Track video ID."""

import sys
import warnings

warnings.filterwarnings("ignore")


def log(*args):
    print(*args, file=sys.stderr)


def format_result(result):
    artists = ", ".join(
        artist["name"]
        for artist in (result.get("artists") or [])
        if artist.get("name")
    )
    album = (result.get("album") or {}).get("name") if result.get("album") else ""
    duration = result.get("duration") or ""
    parts = [result.get("title") or "?"]
    if artists:
        parts.append(f"- {artists}")
    if album:
        parts.append(f"[{album}]")
    if duration:
        parts.append(f"({duration})")
    return " ".join(parts)


def pick(candidates, auto=False):
    if not candidates:
        return None

    log("Song matches:")
    for index, result in enumerate(candidates, 1):
        log(f"  {index}. {format_result(result)}")

    if len(candidates) == 1:
        return candidates[0]["videoId"]

    if auto or not sys.stdin.isatty():
        log(f"[auto-pick] {format_result(candidates[0])}")
        return candidates[0]["videoId"]

    log("  0. cancel")
    while True:
        print("Choice [1]: ", end="", file=sys.stderr, flush=True)
        line = sys.stdin.readline()
        if not line:
            return candidates[0]["videoId"]
        line = line.strip()
        if not line:
            return candidates[0]["videoId"]
        if line.isdigit():
            choice = int(line)
            if choice == 0:
                return None
            if 1 <= choice <= len(candidates):
                return candidates[choice - 1]["videoId"]
        log("  invalid choice")


def main():
    arguments = sys.argv[1:]
    auto = "--auto" in arguments
    arguments = [argument for argument in arguments if argument != "--auto"]
    if not arguments or not arguments[0].strip():
        log("usage: ytmusic-resolve.py [--auto] <videoId>")
        return 2

    video_id = arguments[0].strip()

    from ytmusicapi import YTMusic

    youtube_music = YTMusic()
    try:
        details = youtube_music.get_song(video_id).get("videoDetails", {})
    except Exception as error:  # noqa: BLE001
        log(f"[warn] could not fetch metadata for {video_id}: {error}")
        details = {}

    music_video_type = details.get("musicVideoType", "")
    title = details.get("title", "")
    author = details.get("author", "")

    if music_video_type == "MUSIC_VIDEO_TYPE_ATV":
        log(f"[song] {title} - {author} (already a song)")
        print(video_id)
        return 0

    query = " ".join(part for part in (author, title) if part) or video_id
    log(f"[video] {title or video_id} - searching songs for: {query!r}")

    try:
        results = youtube_music.search(query, filter="songs", limit=10) or []
    except Exception as error:  # noqa: BLE001
        log(f"[error] search failed: {error}")
        return 1

    candidates = [result for result in results if result.get("videoId")][:8]
    if not candidates:
        log("[error] no song version found on YouTube Music")
        return 1

    chosen = pick(candidates, auto=auto)
    if not chosen:
        log("cancelled")
        return 1

    print(chosen)
    return 0


if __name__ == "__main__":
    sys.exit(main())
