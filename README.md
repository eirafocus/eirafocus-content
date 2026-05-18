# eirafocus-content

Shared, versioned content bundle for the EiraFocus iOS and Android apps.

This repo holds everything that isn't code: audio loops, voice clips, program scripts, quotes, breathing-pattern definitions, tag and mood data, and branding assets. Both apps pin a `manifest_version` (major) from `manifest.json` and lazily fetch content. Audio files are downloaded on first play and cached on device — uninstall clears them.

## Layout

```
.
├── manifest.json              top-level versioning + index
├── branding/                  logos
├── data/                      structured content (JSON)
│   ├── breathing_methods.json
│   ├── quotes.json
│   ├── tags.json
│   └── text_prompts.json
├── programs/                  multi-prompt journey scripts
│   └── guided_journeys.json
├── audio/
│   ├── legacy/                v1 Flutter sounds, kept for reference, not shipping in v2
│   ├── ambient/               Pixabay-sourced ambient loops (added in subsequent commits)
│   └── voice/                 Azure Neural HD TTS clips (added in subsequent commits)
└── docs/
```

## Versioning

- `manifest_version` — bumped on **breaking** structural changes. Apps pin a major version.
- `content_version` — bumped on content updates within a manifest. Apps poll this lazily.
- Each JSON file has its own internal `version` field for fine-grained migration.

## Sources and licensing

| Content type | Source | License |
|---|---|---|
| Branding logos | Designed for EiraFocus | All rights reserved by Aftaab Siddiqui |
| Quotes | Public domain / fair-use single-line quotations with attribution | Compiled list, freely usable |
| Breathing methods, tags, mood data, text prompts | Original to EiraFocus | MIT |
| Programs (guided journeys) | Original scripts for EiraFocus | MIT |
| Legacy audio (v1 Flutter) | Procedural / placeholder, not shipping in v2 | n/a |
| Ambient audio (v2.0+) | Pixabay (Pixabay License — commercial + redistribution OK, no attribution required) | Pixabay License |
| Voice clips (v2.0+) | Azure Neural HD TTS, pre-rendered. Voices: `en-US-AvaMultilingualNeural`, `en-US-AndrewMultilingualNeural`, `en-IN-NeerjaNeural`, `en-IN-PrabhatNeural` | See Azure Speech terms for synthetic-output usage |

## Consumers

- `eirafocus/eirafocus-ios` — bundles a snapshot at build time, fetches updates at runtime
- `eirafocus/eirafocus-android` — same

## Related repos

- [eirafocus-ios](https://github.com/eirafocus/eirafocus-ios)
- [eirafocus-android](https://github.com/eirafocus/eirafocus-android)
- [eirafocus-sync](https://github.com/eirafocus/eirafocus-sync) — private
- [eirafocus.com](https://github.com/eirafocus/eirafocus.com)
- [eirafocus-legacy](https://github.com/eirafocus/eirafocus-legacy) — archived v1 Flutter app

## License

MIT for original scripts and code. See individual content licenses above.
