# Ambient sound assets

These four MP3s are bundled with the app and played in breathing / meditation sessions.

| File | Character | How it's made today |
|---|---|---|
| `rain.mp3` | Steady rainfall | Pink noise, band-pass 300–5500 Hz |
| `forest.mp3` | Airy wind / leaves | Low-passed pink noise + slow tremolo |
| `creek.mp3` | Flowing water | Brown noise + mid-range emphasis + tremolo |
| `bell.mp3` | Meditation bell | 528 Hz + harmonics + slow tremolo |

All current tracks are **pre-rendered synthesis** — better than the old runtime procedural generator (longer, properly filtered, no iOS MIME hack), but still not as satisfying as real field recordings.

## Regenerating

```bash
bash scripts/generate_ambient_sounds.sh
```

Requires `ffmpeg` on PATH.

## Upgrading to real recordings

Drop real **CC0** or **Pixabay-license** 30–60s seamlessly-loopable MP3s into this directory using the exact same filenames (`rain.mp3`, `forest.mp3`, `creek.mp3`, `bell.mp3`). No code change needed — `AudioService` loads by filename. Then:

```bash
flutter clean && flutter pub get && flutter run
```

Good CC0 sources:
- https://freesound.org/browse/tags/cc0/
- https://pixabay.com/sound-effects/
- https://mixkit.co/free-sound-effects/

**Verify licenses before committing.** Prefer CC0 (no attribution needed) over CC-BY (attribution required in-app).
