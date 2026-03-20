# Music Plugin

Search YouTube, SoundCloud, or local files, play audio in the background with `mpv`, and manage a saved library with playlists, tags, ratings, preview metadata, and a built-in queue.

## Requirements

- `mpv` for playback
- `yt-dlp` for YouTube and SoundCloud search/details/downloads
- `jq` for local persistence helpers
- `ffprobe` is optional but improves local metadata detection

## Launcher usage

- `>music` opens the home view with status, library shortcuts, recent plays, top tracks, tags, artists, and playlists
- `>music <query>` searches the active provider
- `>music yt:<query>`, `sc:<query>`, `local:<query>` force a provider
- `>music <url>` plays a direct URL immediately
- `>music saved:` browses the saved library
- `>music queue` opens the built-in queue browser and controls
- `>music playlist:<name>` browses, creates, renames, and launches playlists
- `>music artist:<name>` browses saved tracks by uploader
- `>music #tag` or `>music tag:` filters or edits tags
- `>music edit:` updates title, artist, or album metadata for saved entries
- `>music speed:1.05` adjusts playback speed
- `>music stop` stops background playback

Search results and saved tracks expose inline actions for queueing, saving, downloading, metadata edits, tags, and playlists. Queue controls are now part of the music plugin, so the old standalone `queue` plugin should be treated as legacy.

## IPC usage

```bash
qs -c noctalia-shell ipc call plugin:music launcher
qs -c noctalia-shell ipc call plugin:music play "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
qs -c noctalia-shell ipc call plugin:music save "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
qs -c noctalia-shell ipc call plugin:music seek 90
qs -c noctalia-shell ipc call plugin:music stop
```

## Data files

- `cache/library.json` stores saved tracks and playback stats
- `cache/playlists.json` stores playlists
- `cache/queue.json` stores the built-in persistent queue
- `cache/state.json` stores current playback state
- `settings.json` is local user state and should not be committed
