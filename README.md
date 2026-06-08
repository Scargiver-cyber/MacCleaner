# MacCleaner

A free, open-source CleanMyMac alternative built entirely with native macOS tools.

![macOS](https://img.shields.io/badge/macOS-Sequoia%20%7C%20Sonoma%20%7C%20Ventura-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Bash](https://img.shields.io/badge/bash-5.0%2B-orange)

MacCleaner cleans caches, logs, app leftovers, and developer cruft using built-in macOS commands — no subscription, no black-box binary, no third-party dependencies.

---

## Quick start

```bash
# Clone via HTTPS
git clone https://github.com/Scargiver-cyber/MacCleaner.git
cd MacCleaner

# Make the script executable (first time only)
chmod +x mac_cleaner.sh

# Preview what would be cleaned — no changes made
./mac_cleaner.sh --dry-run --quick

# Run the interactive menu
./mac_cleaner.sh
```

That's it. No install step, no pip packages, nothing to configure.

---

## What it does

```
ANALYSIS & OVERVIEW
  1)  Quick system overview
  2)  Full analysis report
  3)  AI-powered analysis (optional — see below)
  4)  Large files scanner

SYSTEM JUNK (safe)
  5)  Quick cleanup (caches, logs, trash)
  6)  User caches
  7)  System logs
  8)  Empty Trash
  9)  Mail attachments

APPLICATIONS
  10) App uninstaller (removes all related files)
  11) App leftovers detector
  12) Check for app updates

STARTUP & BACKGROUND
  13) Login items
  14) Background items (LaunchAgents)

DEVELOPER TOOLS
  15) Xcode cleanup
  16) Docker cleanup
  17) Homebrew cleanup

BROWSERS & MAINTENANCE
  18) Browser caches (Safari, Chrome, Firefox, Brave)
  19) System maintenance (DNS flush, memory purge)
```

---

## Command-line flags

| Flag | What it does |
|------|-------------|
| _(none)_ | Opens the interactive menu |
| `--quick` | Runs a safe cleanup with no prompts (caches, logs, trash, Homebrew, npm) |
| `--analyze` | Prints a detailed system report — pipe it to a file for review |
| `--dry-run` | Shows what would be deleted without touching anything |
| `--help` | Shows usage summary |

Examples:

```bash
# Safe cleanup, no prompts
./mac_cleaner.sh --quick

# See what --quick would do before running it
./mac_cleaner.sh --dry-run --quick

# Save a full report to a file
./mac_cleaner.sh --analyze > ~/Desktop/mac-report.txt
```

---

## GUI application

The repo includes `MacCleaner.app`, a native macOS app that wraps the script in dialog boxes. To use it:

```bash
open MacCleaner.app
```

Or copy it to Applications so it shows up in Spotlight:

```bash
cp -r MacCleaner.app /Applications/
```

### Build the app yourself (recommended after cloning)

The `.app` bundle in the repo was compiled from `MacCleaner.applescript`. To rebuild it on your own machine:

```bash
osacompile -o MacCleaner.app MacCleaner.applescript
```

You only need to do this once. After that, `open MacCleaner.app` works normally.

---

## Make it yours

### Change which paths get cleaned

Open `mac_cleaner.sh` and find the `quick_cleanup` function (around line 267). The paths it cleans are listed there. Add or remove entries to match your setup.

**Before** (default: cleans `~/Library/Caches`):
```bash
if [[ -d ~/Library/Caches ]]; then
    local cache_size_kb=$(get_size_kb ~/Library/Caches)
    ...
```

**After** (add a custom cache path, e.g. for a specific app):
```bash
if [[ -d ~/Library/Caches ]]; then
    local cache_size_kb=$(get_size_kb ~/Library/Caches)
    ...

# Your custom addition:
if [[ -d ~/Library/Caches/MyApp ]]; then
    rm -rf ~/Library/Caches/MyApp/* 2>/dev/null || true
fi
```

### Change where logs are written

By default, logs go to `./logs/` next to the script. Override with an environment variable:

```bash
MACCLEANER_LOG_DIR=/tmp ./mac_cleaner.sh --quick
```

### Point the app at a different copy of the script

If you move `mac_cleaner.sh` somewhere else, set `MACCLEANER_SCRIPT` before opening the app:

```bash
export MACCLEANER_SCRIPT=/path/to/your/mac_cleaner.sh
open MacCleaner.app
```

---

## Optional: AI-powered analysis

Menu option 3 can call an Ollama-backed AI agent to review your disk report and suggest cleanup steps. This is **fully optional** — the rest of the tool works fine without it.

To enable it:

1. Install [Ollama](https://ollama.ai) and pull a model (e.g. `ollama pull qwen2.5`).
2. Set up `agent_prompt.py` and `mac_maintainer.json` from this repo in a local agent system.
3. Point the script at `agent_prompt.py`:

```bash
export MACCLEANER_AGENT_SCRIPT=/path/to/agent_prompt.py
./mac_cleaner.sh
# then choose option 3
```

If `MACCLEANER_AGENT_SCRIPT` is not set, option 3 falls back to printing the plain analysis report.

---

## Safety

- Every destructive action asks for confirmation before running.
- `--dry-run` shows exactly what would be deleted without touching anything.
- The app uninstaller (option 10) moves files to Trash instead of permanently deleting them.
- All actions are logged to `./logs/mac_cleaner_YYYYMMDD.log`.

Things MacCleaner will never delete without an explicit confirmation prompt:

- System folders (`/System`, `/usr`, `/bin`, `/sbin`)
- App preferences (`~/Library/Preferences`)
- Keychain files
- Anything over 1 GB

---

## Troubleshooting

**"Permission denied" when running the script**

```bash
chmod +x mac_cleaner.sh
```

**"App is damaged" or macOS blocks the app from opening**

```bash
xattr -cr MacCleaner.app
```

Then try opening it again.

**The app can't find mac_cleaner.sh**

Make sure `mac_cleaner.sh` is in the same folder as `MacCleaner.app`. If they are in different places, set the env var:

```bash
export MACCLEANER_SCRIPT=/full/path/to/mac_cleaner.sh
open MacCleaner.app
```

**Logs not showing up**

Logs are written to `./logs/` next to the script. If that directory is read-only, override the location:

```bash
MACCLEANER_LOG_DIR=~/Desktop/logs ./mac_cleaner.sh
```

**Quick cleanup reports 0 bytes freed**

Most browsers and apps re-create their caches immediately after they are cleared. The freed space is real — it just fills up quickly during normal use.

---

## Requirements

- macOS 13 or later (Ventura, Sonoma, Sequoia)
- Bash 5.0 or later (ships with macOS)
- Optional: [Ollama](https://ollama.ai) for AI-powered analysis

---

## License

MIT — see [LICENSE](LICENSE) for details.

## Author

**Jason Tilson** — [github.com/Scargiver-cyber](https://github.com/Scargiver-cyber)

*Built as a learning project demonstrating Bash scripting, AppleScript automation, and macOS system administration.*
