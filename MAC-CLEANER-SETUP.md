# Mac Cleaner GUI Setup

Your CleanMyMac replacement with native macOS GUI.

## Quick Start

### Option 1: Run the App Directly
```bash
open ~/ai-terminal/apps/MacCleaner.app
```

### Option 2: Add to Dock
1. Open Finder
2. Navigate to `~/ai-terminal/apps/`
3. Drag `MacCleaner.app` to your Dock

### Option 3: Add to Applications (recommended)
```bash
ln -s ~/ai-terminal/apps/MacCleaner.app /Applications/MacCleaner.app
```

Now it appears in Spotlight and Launchpad!

---

## Setting Up a Keyboard Shortcut

### Method 1: Automator Quick Action (Recommended)

1. Open **Automator** (Cmd+Space, type "Automator")
2. Choose **Quick Action** (or "Service" on older macOS)
3. Set "Workflow receives" to **no input** in **any application**
4. Add a **Run Shell Script** action
5. Paste this command:
   ```bash
   open /Users/jasontilson/ai-terminal/apps/MacCleaner.app
   ```
6. Save as "Mac Cleaner" (Cmd+S)
7. Go to **System Settings → Keyboard → Keyboard Shortcuts → Services**
8. Find "Mac Cleaner" and assign a shortcut (e.g., `Ctrl+Opt+Cmd+C`)

### Method 2: Raycast/Alfred (if installed)

**Raycast:**
1. Open Raycast Preferences
2. Go to Extensions → Script Commands
3. Add new script pointing to:
   ```
   /Users/jasontilson/ai-terminal/scripts/launch_mac_cleaner.sh
   ```

**Alfred:**
1. Create a Workflow
2. Add Hotkey trigger
3. Connect to "Run Script" action with:
   ```
   open /Users/jasontilson/ai-terminal/apps/MacCleaner.app
   ```

### Method 3: BetterTouchTool / Karabiner

Map any key combination to run:
```bash
open /Users/jasontilson/ai-terminal/apps/MacCleaner.app
```

---

## App Features

| Button | Action |
|--------|--------|
| **Quick Clean** | Safe cleanup (caches, logs, trash, Homebrew, npm) |
| **Full Menu** | Opens interactive Terminal menu or quick actions |
| **Interactive Terminal** | Full CLI experience with all options |

## Command Line (still available)

```bash
# Interactive menu
./scripts/mac_cleaner.sh

# Quick safe cleanup
./scripts/mac_cleaner.sh --quick

# Generate analysis
./scripts/mac_cleaner.sh --analyze
```

---

## Troubleshooting

### "App is damaged" or won't open
```bash
xattr -cr ~/ai-terminal/apps/MacCleaner.app
```

### Permissions issues
```bash
chmod +x ~/ai-terminal/scripts/mac_cleaner.sh
chmod +x ~/ai-terminal/scripts/launch_mac_cleaner.sh
```

### Recompile the app
```bash
osacompile -o ~/ai-terminal/apps/MacCleaner.app ~/ai-terminal/scripts/MacCleaner.applescript
```
