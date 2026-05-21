# EiraFocus database schema — v1

This is the **canonical** SQLite schema for both apps. iOS implements it with [GRDB](https://github.com/groue/GRDB.swift); Android implements it with [Room](https://developer.android.com/training/data-storage/room). The two implementations are validated against this document, not against each other directly.

> See [PLAN.md](https://github.com/eirafocus/eirafocus-content/blob/main/PLAN.md) §12.3 for the rationale. Both apps must be able to import a JSON export from the other.

## Versioning

- The schema has a single integer `version` (currently `1`). Both apps store this in their on-device metadata.
- **Additive migrations only** while we share the schema spec — adding a column or a new table is fine; renaming or removing requires a coordinated version bump on both platforms.
- The JSON export envelope (§3 below) also carries the schema version so it can be validated on import.

---

## 1. Tables

### `sessions`
Every breathing session, meditation session, AND daily journal entry. The `type='Journal'` rows have `null` `method` and `duration_seconds`.

| Column            | Type    | Constraints                          | Notes |
|-------------------|---------|--------------------------------------|-------|
| `id`              | INTEGER | PRIMARY KEY AUTOINCREMENT             |       |
| `type`            | TEXT    | NOT NULL                              | `'Breathing'` \| `'Meditation'` \| `'Journal'` |
| `method`          | TEXT    | nullable                              | e.g. `'Box Breathing'`; null for journal |
| `duration_seconds`| INTEGER | nullable                              | null for journal |
| `timestamp`       | TEXT    | NOT NULL                              | ISO-8601 UTC, e.g. `2026-05-21T08:32:11Z` |
| `journal`         | TEXT    | nullable                              | free-form note attached to session, or main text for journal entries |
| `tags`            | TEXT    | nullable                              | CSV of tag ids (see `data/tags.json`) |
| `mood_before`     | INTEGER | nullable, CHECK (1..5)                |       |
| `mood_after`      | INTEGER | nullable, CHECK (1..5)                |       |
| `photo_path`      | TEXT    | nullable                              | local file URL only; never synced unless user opts in. Plus tier. |

Indexes:
- `idx_sessions_timestamp` on `(timestamp DESC)` — list views
- `idx_sessions_type` on `(type)` — filter sub-tabs
- `idx_sessions_mood_after` on `(mood_after)` — analytics

### `streaks`
Single-row table holding the user's current streak state.

| Column              | Type    | Constraints                | Notes |
|---------------------|---------|----------------------------|-------|
| `id`                | INTEGER | PRIMARY KEY, CHECK (id=1)  | enforced single row |
| `current_streak`    | INTEGER | NOT NULL DEFAULT 0          |       |
| `last_session_date` | TEXT    | nullable                    | ISO date only, `YYYY-MM-DD` |
| `longest_streak`    | INTEGER | NOT NULL DEFAULT 0          |       |
| `freeze_tokens`     | INTEGER | NOT NULL DEFAULT 0          |       |
| `freeze_used_dates` | TEXT    | nullable                    | CSV of ISO dates |

### `weekly_goals`
One row per Monday-aligned week.

| Column         | Type    | Constraints  | Notes |
|----------------|---------|--------------|-------|
| `week_start`   | TEXT    | PRIMARY KEY  | ISO date of Monday, `YYYY-MM-DD` |
| `goal_minutes` | INTEGER | NOT NULL     |       |

### `favorites`
Methods the user has starred.

| Column        | Type | Constraints | Notes |
|---------------|------|-------------|-------|
| `method_name` | TEXT | PRIMARY KEY | breathing method name or `'Meditation'` |

### `custom_methods`
User-created breathing patterns.

| Column              | Type    | Constraints              | Notes |
|---------------------|---------|--------------------------|-------|
| `id`                | INTEGER | PRIMARY KEY AUTOINCREMENT |       |
| `name`              | TEXT    | NOT NULL                  |       |
| `inhale`            | INTEGER | NOT NULL                  | seconds |
| `hold_after_inhale` | INTEGER | NOT NULL DEFAULT 0        |       |
| `exhale`            | INTEGER | NOT NULL                  |       |
| `hold_after_exhale` | INTEGER | NOT NULL DEFAULT 0        |       |
| `created_at`        | TEXT    | NOT NULL                  | ISO-8601 UTC |

### `presets`
Quick-start cards on the Today screen.

| Column             | Type    | Constraints              | Notes |
|--------------------|---------|--------------------------|-------|
| `id`               | INTEGER | PRIMARY KEY AUTOINCREMENT |       |
| `name`             | TEXT    | NOT NULL                  |       |
| `type`             | TEXT    | NOT NULL                  | `'Breathing'` \| `'Meditation'` |
| `method`           | TEXT    | NOT NULL                  | breathing method name or `'Meditation'` |
| `duration_minutes` | INTEGER | nullable                  | null = "Free", run until ended |
| `created_at`       | TEXT    | NOT NULL                  |       |

### `custom_journeys`
User-defined multi-prompt guided sessions.

| Column          | Type    | Constraints              | Notes |
|-----------------|---------|--------------------------|-------|
| `id`            | INTEGER | PRIMARY KEY AUTOINCREMENT |       |
| `name`          | TEXT    | NOT NULL                  |       |
| `segments_json` | TEXT    | NOT NULL                  | JSON: `[{at_seconds, text}, ...]` |
| `created_at`    | TEXT    | NOT NULL                  |       |

### `programs_progress`
Progress through multi-day programs from the content bundle.

| Column         | Type    | Constraints              | Notes |
|----------------|---------|--------------------------|-------|
| `program_id`   | TEXT    | PRIMARY KEY               | matches content `programs/*.json` id |
| `current_day`  | INTEGER | NOT NULL DEFAULT 0        |       |
| `started_at`   | TEXT    | NOT NULL                  | ISO-8601 UTC |
| `completed_at` | TEXT    | nullable                  | ISO-8601 UTC, null if in progress |

### `settings`
Generic key/value bag for non-relational state. Use sparingly — prefer typed columns.

| Column  | Type | Constraints  | Notes |
|---------|------|--------------|-------|
| `key`   | TEXT | PRIMARY KEY  |       |
| `value` | TEXT | nullable     | free-form; encode complex values as JSON |

Known keys (well-known consumers should add to this list):
- `voice_id` — selected voice (`en-US-Ava`, `en-US-Andrew`, `en-IN-Neerja`, `en-IN-Prabhat`)
- `theme_mode` — `'system'` \| `'light'` \| `'dark'`
- `accent_color` — hex string, Plus only
- `visualizer_skin` — `'orb'` \| `'halo'` \| `'ribbon'` \| ...
- `streaks_hidden` — `'true'` \| `'false'` (no-streak mode)
- `reminders_enabled` — `'true'` \| `'false'`
- `reminder_hour` / `reminder_minute` — `'0'`..`'23'` / `'0'`..`'59'`
- `health_sync_enabled` — `'true'` \| `'false'`
- `sync_key_hash` — SHA-256 hex of the user's sync key (Plus)
- `manifest_pinned_version` — major version of the content bundle

---

## 2. Date and time

- **All timestamps stored as TEXT in ISO-8601 UTC** with `Z` suffix, e.g. `2026-05-21T08:32:11Z`.
- Dates without time use `YYYY-MM-DD`.
- Both platforms must parse / serialize with strict ISO-8601 + UTC. Local time conversion happens only at the UI layer.

## 3. JSON export envelope

The format used for backup, restore, and cloud sync payloads.

```jsonc
{
  "schema": "eirafocus-export",
  "schema_version": 1,
  "exported_at": "2026-05-21T08:32:11Z",
  "device": {
    "platform": "ios" | "android",
    "app_version": "2.0.0"
  },
  "tables": {
    "sessions":          [ /* row objects matching the column names above */ ],
    "streaks":           [ /* exactly 0 or 1 row */ ],
    "weekly_goals":      [ /* ... */ ],
    "favorites":         [ /* ... */ ],
    "custom_methods":    [ /* ... */ ],
    "presets":           [ /* ... */ ],
    "custom_journeys":   [ /* ... */ ],
    "programs_progress": [ /* ... */ ],
    "settings":          [ { "key": "...", "value": "..." } ]
  }
}
```

Import rules:
1. Validate `schema == "eirafocus-export"` and `schema_version <= app's max known version`.
2. Wrap the entire import in a single transaction.
3. For tables with autoincrement IDs (`sessions`, `custom_methods`, `presets`, `custom_journeys`), use `INSERT OR IGNORE` to avoid colliding with existing rows; preserve the imported `id` value.
4. For primary-key tables (`streaks`, `weekly_goals`, `favorites`, `programs_progress`, `settings`), use `INSERT OR REPLACE`.
5. Tags reference `data/tags.json` from the content bundle — orphan tag ids are kept as-is (do not delete them).

## 4. Encryption (cloud sync only)

When the JSON envelope is uploaded to the optional sync service ([eirafocus-sync](https://github.com/eirafocus/eirafocus-sync)), it is encrypted client-side with AES-256-GCM using a key derived from the user's sync key via HKDF. The server stores ciphertext only. See PLAN.md §12.4.

## 5. Migration policy

- **Adding a column**: ship it, give it a sensible default, document here, do not bump `schema_version`.
- **Adding a table**: same.
- **Renaming a column** or changing its type: bump `schema_version`, write a migration on both platforms.
- **Removing a column**: never. Mark as deprecated in this doc, leave it on disk.

## 6. Implementations

- iOS: `eirafocus-ios/EiraFocus/Services/Database/`
- Android: `eirafocus-android/app/src/main/kotlin/com/eirafocus/android/services/database/`

Both implementations test against the round-trip: serialize → JSON → deserialize → byte-for-byte equality in normalized form.
