#!/bin/bash
#
# mac_cleaner.sh - CleanMyMac replacement using native macOS tools
#
# Usage:
#   ./mac_cleaner.sh              # Interactive menu
#   ./mac_cleaner.sh --analyze    # Run analysis for AI agent
#   ./mac_cleaner.sh --quick      # Safe quick cleanup (no prompts)
#   ./mac_cleaner.sh --help       # Show help
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${MACCLEANER_LOG_DIR:-$SCRIPT_DIR/logs}"
LOG_FILE="$LOG_DIR/mac_cleaner_$(date +%Y%m%d).log"
DRY_RUN=false

# Ensure logs directory exists
mkdir -p "$LOG_DIR"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Print with color
print_color() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Print section header
print_header() {
    echo ""
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BOLD$CYAN" "  $1"
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Get human-readable size from KB
human_size_kb() {
    local kb=$1
    if [[ $kb -ge 1048576 ]]; then
        echo "$(echo "scale=2; $kb / 1048576" | bc) GB"
    elif [[ $kb -ge 1024 ]]; then
        echo "$(echo "scale=1; $kb / 1024" | bc) MB"
    else
        echo "${kb} KB"
    fi
}

# Get human-readable size from bytes (legacy, for compatibility)
human_size() {
    local bytes=$1
    if [[ -z "$bytes" || "$bytes" == "0" ]]; then
        echo "0 bytes"
        return
    fi
    if [[ $bytes -ge 1073741824 ]]; then
        echo "$(echo "scale=2; $bytes / 1073741824" | bc) GB"
    elif [[ $bytes -ge 1048576 ]]; then
        echo "$(echo "scale=1; $bytes / 1048576" | bc) MB"
    elif [[ $bytes -ge 1024 ]]; then
        echo "$(echo "scale=0; $bytes / 1024" | bc) KB"
    else
        echo "$bytes bytes"
    fi
}

# Get folder size in KB (safer for bash arithmetic)
get_size_kb() {
    local path=$1
    if [[ -e "$path" ]]; then
        du -sk "$path" 2>/dev/null | awk '{print $1}' | tr -d '\n' || echo "0"
    else
        echo "0"
    fi
}

# Get folder size in bytes (for display only, not arithmetic)
get_size_bytes() {
    local path=$1
    if [[ -e "$path" ]]; then
        local kb=$(du -sk "$path" 2>/dev/null | awk '{print $1}')
        echo $((kb * 1024))
    else
        echo "0"
    fi
}

# Get folder size human readable
get_size() {
    local path=$1
    if [[ -e "$path" ]]; then
        du -sh "$path" 2>/dev/null | awk '{print $1}' || echo "0B"
    else
        echo "0B"
    fi
}

# Confirmation prompt
confirm() {
    local message=$1
    local default=${2:-n}

    if [[ "$default" == "y" ]]; then
        read -p "$message [Y/n]: " response
        [[ -z "$response" || "$response" =~ ^[Yy] ]]
    else
        read -p "$message [y/N]: " response
        [[ "$response" =~ ^[Yy] ]]
    fi
}

# Safe delete - moves to trash instead of rm
safe_delete() {
    local path=$1
    if [[ -e "$path" ]]; then
        if $DRY_RUN; then
            print_color "$YELLOW" "  [DRY RUN] Would delete: $path"
        else
            # Use macOS trash if available, otherwise rm
            if command -v trash &> /dev/null; then
                trash "$path"
                print_color "$GREEN" "  ✓ Moved to Trash: $path"
            else
                rm -rf "$path"
                print_color "$GREEN" "  ✓ Deleted: $path"
            fi
            log "Deleted: $path"
        fi
    fi
}

# Analyze system for AI agent
analyze_system() {
    print_header "SYSTEM ANALYSIS FOR MAC MAINTAINER"

    echo ""
    echo "=== SYSTEM INFORMATION ==="
    echo "macOS Version: $(sw_vers -productVersion)"
    echo "Build: $(sw_vers -buildVersion)"
    echo "Hardware: $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'Unknown')"
    echo "Memory: $(sysctl -n hw.memsize 2>/dev/null | awk '{print $1/1073741824 " GB"}' || echo 'Unknown')"
    echo ""

    echo "=== DISK USAGE ==="
    df -h / | tail -1 | awk '{print "Total: "$2", Used: "$3", Available: "$4", Usage: "$5}'
    echo ""

    echo "=== USER CACHES ==="
    if [[ -d ~/Library/Caches ]]; then
        echo "Total ~/Library/Caches: $(get_size ~/Library/Caches)"
        echo ""
        echo "Top 15 cache folders by size:"
        du -sh ~/Library/Caches/*/ 2>/dev/null | sort -hr | head -15
    fi
    echo ""

    echo "=== SYSTEM CACHES ==="
    if [[ -d /Library/Caches ]]; then
        echo "Total /Library/Caches: $(get_size /Library/Caches)"
    fi
    echo ""

    echo "=== LOGS ==="
    echo "User logs ~/Library/Logs: $(get_size ~/Library/Logs)"
    echo "System logs /var/log: $(get_size /var/log 2>/dev/null || echo 'N/A')"
    echo "Diagnostic reports: $(get_size ~/Library/Logs/DiagnosticReports)"
    echo ""

    echo "=== DOWNLOADS ==="
    echo "Downloads folder: $(get_size ~/Downloads)"
    if [[ -d ~/Downloads ]]; then
        echo "Files older than 30 days:"
        find ~/Downloads -maxdepth 1 -type f -mtime +30 -exec ls -lh {} \; 2>/dev/null | head -10
    fi
    echo ""

    echo "=== TRASH ==="
    echo "Trash: $(get_size ~/.Trash)"
    echo ""

    echo "=== DEVELOPER TOOLS ==="

    # Xcode
    if [[ -d ~/Library/Developer ]]; then
        echo "Xcode Developer folder: $(get_size ~/Library/Developer)"
        [[ -d ~/Library/Developer/Xcode/DerivedData ]] && echo "  - DerivedData: $(get_size ~/Library/Developer/Xcode/DerivedData)"
        [[ -d ~/Library/Developer/Xcode/Archives ]] && echo "  - Archives: $(get_size ~/Library/Developer/Xcode/Archives)"
        [[ -d ~/Library/Developer/Xcode/iOS\ DeviceSupport ]] && echo "  - iOS DeviceSupport: $(get_size ~/Library/Developer/Xcode/iOS\ DeviceSupport)"
        [[ -d ~/Library/Developer/CoreSimulator ]] && echo "  - Simulators: $(get_size ~/Library/Developer/CoreSimulator)"
    fi

    # Docker
    if [[ -d ~/Library/Containers/com.docker.docker ]]; then
        echo "Docker: $(get_size ~/Library/Containers/com.docker.docker)"
    fi

    # Homebrew
    if command -v brew &> /dev/null; then
        echo "Homebrew cache: $(get_size "$(brew --cache)" 2>/dev/null || echo 'N/A')"
    fi

    # npm
    if [[ -d ~/.npm ]]; then
        echo "npm cache: $(get_size ~/.npm)"
    fi

    # pip
    if [[ -d ~/Library/Caches/pip ]]; then
        echo "pip cache: $(get_size ~/Library/Caches/pip)"
    fi

    # Cargo/Rust
    if [[ -d ~/.cargo ]]; then
        echo "Cargo: $(get_size ~/.cargo)"
    fi

    echo ""

    echo "=== MAIL ==="
    if [[ -d ~/Library/Mail ]]; then
        echo "Mail data: $(get_size ~/Library/Mail)"
    fi
    if [[ -d ~/Library/Containers/com.apple.mail/Data/Library/Mail\ Downloads ]]; then
        echo "Mail attachments: $(get_size ~/Library/Containers/com.apple.mail/Data/Library/Mail\ Downloads)"
    fi
    echo ""

    echo "=== BROWSERS ==="
    [[ -d ~/Library/Caches/com.apple.Safari ]] && echo "Safari cache: $(get_size ~/Library/Caches/com.apple.Safari)"
    [[ -d ~/Library/Caches/Google/Chrome ]] && echo "Chrome cache: $(get_size ~/Library/Caches/Google/Chrome)"
    [[ -d ~/Library/Caches/Firefox ]] && echo "Firefox cache: $(get_size ~/Library/Caches/Firefox)"
    [[ -d ~/Library/Caches/BraveSoftware ]] && echo "Brave cache: $(get_size ~/Library/Caches/BraveSoftware)"
    echo ""

    echo "=== TIME MACHINE ==="
    tmutil listlocalsnapshotdates / 2>/dev/null || echo "No local snapshots or Time Machine not configured"
    echo ""

    echo "=== LARGE FILES (>500MB in common locations) ==="
    find ~/Downloads ~/Desktop ~/Documents -type f -size +500M 2>/dev/null | while read file; do
        echo "$(get_size "$file") - $file"
    done | head -20
    echo ""

    echo "=== END OF ANALYSIS ==="
}

# Quick safe cleanup - no prompts
quick_cleanup() {
    print_header "QUICK SAFE CLEANUP"
    local total_freed_kb=0

    echo ""
    print_color "$YELLOW" "This will clean SAFE items only (user caches, logs, Trash)..."
    echo ""

    # User caches
    if [[ -d ~/Library/Caches ]]; then
        local cache_size_kb=$(get_size_kb ~/Library/Caches)
        print_color "$BLUE" "Clearing user caches ($(human_size_kb $cache_size_kb))..."
        if ! $DRY_RUN; then
            rm -rf ~/Library/Caches/* 2>/dev/null || true
            total_freed_kb=$((total_freed_kb + cache_size_kb))
        fi
    fi

    # Old logs (older than 7 days)
    if [[ -d ~/Library/Logs ]]; then
        print_color "$BLUE" "Clearing old logs (>7 days)..."
        if ! $DRY_RUN; then
            find ~/Library/Logs -type f -mtime +7 -delete 2>/dev/null || true
        fi
    fi

    # Crash reports (older than 30 days)
    if [[ -d ~/Library/Logs/DiagnosticReports ]]; then
        print_color "$BLUE" "Clearing old crash reports (>30 days)..."
        if ! $DRY_RUN; then
            find ~/Library/Logs/DiagnosticReports -type f -mtime +30 -delete 2>/dev/null || true
        fi
    fi

    # Trash
    if [[ -d ~/.Trash ]]; then
        local trash_size_kb=$(get_size_kb ~/.Trash)
        print_color "$BLUE" "Emptying Trash ($(human_size_kb $trash_size_kb))..."
        if ! $DRY_RUN; then
            rm -rf ~/.Trash/* 2>/dev/null || true
            total_freed_kb=$((total_freed_kb + trash_size_kb))
        fi
    fi

    # Homebrew cache
    if command -v brew &> /dev/null; then
        print_color "$BLUE" "Clearing Homebrew cache..."
        if ! $DRY_RUN; then
            brew cleanup -s 2>/dev/null || true
        fi
    fi

    # pip cache
    if [[ -d ~/Library/Caches/pip ]]; then
        local pip_size_kb=$(get_size_kb ~/Library/Caches/pip)
        print_color "$BLUE" "Clearing pip cache ($(human_size_kb $pip_size_kb))..."
        if ! $DRY_RUN; then
            rm -rf ~/Library/Caches/pip/* 2>/dev/null || true
            total_freed_kb=$((total_freed_kb + pip_size_kb))
        fi
    fi

    # npm cache
    if command -v npm &> /dev/null; then
        print_color "$BLUE" "Clearing npm cache..."
        if ! $DRY_RUN; then
            npm cache clean --force 2>/dev/null || true
        fi
    fi

    echo ""
    print_color "$GREEN" "✓ Quick cleanup complete!"
    print_color "$GREEN" "  Estimated space freed: $(human_size_kb $total_freed_kb)"
    log "Quick cleanup completed. Freed approximately $(human_size_kb $total_freed_kb)"
}

# Individual cleanup functions
clean_user_caches() {
    print_header "USER CACHES CLEANUP"
    local total=0

    if [[ -d ~/Library/Caches ]]; then
        echo "Current size: $(get_size ~/Library/Caches)"
        echo ""
        echo "Top 10 cache folders:"
        du -sh ~/Library/Caches/*/ 2>/dev/null | sort -hr | head -10
        echo ""

        if confirm "Clear ALL user caches?"; then
            local size=$(get_size_bytes ~/Library/Caches)
            rm -rf ~/Library/Caches/* 2>/dev/null || true
            print_color "$GREEN" "✓ Cleared $(human_size $size) of user caches"
            log "Cleared user caches: $(human_size $size)"
        fi
    else
        print_color "$YELLOW" "No user caches folder found"
    fi
}

clean_logs() {
    print_header "LOGS CLEANUP"

    echo "User logs: $(get_size ~/Library/Logs)"
    echo "Diagnostic reports: $(get_size ~/Library/Logs/DiagnosticReports)"
    echo ""

    if confirm "Clear logs older than 7 days?"; then
        find ~/Library/Logs -type f -mtime +7 -delete 2>/dev/null || true
        print_color "$GREEN" "✓ Cleared old logs"
        log "Cleared old logs"
    fi

    if confirm "Clear all diagnostic/crash reports older than 30 days?"; then
        find ~/Library/Logs/DiagnosticReports -type f -mtime +30 -delete 2>/dev/null || true
        print_color "$GREEN" "✓ Cleared old crash reports"
        log "Cleared old crash reports"
    fi
}

clean_trash() {
    print_header "TRASH CLEANUP"

    if [[ -d ~/.Trash ]]; then
        local size=$(get_size ~/.Trash)
        echo "Trash size: $size"
        echo ""

        if confirm "Empty Trash?"; then
            rm -rf ~/.Trash/* 2>/dev/null || true
            print_color "$GREEN" "✓ Emptied Trash ($size freed)"
            log "Emptied Trash: $size"
        fi
    else
        print_color "$YELLOW" "Trash is empty"
    fi
}

clean_xcode() {
    print_header "XCODE CLEANUP"

    if [[ ! -d ~/Library/Developer/Xcode ]]; then
        print_color "$YELLOW" "Xcode not found"
        return
    fi

    echo "Xcode storage breakdown:"
    [[ -d ~/Library/Developer/Xcode/DerivedData ]] && echo "  DerivedData: $(get_size ~/Library/Developer/Xcode/DerivedData)"
    [[ -d ~/Library/Developer/Xcode/Archives ]] && echo "  Archives: $(get_size ~/Library/Developer/Xcode/Archives)"
    [[ -d ~/Library/Developer/Xcode/iOS\ DeviceSupport ]] && echo "  iOS DeviceSupport: $(get_size ~/Library/Developer/Xcode/iOS\ DeviceSupport)"
    [[ -d ~/Library/Developer/CoreSimulator ]] && echo "  Simulators: $(get_size ~/Library/Developer/CoreSimulator)"
    echo ""

    if [[ -d ~/Library/Developer/Xcode/DerivedData ]] && confirm "Clear DerivedData (build cache, regenerates automatically)?"; then
        rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
        print_color "$GREEN" "✓ Cleared DerivedData"
        log "Cleared Xcode DerivedData"
    fi

    if [[ -d ~/Library/Developer/Xcode/Archives ]] && confirm "Clear old Archives (old app builds)?"; then
        rm -rf ~/Library/Developer/Xcode/Archives/* 2>/dev/null || true
        print_color "$GREEN" "✓ Cleared Archives"
        log "Cleared Xcode Archives"
    fi

    print_color "$YELLOW" "Note: iOS DeviceSupport and Simulators are best managed through Xcode"
}

clean_docker() {
    print_header "DOCKER CLEANUP"

    if ! command -v docker &> /dev/null; then
        print_color "$YELLOW" "Docker not installed"
        return
    fi

    if ! docker info &> /dev/null; then
        print_color "$YELLOW" "Docker is not running"
        return
    fi

    echo "Docker disk usage:"
    docker system df
    echo ""

    if confirm "Run Docker system prune (removes unused data)?"; then
        docker system prune -f
        print_color "$GREEN" "✓ Docker pruned"
        log "Docker system prune completed"
    fi

    if confirm "Also remove unused volumes (CAUTION: may contain data)?"; then
        docker volume prune -f
        print_color "$GREEN" "✓ Docker volumes pruned"
        log "Docker volumes pruned"
    fi
}

clean_homebrew() {
    print_header "HOMEBREW CLEANUP"

    if ! command -v brew &> /dev/null; then
        print_color "$YELLOW" "Homebrew not installed"
        return
    fi

    local cache_size=$(get_size "$(brew --cache)" 2>/dev/null || echo "N/A")
    echo "Homebrew cache: $cache_size"
    echo ""

    if confirm "Run brew cleanup (removes old versions and cache)?"; then
        brew cleanup -s
        print_color "$GREEN" "✓ Homebrew cleaned"
        log "Homebrew cleanup completed"
    fi
}

clean_browsers() {
    print_header "BROWSER CACHE CLEANUP"

    echo "Browser cache sizes:"
    [[ -d ~/Library/Caches/com.apple.Safari ]] && echo "  Safari: $(get_size ~/Library/Caches/com.apple.Safari)"
    [[ -d ~/Library/Caches/Google/Chrome ]] && echo "  Chrome: $(get_size ~/Library/Caches/Google/Chrome)"
    [[ -d ~/Library/Caches/Firefox ]] && echo "  Firefox: $(get_size ~/Library/Caches/Firefox)"
    [[ -d ~/Library/Caches/BraveSoftware ]] && echo "  Brave: $(get_size ~/Library/Caches/BraveSoftware)"
    echo ""

    print_color "$YELLOW" "Note: Clearing browser cache will log you out of some websites"
    echo ""

    if [[ -d ~/Library/Caches/com.apple.Safari ]] && confirm "Clear Safari cache?"; then
        rm -rf ~/Library/Caches/com.apple.Safari/* 2>/dev/null || true
        print_color "$GREEN" "✓ Safari cache cleared"
    fi

    if [[ -d ~/Library/Caches/Google/Chrome ]] && confirm "Clear Chrome cache?"; then
        rm -rf ~/Library/Caches/Google/Chrome/* 2>/dev/null || true
        print_color "$GREEN" "✓ Chrome cache cleared"
    fi

    if [[ -d ~/Library/Caches/Firefox ]] && confirm "Clear Firefox cache?"; then
        rm -rf ~/Library/Caches/Firefox/* 2>/dev/null || true
        print_color "$GREEN" "✓ Firefox cache cleared"
    fi

    if [[ -d ~/Library/Caches/BraveSoftware ]] && confirm "Clear Brave cache?"; then
        rm -rf ~/Library/Caches/BraveSoftware/* 2>/dev/null || true
        print_color "$GREEN" "✓ Brave cache cleared"
    fi
}

system_maintenance() {
    print_header "SYSTEM MAINTENANCE"

    echo "Available maintenance tasks:"
    echo "  1. Flush DNS cache"
    echo "  2. Rebuild Spotlight index"
    echo "  3. Purge inactive memory"
    echo "  4. Verify disk"
    echo ""

    if confirm "Flush DNS cache?"; then
        sudo dscacheutil -flushcache
        sudo killall -HUP mDNSResponder 2>/dev/null || true
        print_color "$GREEN" "✓ DNS cache flushed"
        log "DNS cache flushed"
    fi

    if confirm "Purge inactive memory (may briefly slow system)?"; then
        sudo purge
        print_color "$GREEN" "✓ Memory purged"
        log "Memory purged"
    fi

    print_color "$YELLOW" "Note: Spotlight reindex and disk verify are intensive operations"
    print_color "$YELLOW" "Run manually if needed:"
    echo "  Spotlight: sudo mdutil -E /"
    echo "  Disk verify: diskutil verifyVolume /"
}

# ============================================================================
# NEW FEATURES - CleanMyMac Parity
# ============================================================================

# Login Items Management
manage_login_items() {
    print_header "LOGIN ITEMS"

    echo "Apps that open automatically when you log in:"
    echo ""

    # Get login items using osascript
    local login_items=$(osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null)

    if [[ -z "$login_items" || "$login_items" == "" ]]; then
        print_color "$GREEN" "No login items found."
    else
        echo "$login_items" | tr ',' '\n' | while read -r item; do
            item=$(echo "$item" | xargs)  # trim whitespace
            [[ -n "$item" ]] && echo "  • $item"
        done
    fi

    echo ""
    print_color "$CYAN" "To manage login items:"
    echo "  System Settings → General → Login Items"
    echo ""

    if confirm "Open Login Items settings?"; then
        open "x-apple.systempreferences:com.apple.LoginItems-Settings.extension"
    fi
}

# Background Items (LaunchAgents/LaunchDaemons)
scan_background_items() {
    print_header "BACKGROUND ITEMS"

    local user_agents=~/Library/LaunchAgents
    local system_agents=/Library/LaunchAgents
    local system_daemons=/Library/LaunchDaemons

    local total_count=0

    echo "Scanning for background processes..."
    echo ""

    # User LaunchAgents
    if [[ -d "$user_agents" ]]; then
        local user_count=$(ls -1 "$user_agents"/*.plist 2>/dev/null | wc -l | tr -d ' ')
        if [[ $user_count -gt 0 ]]; then
            print_color "$BOLD" "User LaunchAgents ($user_count items):"
            ls -1 "$user_agents"/*.plist 2>/dev/null | while read -r plist; do
                local name=$(basename "$plist" .plist)
                local status="enabled"
                # Check if disabled
                if launchctl print gui/$(id -u)/"$name" &>/dev/null; then
                    status="running"
                fi
                echo "  • $name"
            done
            total_count=$((total_count + user_count))
            echo ""
        fi
    fi

    # System LaunchAgents
    if [[ -d "$system_agents" ]]; then
        local sys_agent_count=$(ls -1 "$system_agents"/*.plist 2>/dev/null | wc -l | tr -d ' ')
        if [[ $sys_agent_count -gt 0 ]]; then
            print_color "$BOLD" "System LaunchAgents ($sys_agent_count items):"
            ls -1 "$system_agents"/*.plist 2>/dev/null | head -10 | while read -r plist; do
                echo "  • $(basename "$plist" .plist)"
            done
            [[ $sys_agent_count -gt 10 ]] && echo "  ... and $((sys_agent_count - 10)) more"
            total_count=$((total_count + sys_agent_count))
            echo ""
        fi
    fi

    # System LaunchDaemons
    if [[ -d "$system_daemons" ]]; then
        local daemon_count=$(ls -1 "$system_daemons"/*.plist 2>/dev/null | wc -l | tr -d ' ')
        if [[ $daemon_count -gt 0 ]]; then
            print_color "$BOLD" "System LaunchDaemons ($daemon_count items):"
            ls -1 "$system_daemons"/*.plist 2>/dev/null | head -10 | while read -r plist; do
                echo "  • $(basename "$plist" .plist)"
            done
            [[ $daemon_count -gt 10 ]] && echo "  ... and $((daemon_count - 10)) more"
            total_count=$((total_count + daemon_count))
            echo ""
        fi
    fi

    print_color "$CYAN" "Total background items: $total_count"
    echo ""

    # Identify potentially unwanted items
    print_color "$YELLOW" "Potentially removable (non-Apple) user agents:"
    ls -1 ~/Library/LaunchAgents/*.plist 2>/dev/null | while read -r plist; do
        local name=$(basename "$plist" .plist)
        # Skip Apple items
        if [[ ! "$name" =~ ^com\.apple\. ]]; then
            echo "  • $name"
        fi
    done

    echo ""
    print_color "$YELLOW" "To disable a launch agent:"
    echo "  launchctl unload ~/Library/LaunchAgents/<name>.plist"
    echo "  rm ~/Library/LaunchAgents/<name>.plist"
}

# App Leftovers Detector
find_app_leftovers() {
    print_header "APP LEFTOVERS"

    echo "Scanning for orphaned application support files..."
    echo ""

    local leftovers=()
    local total_size_kb=0

    # Check Application Support
    if [[ -d ~/Library/Application\ Support ]]; then
        for dir in ~/Library/Application\ Support/*/; do
            [[ ! -d "$dir" ]] && continue
            local app_name=$(basename "$dir")

            # Skip system/common folders
            [[ "$app_name" =~ ^(AddressBook|com\.apple\.|Apple|CrashReporter|SyncServices|CloudDocs).*$ ]] && continue

            # Check if corresponding app exists
            local found=false
            for app_dir in /Applications ~/Applications /System/Applications; do
                if [[ -d "$app_dir" ]]; then
                    # Check for app with similar name
                    if ls "$app_dir" 2>/dev/null | grep -qi "${app_name%% *}"; then
                        found=true
                        break
                    fi
                fi
            done

            if ! $found; then
                local size_kb=$(get_size_kb "$dir")
                if [[ $size_kb -gt 100 ]]; then  # Only show if > 100KB
                    leftovers+=("$dir|$size_kb")
                    total_size_kb=$((total_size_kb + size_kb))
                fi
            fi
        done
    fi

    # Check Preferences
    local pref_leftovers=()
    if [[ -d ~/Library/Preferences ]]; then
        for plist in ~/Library/Preferences/*.plist; do
            [[ ! -f "$plist" ]] && continue
            local plist_name=$(basename "$plist" .plist)

            # Skip Apple preferences
            [[ "$plist_name" =~ ^(com\.apple\.|Apple|NSGlobal|pbs|loginwindow).*$ ]] && continue

            # Extract app identifier
            local app_id=$(echo "$plist_name" | cut -d. -f1-3)

            # Very basic check - if it looks like an app bundle ID but app doesn't exist
            if [[ "$plist_name" =~ ^com\.[a-z]+\.[A-Za-z]+ ]]; then
                local app_guess=$(echo "$plist_name" | awk -F. '{print $3}')
                if ! ls /Applications 2>/dev/null | grep -qi "$app_guess"; then
                    pref_leftovers+=("$plist")
                fi
            fi
        done
    fi

    # Display results
    if [[ ${#leftovers[@]} -eq 0 && ${#pref_leftovers[@]} -eq 0 ]]; then
        print_color "$GREEN" "No significant app leftovers found!"
        return
    fi

    print_color "$BOLD" "Potential App Leftovers Found:"
    echo ""

    if [[ ${#leftovers[@]} -gt 0 ]]; then
        print_color "$CYAN" "Application Support folders ($(human_size_kb $total_size_kb)):"
        for item in "${leftovers[@]}"; do
            local dir=$(echo "$item" | cut -d'|' -f1)
            local size_kb=$(echo "$item" | cut -d'|' -f2)
            echo "  $(human_size_kb $size_kb) - $(basename "$dir")"
        done
        echo ""
    fi

    if [[ ${#pref_leftovers[@]} -gt 0 ]]; then
        print_color "$CYAN" "Orphaned Preferences (${#pref_leftovers[@]} files):"
        for plist in "${pref_leftovers[@]:0:10}"; do
            echo "  • $(basename "$plist")"
        done
        [[ ${#pref_leftovers[@]} -gt 10 ]] && echo "  ... and $((${#pref_leftovers[@]} - 10)) more"
        echo ""
    fi

    print_color "$YELLOW" "Total potential leftovers: $(human_size_kb $total_size_kb)"
    echo ""

    if confirm "Would you like to review and clean these leftovers?"; then
        clean_app_leftovers "${leftovers[@]}"
    fi
}

clean_app_leftovers() {
    local items=("$@")

    for item in "${items[@]}"; do
        local dir=$(echo "$item" | cut -d'|' -f1)
        local size_kb=$(echo "$item" | cut -d'|' -f2)
        local name=$(basename "$dir")

        echo ""
        if confirm "Delete '$name' ($(human_size_kb $size_kb))?"; then
            rm -rf "$dir"
            print_color "$GREEN" "  ✓ Deleted: $name"
            log "Deleted app leftover: $dir"
        fi
    done
}

# Mail Attachments Cleanup
clean_mail_attachments() {
    print_header "MAIL ATTACHMENTS"

    local mail_downloads=~/Library/Containers/com.apple.mail/Data/Library/Mail\ Downloads
    local mail_attachments=~/Library/Mail/V*/Attachments

    local total_size_kb=0

    echo "Scanning for mail attachments..."
    echo ""

    # Mail Downloads
    if [[ -d "$mail_downloads" ]]; then
        local dl_size_kb=$(get_size_kb "$mail_downloads")
        if [[ $dl_size_kb -gt 0 ]]; then
            print_color "$BOLD" "Mail Downloads: $(human_size_kb $dl_size_kb)"
            total_size_kb=$((total_size_kb + dl_size_kb))
        fi
    fi

    # Mail Attachments in mailboxes
    local attach_size_kb=0
    while IFS= read -r attach_dir; do
        if [[ -d "$attach_dir" ]]; then
            local this_size=$(get_size_kb "$attach_dir")
            attach_size_kb=$((attach_size_kb + this_size))
        fi
    done < <(find ~/Library/Mail -name "Attachments" -type d 2>/dev/null)

    if [[ $attach_size_kb -gt 0 ]]; then
        print_color "$BOLD" "Mailbox Attachments: $(human_size_kb $attach_size_kb)"
        total_size_kb=$((total_size_kb + attach_size_kb))
    fi

    echo ""

    if [[ $total_size_kb -eq 0 ]]; then
        print_color "$GREEN" "No mail attachments found to clean."
        return
    fi

    print_color "$CYAN" "Total Mail Attachments: $(human_size_kb $total_size_kb)"
    echo ""

    print_color "$YELLOW" "Note: These are cached copies. Originals remain on the mail server."
    echo ""

    if [[ -d "$mail_downloads" ]] && confirm "Clear Mail Downloads ($(get_size "$mail_downloads"))?"; then
        rm -rf "$mail_downloads"/* 2>/dev/null || true
        print_color "$GREEN" "✓ Mail Downloads cleared"
        log "Cleared mail downloads"
    fi
}

# App Uninstaller
uninstall_app() {
    print_header "APP UNINSTALLER"

    echo "Installed Applications:"
    echo ""

    # List user-installed apps (non-Apple) in /Applications
    local apps=()
    for app in /Applications/*.app; do
        [[ ! -d "$app" ]] && continue
        local app_name=$(basename "$app" .app)

        # Skip Apple apps
        local bundle_id=$(defaults read "$app/Contents/Info" CFBundleIdentifier 2>/dev/null || echo "")
        [[ "$bundle_id" =~ ^com\.apple\. ]] && continue

        local app_size=$(get_size "$app")
        apps+=("$app_name|$app_size|$app")
    done

    # Display apps with numbers
    local i=1
    for app_info in "${apps[@]}"; do
        local name=$(echo "$app_info" | cut -d'|' -f1)
        local size=$(echo "$app_info" | cut -d'|' -f2)
        printf "  %2d) %-30s %s\n" $i "$name" "$size"
        ((i++))
    done

    echo ""
    echo "  0) Cancel"
    echo ""

    read -p "Select app to uninstall (number): " selection

    if [[ "$selection" == "0" || -z "$selection" ]]; then
        return
    fi

    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ $selection -gt ${#apps[@]} ]]; then
        print_color "$RED" "Invalid selection"
        return
    fi

    local selected_app="${apps[$((selection-1))]}"
    local app_name=$(echo "$selected_app" | cut -d'|' -f1)
    local app_path=$(echo "$selected_app" | cut -d'|' -f3)

    echo ""
    print_color "$YELLOW" "Uninstalling: $app_name"
    echo ""

    # Find related files
    local bundle_id=$(defaults read "$app_path/Contents/Info" CFBundleIdentifier 2>/dev/null || echo "$app_name")

    echo "Related files found:"
    local related_files=()

    # Application Support
    for dir in ~/Library/Application\ Support/"$app_name"* ~/Library/Application\ Support/"${bundle_id}"*; do
        [[ -d "$dir" ]] && related_files+=("$dir") && echo "  • $dir ($(get_size "$dir"))"
    done

    # Caches
    for dir in ~/Library/Caches/"$app_name"* ~/Library/Caches/"${bundle_id}"* ~/Library/Caches/*"$app_name"*; do
        [[ -d "$dir" ]] && related_files+=("$dir") && echo "  • $dir ($(get_size "$dir"))"
    done

    # Preferences
    for plist in ~/Library/Preferences/"${bundle_id}"*.plist ~/Library/Preferences/*"$app_name"*.plist; do
        [[ -f "$plist" ]] && related_files+=("$plist") && echo "  • $plist"
    done

    # Containers
    if [[ -d ~/Library/Containers/"$bundle_id" ]]; then
        related_files+=(~/Library/Containers/"$bundle_id")
        echo "  • ~/Library/Containers/$bundle_id ($(get_size ~/Library/Containers/"$bundle_id"))"
    fi

    # Saved Application State
    if [[ -d ~/Library/Saved\ Application\ State/"${bundle_id}.savedState" ]]; then
        related_files+=(~/Library/Saved\ Application\ State/"${bundle_id}.savedState")
        echo "  • Saved Application State"
    fi

    echo ""

    if confirm "Remove $app_name and all related files?"; then
        # Move app to trash
        mv "$app_path" ~/.Trash/ 2>/dev/null && print_color "$GREEN" "  ✓ Moved app to Trash"

        # Remove related files
        for file in "${related_files[@]}"; do
            rm -rf "$file" 2>/dev/null && print_color "$GREEN" "  ✓ Removed: $(basename "$file")"
        done

        log "Uninstalled app: $app_name"
        echo ""
        print_color "$GREEN" "✓ $app_name has been uninstalled!"
    fi
}

# Application Updates Checker
check_app_updates() {
    print_header "APPLICATION UPDATES"

    echo "Checking for updates..."
    echo ""

    # Check Mac App Store updates
    print_color "$BOLD" "Mac App Store Updates:"
    local mas_updates=$(softwareupdate -l 2>&1)

    if echo "$mas_updates" | grep -q "No new software available"; then
        print_color "$GREEN" "  All App Store apps are up to date"
    else
        echo "$mas_updates" | grep -E "^\*|Label:" | head -20
    fi

    echo ""

    # Check Homebrew cask updates
    if command -v brew &>/dev/null; then
        print_color "$BOLD" "Homebrew Cask Updates:"
        local outdated=$(brew outdated --cask 2>/dev/null)
        if [[ -z "$outdated" ]]; then
            print_color "$GREEN" "  All Homebrew casks are up to date"
        else
            echo "$outdated" | while read -r app; do
                echo "  • $app"
            done
        fi
        echo ""

        if [[ -n "$outdated" ]] && confirm "Update all Homebrew casks?"; then
            brew upgrade --cask
            print_color "$GREEN" "✓ Updates installed"
        fi
    fi

    echo ""
    print_color "$CYAN" "To update App Store apps:"
    echo "  Open App Store → Updates"

    if confirm "Open App Store?"; then
        open -a "App Store"
    fi
}

# Large Files Scanner
scan_large_files() {
    print_header "LARGE FILES SCANNER"

    echo "Scanning for large files (>100MB)..."
    echo ""

    print_color "$BOLD" "Downloads folder:"
    find ~/Downloads -type f -size +100M 2>/dev/null | while read -r file; do
        echo "  $(get_size "$file") - $(basename "$file")"
    done | sort -hr | head -10

    echo ""
    print_color "$BOLD" "Desktop:"
    find ~/Desktop -type f -size +100M 2>/dev/null | while read -r file; do
        echo "  $(get_size "$file") - $(basename "$file")"
    done | sort -hr | head -10

    echo ""
    print_color "$BOLD" "Documents:"
    find ~/Documents -type f -size +100M 2>/dev/null | while read -r file; do
        echo "  $(get_size "$file") - $(basename "$file")"
    done | sort -hr | head -10

    echo ""
    print_color "$BOLD" "Movies:"
    find ~/Movies -type f -size +500M 2>/dev/null | while read -r file; do
        echo "  $(get_size "$file") - $(basename "$file")"
    done | sort -hr | head -10

    echo ""
    print_color "$YELLOW" "Tip: Review and delete files you no longer need"
}

# Run with AI agent (optional — requires Ollama + mac_maintainer agent)
run_with_ai() {
    print_header "AI-POWERED ANALYSIS"

    # Resolve agent_prompt.py — honour MACCLEANER_AGENT_SCRIPT env var, then look
    # in the same directory as this script, then fall back to graceful skip.
    local agent_script="${MACCLEANER_AGENT_SCRIPT:-}"
    if [[ -z "$agent_script" ]]; then
        local candidate="$SCRIPT_DIR/scripts/agent_prompt.py"
        [[ -f "$candidate" ]] && agent_script="$candidate"
    fi

    if [[ -z "$agent_script" || ! -f "$agent_script" ]]; then
        print_color "$YELLOW" "AI analysis is optional and needs a separate tool."
        print_color "$YELLOW" "If you have Ollama + the mac_maintainer agent set up, point"
        print_color "$YELLOW" "MACCLEANER_AGENT_SCRIPT to your agent_prompt.py and re-run."
        echo ""
        print_color "$CYAN" "Falling back to plain analysis output:"
        echo ""
        analyze_system
        return
    fi

    echo "Collecting system information..."
    local analysis_file="/tmp/mac_analysis_$(date +%Y%m%d_%H%M%S).txt"
    analyze_system > "$analysis_file"

    echo ""
    print_color "$CYAN" "Analysis saved to: $analysis_file"
    echo ""

    if confirm "Run AI analysis now?"; then
        python3 "$agent_script" mac_maintainer \
            --objective "Analyze my Mac and recommend safe cleanup actions with specific commands" \
            --var-file disk_report "$analysis_file" \
            --var system_info "macOS $(sw_vers -productVersion), $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'Mac')" \
            --var concerns "General cleanup and space optimization" \
            --execute
    fi
}

# Interactive menu
show_menu() {
    while true; do
        print_header "MAC CLEANER - Your CleanMyMac Alternative"
        echo ""
        print_color "$BOLD" "ANALYSIS & OVERVIEW"
        echo "  1)  Quick system overview"
        echo "  2)  Full analysis (for AI agent)"
        echo "  3)  Run AI-powered analysis"
        echo "  4)  Large files scanner"
        echo ""
        print_color "$BOLD" "SYSTEM JUNK (Safe)"
        echo "  5)  Quick cleanup (caches, logs, trash)"
        echo "  6)  User caches"
        echo "  7)  System logs"
        echo "  8)  Empty Trash"
        echo "  9)  Mail attachments"
        echo ""
        print_color "$BOLD" "APPLICATIONS"
        echo "  10) App uninstaller"
        echo "  11) App leftovers detector"
        echo "  12) Check for app updates"
        echo ""
        print_color "$BOLD" "STARTUP & BACKGROUND"
        echo "  13) Login items"
        echo "  14) Background items (LaunchAgents)"
        echo ""
        print_color "$BOLD" "DEVELOPER TOOLS"
        echo "  15) Xcode cleanup"
        echo "  16) Docker cleanup"
        echo "  17) Homebrew cleanup"
        echo ""
        print_color "$BOLD" "BROWSERS & MAINTENANCE"
        echo "  18) Browser caches"
        echo "  19) System maintenance (DNS, memory)"
        echo ""
        print_color "$BOLD" "OTHER"
        echo "  h)  Help"
        echo "  q)  Quit"
        echo ""

        read -p "Select option: " choice

        case $choice in
            1)
                print_header "QUICK OVERVIEW"
                echo "Disk: $(df -h / | tail -1 | awk '{print "Used: "$3" / "$2" ("$5")"}')"
                echo "User Caches: $(get_size ~/Library/Caches)"
                echo "Trash: $(get_size ~/.Trash)"
                echo "Downloads: $(get_size ~/Downloads)"
                echo "Mail Attachments: $(get_size ~/Library/Containers/com.apple.mail/Data/Library/Mail\ Downloads 2>/dev/null || echo '0B')"
                read -p "Press Enter to continue..."
                ;;
            2) analyze_system | less ;;
            3) run_with_ai ;;
            4) scan_large_files; read -p "Press Enter to continue..." ;;
            5) quick_cleanup; read -p "Press Enter to continue..." ;;
            6) clean_user_caches; read -p "Press Enter to continue..." ;;
            7) clean_logs; read -p "Press Enter to continue..." ;;
            8) clean_trash; read -p "Press Enter to continue..." ;;
            9) clean_mail_attachments; read -p "Press Enter to continue..." ;;
            10) uninstall_app; read -p "Press Enter to continue..." ;;
            11) find_app_leftovers; read -p "Press Enter to continue..." ;;
            12) check_app_updates; read -p "Press Enter to continue..." ;;
            13) manage_login_items; read -p "Press Enter to continue..." ;;
            14) scan_background_items; read -p "Press Enter to continue..." ;;
            15) clean_xcode; read -p "Press Enter to continue..." ;;
            16) clean_docker; read -p "Press Enter to continue..." ;;
            17) clean_homebrew; read -p "Press Enter to continue..." ;;
            18) clean_browsers; read -p "Press Enter to continue..." ;;
            19) system_maintenance; read -p "Press Enter to continue..." ;;
            h|H|help)
                print_header "HELP"
                echo "Mac Cleaner is a CleanMyMac replacement using native macOS tools."
                echo ""
                echo "Feature Categories:"
                echo "  • System Junk: Caches, logs, trash, mail attachments"
                echo "  • Applications: Uninstall apps, find leftovers, check updates"
                echo "  • Startup: Manage login items and background processes"
                echo "  • Developer: Xcode, Docker, Homebrew cleanup"
                echo "  • Browsers: Clear browser caches"
                echo "  • Maintenance: DNS flush, memory purge"
                echo ""
                echo "Command line usage:"
                echo "  ./mac_cleaner.sh              # Interactive menu"
                echo "  ./mac_cleaner.sh --analyze    # Generate analysis file"
                echo "  ./mac_cleaner.sh --quick      # Safe quick cleanup"
                echo "  ./mac_cleaner.sh --dry-run    # Preview without changes"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            q|Q|quit|exit)
                print_color "$GREEN" "Goodbye!"
                exit 0
                ;;
            *)
                print_color "$RED" "Invalid option: $choice"
                sleep 1
                ;;
        esac
    done
}

# Show help
show_help() {
    echo "Mac Cleaner - CleanMyMac Alternative"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --analyze     Generate system analysis for AI agent"
    echo "  --quick       Run safe quick cleanup (no prompts)"
    echo "  --dry-run     Preview actions without making changes"
    echo "  --help, -h    Show this help message"
    echo ""
    echo "Interactive mode (default):"
    echo "  Run without options to enter the interactive menu"
    echo ""
    echo "Optional AI analysis (requires Ollama + mac_maintainer agent):"
    echo "  $0 --analyze > /tmp/analysis.txt"
    echo "  MACCLEANER_AGENT_SCRIPT=/path/to/agent_prompt.py $0"
    echo "  Then choose option 3 (AI-powered analysis) from the menu."
}

# Main
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --analyze)
                analyze_system
                exit 0
                ;;
            --quick)
                quick_cleanup
                exit 0
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_color "$RED" "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Interactive mode
    show_menu
}

main "$@"
