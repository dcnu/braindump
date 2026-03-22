# Braindump: Quick-Capture Note Inbox

## Overview

A native macOS menu bar app for capturing thoughts, observations, and tasks throughout the day. Notes are stored as daily Markdown files with YAML front-matter, compatible with Obsidian. The app acts as an inbox: autonomous agents process, organize, and clear notes on a regular cadence.

## Core Concepts

- The app is an **inbox**, not an archive
- The filesystem is the API: agents and the app both read/write `.md` files directly
- One `.md` file per day
- Each entry within a day is timestamped to the second
- Markdown is stored raw (syntax-highlighted but not rendered)
- Agents set `status: processed` in front-matter to clear a day from the UI

## File Format

### Directory Structure

```
<vault-root>/
  braindump/
    2026-03-21.md
    2026-03-20.md
    2026-03-19.md
    index.json
```

### Daily File

```yaml
---
created: 2026-03-21
edited: 2026-03-21T14:42:07Z
status: active
---
```

```markdown
## 14:41:33

candidate has 5 years of experience

## 14:42:07

strong knowledge in React and TypeS
follow up question about state management

## 14:55:00

- [ ] send follow-up email to candidate
- [ ] check references

## 15:10:44

[[hiring-pipeline]] might need to adjust criteria
for senior roles
```

- `created`: date only, written once
- `edited`: ISO 8601 with time, updated on every save
- `status`: `active` | `processed`
- When `status` is `processed`, the day's entries remain in the file and are still visible in the UI, but displayed as read-only with muted/greyed text and a lock icon on the date header. The user cannot edit or add entries to a processed day. This signals that the canonical version now lives in Obsidian.
- Entries are H2 blocks with `HH:MM:SS` as the heading
- Multi-line content within an entry is preserved as-is
- Markdown syntax is preserved verbatim in the file

### Supported Markdown Notation

- `- [ ]` / `- [x]` (task items)
- `- []` / `- [X]` (alternate task syntax, treated equivalently)
- `TODO` / `TODO:` as plain text task markers
- `**bold**`, `*italic*`, `` `code` ``, `~~strikethrough~~`
- `[[wikilinks]]`
- `> blockquotes`
- Fenced code blocks with language identifier
- `#tags` (inline hashtags)

All notation is stored verbatim. The editor syntax-highlights but does not render (no rich text conversion, no rendered checkboxes, no bold text).

## Architecture

### Stack

- **Platform**: native macOS (Swift >= 5.9, macOS >= 14.0 Sonoma)
- **UI framework**: SwiftUI for menu bar panel and settings; `NSTextView` subclass for the editor with custom attribute-based Markdown syntax highlighting
- **Index**: JSON file on disk, maintained by a background `DispatchSource` file watcher

### Index

`index.json` is a metadata cache derived from front-matter. The filesystem remains the source of truth.

```json
[
  {
    "date": "2026-03-21",
    "filePath": "braindump/2026-03-21.md",
    "status": "active",
    "entryCount": 4,
    "lastEntryTime": "15:10:44"
  }
]
```

- Rebuilt on startup by parsing front-matter of all `.md` files in the directory
- Updated incrementally via `DispatchSource.makeFileSystemObjectSource` on the braindump directory
- Full reconciliation every 60 seconds or on window focus
- Only `active` days are editable in the UI; `processed` days are visible but read-only

### Data Flow

```
user types entry, presses CMD+Enter
       │
       ▼
append H2 block to today's .md file
update `edited` in front-matter
       │
       ▼
file watcher detects change
       │
       ▼
update index.json
       │
       ▼
UI reflects new entry
```

```
agent reads .md file
       │
       ▼
agent processes entries
       │
       ▼
agent sets status: processed in front-matter
       │
       ▼
file watcher detects change
       │
       ▼
index updated, day removed from UI
```

## Frontend

### Activation

- **Menu bar icon**: click to toggle dropdown panel
- **Full window**: option to open as a standard macOS window (from menu bar right-click or settings)
- **Global hotkey**: configurable (default: Ctrl+Space) to summon the input field from any app

### Menu Bar Panel

- Default size: 400px wide, 500px tall
- Resizable by dragging edges
- Remembers last size between sessions
- Pinned above other windows while open
- Click outside or press Escape to dismiss

### Layout

Single scrolling view, reverse chronological. Input field pinned at top.

```
┌─────────────────────────────────────────┐
│  [input field, cursor active]      [now]│
├─────────────────────────────────────────┤
│                                         │
│  ⏱  March 21, 2026                     │
│                                         │
│  15:10:44    [[hiring-pipeline]] might  │
│              need to adjust criteria    │
│              for senior roles           │
│                                         │
│  14:55:00    - [ ] send follow-up email │
│              - [ ] check references     │
│                                         │
│  14:42:07    strong knowledge in React  │
│              and TypeS                  │
│              follow up question about   │
│              state management           │
│                                         │
│  14:41:33    candidate has 5 years of   │
│              experience                 │
│                                         │
│                                         │
│  ⏱  March 20, 2026                     │
│                                         │
│  ...                                    │
│                                         │
└─────────────────────────────────────────┘
```

