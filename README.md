# MacCleaner

A free, open-source CleanMyMac replacement built with native macOS tools.

![macOS](https://img.shields.io/badge/macOS-Sequoia%20%7C%20Sonoma%20%7C%20Ventura-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Bash](https://img.shields.io/badge/bash-5.0%2B-orange)

## Overview

MacCleaner is a comprehensive system maintenance tool that provides all the functionality of CleanMyMac using native macOS commands and shell scripting. It includes both a full-featured command-line interface (19 menu options) and a native macOS GUI application.

**Why MacCleaner?**
- **Free** - No $40/year subscription
- **Transparent** - See exactly what gets deleted (open source)
- **Safe** - Confirmation prompts, dry-run mode, conservative defaults
- **Native** - Uses built-in macOS tools, no third-party dependencies
- **AI-Powered** - Optional intelligent analysis via local LLM

## Features

### System Junk Cleanup
- User caches (`~/Library/Caches`)
- System logs and crash reports
- Trash emptying
- Mail attachments (cached copies)

### Application Management
- **App Uninstaller** - Remove apps + all associated files (Application Support, Preferences, Caches, Containers)
- **App Leftovers Detector** - Find orphaned files from previously uninstalled apps
- **Update Checker** - Quick access to App Store updates

### Startup & Background Items
- **Login Items** - View apps that launch at startup, quick access to System Settings
- **Background Items Scanner** - Audit LaunchAgents and LaunchDaemons (user and system)

### Developer Tools (CLI only)
- Xcode DerivedData and Archives cleanup
- Docker system prune
- Homebrew cache cleanup
- npm/pip cache cleanup

### Browser Cleanup
- Safari, Chrome, Firefox, Brave cache clearing

### System Maintenance
- DNS cache flush
- Inactive memory purge
- Large files scanner (Downloads, Desktop, Documents, Movies)

### AI-Powered Analysis
- Integrates with local Ollama LLM via `mac_maintainer` agent
- Categorizes cleanup opportunities: SAFE / CAUTION / DANGEROUS
- Provides educational context about system files
- Generates specific, safe cleanup commands

## Installation

### Quick Start

```bash
# Clone the repository
git clone git@github.com:Scargiver-cyber/MacCleaner.git
cd MacCleaner

# Run the CLI
./mac_cleaner.sh

# Or open the GUI app
open MacCleaner.app
```

### Add to Applications (Spotlight access)

```bash
ln -s "$(pwd)/MacCleaner.app" /Applications/MacCleaner.app
```

Now launch with `Cmd+Space` → "MacCleaner"

### Set Up Keyboard Shortcut (Optional)

1. Open **Automator** → Create **Quick Action**
2. Set "Workflow receives" → **no input**
3. Add **Run Shell Script** action:
   ```bash
   open /path/to/MacCleaner/MacCleaner.app
   ```
4. Save as "Mac Cleaner"
5. Go to **System Settings → Keyboard → Keyboard Shortcuts → Services**
6. Assign shortcut (e.g., `Ctrl+Opt+Cmd+C`)

## Usage

### GUI Application

```bash
open MacCleaner.app
```

**Menu Structure:**
- **Quick Clean** - One-click safe cleanup (caches, logs, trash, Homebrew, npm)
- **Full Menu** → System Junk, Applications, More...

### Command Line Interface

```bash
# Interactive menu (19 options)
./mac_cleaner.sh

# Quick safe cleanup (no prompts)
./mac_cleaner.sh --quick

# Generate analysis report for AI
./mac_cleaner.sh --analyze

# Preview without making changes
./mac_cleaner.sh --dry-run --quick

# Show help
./mac_cleaner.sh --help
```

### CLI Menu Options

```
ANALYSIS & OVERVIEW
  1)  Quick system overview
  2)  Full analysis (for AI agent)
  3)  Run AI-powered analysis
  4)  Large files scanner

SYSTEM JUNK (Safe)
  5)  Quick cleanup (caches, logs, trash)
  6)  User caches
  7)  System logs
  8)  Empty Trash
  9)  Mail attachments

APPLICATIONS
  10) App uninstaller
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
  18) Browser caches
  19) System maintenance (DNS, memory)
```

## Safety Features

MacCleaner prioritizes data safety:

- **Confirmation Prompts** - Every destructive action requires confirmation
- **Dry Run Mode** - Preview what would be deleted with `--dry-run`
- **Conservative Defaults** - Only targets safe-to-delete files
- **Logging** - All actions logged to `logs/mac_cleaner_YYYYMMDD.log`
- **Trash First** - App uninstaller moves to Trash instead of permanent delete
- **Educational Context** - AI analysis explains what files are before recommending deletion

### What MacCleaner Will NEVER Delete

- System files (`/System`, `/usr`, `/bin`, `/sbin`)
- Application data without confirmation
- Keychain files
- Active application preferences
- Files over 1GB without explicit confirmation

## AI-Powered Analysis (Optional)

Requires [Ollama](https://ollama.ai) running locally with a model like `qwen2.5` or `llama3.1`.

```bash
# Generate system analysis
./mac_cleaner.sh --analyze > /tmp/analysis.txt

# Run AI analysis (requires ai-terminal agent system)
python scripts/agent_prompt.py mac_maintainer \
  --objective "Analyze my Mac and recommend safe cleanup actions" \
  --var-file disk_report /tmp/analysis.txt \
  --execute
```

The AI agent categorizes findings:
- **SAFE** - Can delete without concern (caches, old logs)
- **CAUTION** - Review before deleting (app support folders)
- **DANGEROUS** - Do not delete (system files, active app data)

## File Structure

```
MacCleaner/
├── mac_cleaner.sh          # Main CLI script (1,900+ lines)
├── MacCleaner.app/         # Native macOS GUI application
├── MacCleaner.applescript  # AppleScript source for GUI
├── mac_maintainer.json     # AI agent definition
├── launch_mac_cleaner.sh   # Shortcut launcher script
├── MAC-CLEANER-SETUP.md    # Detailed setup guide
└── README.md               # This file
```

## Comparison with CleanMyMac

| Feature | CleanMyMac | MacCleaner |
|---------|------------|------------|
| System Junk | ✅ | ✅ |
| Trash Cleanup | ✅ | ✅ |
| Mail Attachments | ✅ | ✅ |
| Login Items | ✅ | ✅ |
| Background Items | ✅ | ✅ |
| App Uninstaller | ✅ | ✅ |
| App Leftovers | ✅ | ✅ |
| Large Files | ✅ | ✅ |
| Browser Caches | ✅ | ✅ |
| System Maintenance | ✅ | ✅ |
| Developer Tools | ❌ | ✅ |
| AI Analysis | ❌ | ✅ |
| Open Source | ❌ | ✅ |
| **Price** | **$40/year** | **Free** |

## Requirements

- macOS 13+ (Ventura, Sonoma, Sequoia)
- Bash 5.0+
- Optional: [Ollama](https://ollama.ai) for AI analysis

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details.

## Author

**Jason Tilson**
- GitHub: [@Scargiver-cyber](https://github.com/Scargiver-cyber)
- Email: jason.tilson@gmail.com

---

*Built as a learning project demonstrating Bash scripting, AppleScript automation, and macOS system administration.*
