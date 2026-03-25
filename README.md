# Braindump

A native macOS menu bar app for capturing thoughts, observations, and tasks throughout the day. Notes are stored as daily Markdown files with YAML front-matter, compatible with Obsidian. The app acts as an inbox: autonomous agents process, organize, and clear notes on a regular cadence.

## Features

- **Quick capture** — CMD+N from anywhere to start a new timestamped entry
- **Daily Markdown files** — one `.md` file per day with `## HH:MM:SS` entries
- **Obsidian compatible** — valid Markdown with YAML front-matter, readable by any editor
- **Configurable global hotkey** — default Ctrl+Shift+Space to toggle the panel
- **Day navigation** — CMD+Left/Right to browse past days (read-only), CMD+K to jump to any date with natural language ("yesterday", "last monday", "march 21")
- **Syntax highlighting** — fenced code blocks with per-language keyword coloring (SQL, etc.)
- **Inline math** — type `math` then expressions with variables (`x = 10`, `x * 5 =` evaluates to `50`)
- **Auto-closing brackets** — `(`, `[`, `{`, `` ` `` auto-close with cursor between
- **Markdown link insertion** — CMD+L or paste a URL over selected text
- **Custom colors** — configurable text and background colors
- **Appearance** — system, light, or dark mode
- **File watching** — external changes (from agents or Obsidian) reflected in real-time

## Tech Stack

- **Platform**: macOS 14.0+ (Sonoma)
- **Language**: Swift 5.9+
- **UI**: SwiftUI + AppKit (NSTextView for editor, NSWindow for panels)
- **Build**: Xcode 26.3, xcodegen for project generation
- **Storage**: Filesystem (no database)
- **Dependencies**: Zero third-party dependencies

## Prerequisites

- macOS 14.0 or later
- Xcode 26.3+ (or Xcode Command Line Tools)
- [xcodegen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Installation

```bash
git clone https://github.com/dcnu/braindump.git
cd braindump/Braindump
xcodegen generate
xcodebuild build -scheme Braindump -destination 'platform=macOS' -quiet
```

Launch the built app:

```bash
open ~/Library/Developer/Xcode/DerivedData/Braindump-*/Build/Products/Debug/Braindump.app
```

Or open `Braindump.xcodeproj` in Xcode and press CMD+R.

## Usage

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+Shift+Space | Toggle panel (global, configurable) |
| CMD+N | New entry (from anywhere when app is active) |
| CMD+Enter | Submit entry |
| Escape | Cancel draft / edit |
| CMD+Delete | Delete entry |
| CMD+Left/Right | Navigate between days |
| CMD+Up/Down | Select entry |
| CMD+K | Jump to date |
| CMD+L | Insert markdown link |
| CMD+, | Settings |
| CMD+/ | Keyboard shortcuts overlay |

### File Format

Notes are stored at `~/Documents/Obsidian/braindump/` (configurable in settings).

```markdown
---
created: 2026-03-24
edited: 2026-03-24T14:30:00-07:00
status: active
---

## 14:30:00

Quick thought about the project

## 14:45:12

- [ ] Follow up on this task
- [ ] Review the proposal
```

### Agent Contract

External agents can process notes by:
1. Reading `.md` files from the braindump directory
2. Setting `status: processed` in YAML front-matter when done
3. Adding custom front-matter fields (`processed_at`, `agent`, `tags`)

The app watches for external file changes and updates the UI in real-time.

## Testing

```bash
cd Braindump

# Unit and integration tests (headless, no UI focus stealing)
xcodebuild test -scheme Braindump -destination 'platform=macOS' -only-testing:BraindumpTests

# UI tests (launches the app, takes screen focus)
xcodebuild test -scheme Braindump -destination 'platform=macOS' -only-testing:BraindumpUITests
```

138 unit/integration tests covering: data models, file store, index manager, date parsing, math evaluation, color extensions, settings persistence, app state logic.

<!-- AUTO:START Project Structure -->
## Project Structure

```
Braindump/
  Braindump/
    App/
      AppDelegate.swift           # NSWindow management, hotkey, menu bar
      AppState.swift              # Observable state: navigation, drafts, edits
      BraindumpApp.swift          # @main entry point
    Editor/
      BraindumpTextView.swift     # NSTextView subclass: auto-close brackets, links
      HighlightTheme.swift        # Token colors and fonts
      MarkdownHighlighter.swift   # NSTextStorageDelegate syntax highlighting
    Models/
      DailyFile.swift             # Entry, FrontMatter, DailyFile + parse/serialize
      IndexCache.swift            # IndexEntry for metadata cache
      Settings.swift              # Observable settings backed by UserDefaults
    Services/
      FileStore.swift             # Read/write/delete .md files
      FileWatcher.swift           # DispatchSource directory watcher
      HotkeyManager.swift         # Global hotkey via NSEvent monitors
      IndexManager.swift          # Build/reconcile index.json
    Utilities/
      ColorExtensions.swift       # Color hex conversion
      Constants.swift             # App constants
      DateFormatting.swift        # Logical date, timestamps, 12h/24h
      DateParser.swift            # Natural language date parsing
      MathEvaluator.swift         # Recursive-descent math parser
    Views/
      AutoClosingTextEditor.swift # NSViewRepresentable editor wrapper
      ContentView.swift           # Root view with keyboard shortcuts
      DateJumpOverlay.swift       # CMD+K date jump with autocomplete
      DayView.swift               # Daily entries display
      EntryRow.swift              # Single entry row
      HotkeyRecorderView.swift   # Hotkey capture widget
      SettingsView.swift          # Settings window
      ShortcutsOverlay.swift      # CMD+/ shortcuts reference
  BraindumpTests/                 # Unit and integration tests
  BraindumpUITests/               # UI automation tests
  project.yml                     # xcodegen project spec
TODO/
  requirements.md                 # Product requirements
```
<!-- AUTO:END Project Structure -->

## License

All rights reserved. Copyright (c) 2026 [github.com/dcnu](https://github.com/dcnu).