- Date header: clock icon + human-readable date, left-aligned
- Whitespace between day groups
- Timestamp column: fixed-width, left-aligned, monospace, muted color
- Content column: syntax-highlighted raw Markdown
- Entries within a day are reverse chronological (newest at top)
- One day visible at a time; scroll is within the current day only
- CMD+Left / CMD+Right: navigate to previous/next active day

### Input Behavior

- Input field is always visible at the top of the panel
- On open: show today's entries if any exist, otherwise show a blank day with today's date header
- **CMD+N**: create a new entry with the current timestamp, cursor placed in the content area
- **Enter / Shift+Enter**: newline within the current entry
- **CMD+Enter**: submit current entry (finalize and deselect)
- **Pasting multi-line text**: all content goes into the current entry; line breaks are normalized (collapse consecutive blank lines to a single newline, trim trailing whitespace per line)
- If an entry is never given any text (CMD+N then CMD+N again, or CMD+N then close), the empty entry is discarded
- Auto-saves on CMD+Enter (writes to disk immediately)

### Entry Navigation

- Click an existing entry to edit inline
- Up/Down arrow keys: navigate between entries within the current day
- CMD+Left / CMD+Right: navigate to previous/next active day
- Press Enter within a selected entry to begin editing
- Edits update the content in the `.md` file and set `edited` in front-matter

### Processed Days

- Processed days remain visible in the UI but are read-only
- Date header shows a lock icon (🔒) next to the date
- All entry text is rendered in a muted/grey color
- Clicking entries does not activate editing
- CMD+N is disabled on processed days
- CMD+Left / CMD+Right still navigates to processed days
- The user can still scroll and read entries

- Select entry, press CMD+Delete to remove
- Entry is removed from the `.md` file
- If the last entry in a day is deleted, the daily file is also deleted
- No confirmation dialog (keep it fast)

### Settings

- **Sort key**: `created` (default) or `edited` for day-card ordering
- **Input position**: top (default) — reserved for future option to pin bottom
- **Vault path**: directory where `.md` files are stored
- **Time format**: 24h (default) or 12h display (storage is always 24h)
- **Global hotkey**: configurable key combination
- **Launch at login**: toggle

## Agent Contract

Agents are external processes. The app does not manage, schedule, or invoke them.

### Filesystem Interface

- Agents read `.md` files from the configured vault path
- To mark a day as processed: set `status: processed` in YAML front-matter
- Agents must not modify the `created` field
- Agents must update `edited` when modifying a file
- Agents may add additional front-matter fields (e.g., `processed_at`, `agent`, `tags`)
- Agents may move processed files to a subdirectory (e.g., `braindump/archive/`)
- The app only watches the root `braindump/` directory

### Expected Agent Behaviors

- **Task extraction**: collect `- [ ]`, `- []`, `TODO` items into a centralized task list or Obsidian note
- **Thematic identification**: group entries by topic across days
- **Wikilink resolution**: connect `[[references]]` to existing Obsidian notes or create stubs
- **Cross-referencing**: match entry timestamps against external sources (emails sent/received, Slack messages, calendar events, meeting transcripts) to enrich context
- **Summarization**: generate daily/weekly summaries as separate Obsidian notes
- **Linting**: normalize formatting, fix typos if configured
- **Indexing**: add entries to an Obsidian-compatible search index

### Scheduling

- Default processing runs via cron at 2:00 AM PT the following day (e.g., entries from March 21 are processed at 2:00 AM PT on March 22)
- After processing, the agent sets `status: processed` in front-matter
- The agent may add `processed_at` to front-matter for audit

### Timing

The agent uses `created` (date) and entry timestamps (`HH:MM:SS`) to correlate notes with external events. For example, a note at `14:41:33` on `2026-03-21` can be matched against calendar entries and email activity in that time window.

## Constraints

- No database. The filesystem is the store.
- No network dependency. The app works fully offline.
- No rich-text rendering. Markdown is displayed as syntax-highlighted source.
- No agent orchestration inside the app. Agents are separate processes.
- No search. Agents and Obsidian handle retrieval.
- No inline math evaluation (deferred to v2).
- No task counts or status badges.
- Files must remain valid Markdown readable by Obsidian, any text editor, and `grep`.

## v2 Candidates

- Inline math evaluation (`= expr` with computed result on the next line)
- Input position toggle (top/bottom)
- Configurable syntax highlight theme
- iOS companion app
- Cross-platform (Tauri) if needed

## Open Questions

None at this time.
