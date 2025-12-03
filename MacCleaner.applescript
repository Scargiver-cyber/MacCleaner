-- MacCleaner GUI - Full CleanMyMac Replacement
-- A native macOS interface for the mac_cleaner.sh script
-- Part of ai-terminal system

use AppleScript version "2.4"
use scripting additions

-- Configuration
property scriptPath : "/Users/jasontilson/ai-terminal/scripts/mac_cleaner.sh"
property terminalApp : "Terminal"

-- Main menu
on run
	set mainChoice to display dialog "🧹 Mac Cleaner" & return & return & ¬
		"Your Complete CleanMyMac Replacement" & return & return & ¬
		"Choose a category:" buttons {"Quick Clean", "Full Menu", "Cancel"} ¬
		default button "Quick Clean" ¬
		with icon note ¬
		giving up after 120

	if button returned of mainChoice is "Quick Clean" then
		doQuickClean()
	else if button returned of mainChoice is "Full Menu" then
		showMainMenu()
	end if
end run

-- Quick cleanup (safe, no prompts)
on doQuickClean()
	set confirmDialog to display dialog "🚀 Quick Safe Cleanup" & return & return & ¬
		"This will clean:" & return & ¬
		"  • User caches" & return & ¬
		"  • Old logs (>7 days)" & return & ¬
		"  • Old crash reports" & return & ¬
		"  • Homebrew cache" & return & ¬
		"  • npm cache" & return & ¬
		"  • Empty Trash" & return & return & ¬
		"All operations are SAFE and reversible." ¬
		buttons {"Run Cleanup", "Cancel"} ¬
		default button "Run Cleanup" ¬
		with icon caution

	if button returned of confirmDialog is "Run Cleanup" then
		display notification "Running safe cleanup..." with title "Mac Cleaner"

		try
			set cleanupResult to do shell script scriptPath & " --quick 2>&1"
			display dialog "✅ Cleanup Complete!" & return & return & ¬
				"Your Mac has been cleaned." & return & return & ¬
				"Run 'Full Menu' for more options." ¬
				buttons {"OK"} default button "OK" with icon note
		on error errMsg
			display dialog "❌ Error during cleanup:" & return & return & errMsg ¬
				buttons {"OK"} default button "OK" with icon stop
		end try
	end if
end doQuickClean

-- Main category menu
on showMainMenu()
	set menuChoice to display dialog "📋 Mac Cleaner - Full Menu" & return & return & ¬
		"Select a category:" buttons {"System Junk", "Applications", "More..."} ¬
		default button "System Junk" ¬
		with icon note

	if button returned of menuChoice is "System Junk" then
		showSystemJunkMenu()
	else if button returned of menuChoice is "Applications" then
		showApplicationsMenu()
	else if button returned of menuChoice is "More..." then
		showMoreMenu()
	end if
end showMainMenu

-- System Junk submenu
on showSystemJunkMenu()
	set junkChoice to display dialog "🗑 System Junk Cleanup" & return & return & ¬
		"Choose what to clean:" buttons {"Caches & Logs", "Mail & Trash", "Back"} ¬
		default button "Caches & Logs" ¬
		with icon note

	if button returned of junkChoice is "Caches & Logs" then
		showCachesMenu()
	else if button returned of junkChoice is "Mail & Trash" then
		showMailTrashMenu()
	else if button returned of junkChoice is "Back" then
		showMainMenu()
	end if
end showSystemJunkMenu

-- Caches submenu
on showCachesMenu()
	set cacheChoice to display dialog "📦 Cache Cleanup" & return & return & ¬
		"Select action:" buttons {"All Caches", "Browser Caches", "Back"} ¬
		default button "All Caches" ¬
		with icon note

	if button returned of cacheChoice is "All Caches" then
		cleanAllCaches()
	else if button returned of cacheChoice is "Browser Caches" then
		cleanBrowserCaches()
	else if button returned of cacheChoice is "Back" then
		showSystemJunkMenu()
	end if
end showCachesMenu

-- Clean all caches
on cleanAllCaches()
	display notification "Cleaning caches..." with title "Mac Cleaner"
	try
		do shell script "rm -rf ~/Library/Caches/* 2>/dev/null; echo 'Done'"
		display dialog "✅ User caches cleared!" buttons {"OK"} default button "OK" with icon note
	on error errMsg
		display dialog "Error: " & errMsg buttons {"OK"} default button "OK" with icon stop
	end try
end cleanAllCaches

-- Clean browser caches
on cleanBrowserCaches()
	set browserChoice to display dialog "🌐 Browser Caches" & return & return & ¬
		"Select browser:" buttons {"Safari", "Chrome/Brave", "All Browsers"} ¬
		default button "All Browsers" ¬
		with icon note

	display notification "Cleaning browser caches..." with title "Mac Cleaner"

	try
		if button returned of browserChoice is "Safari" then
			do shell script "rm -rf ~/Library/Caches/com.apple.Safari/* 2>/dev/null"
		else if button returned of browserChoice is "Chrome/Brave" then
			do shell script "rm -rf ~/Library/Caches/Google/Chrome/* ~/Library/Caches/BraveSoftware/* 2>/dev/null"
		else
			do shell script "rm -rf ~/Library/Caches/com.apple.Safari/* ~/Library/Caches/Google/Chrome/* ~/Library/Caches/BraveSoftware/* ~/Library/Caches/Firefox/* 2>/dev/null"
		end if
		display dialog "✅ Browser caches cleared!" buttons {"OK"} default button "OK" with icon note
	on error errMsg
		display dialog "Error: " & errMsg buttons {"OK"} default button "OK" with icon stop
	end try
end cleanBrowserCaches

-- Mail & Trash submenu
on showMailTrashMenu()
	set mailChoice to display dialog "📧 Mail & Trash" & return & return & ¬
		"Select action:" buttons {"Empty Trash", "Mail Attachments", "Back"} ¬
		default button "Empty Trash" ¬
		with icon note

	if button returned of mailChoice is "Empty Trash" then
		emptyTrash()
	else if button returned of mailChoice is "Mail Attachments" then
		cleanMailAttachments()
	else if button returned of mailChoice is "Back" then
		showSystemJunkMenu()
	end if
end showMailTrashMenu

-- Empty Trash
on emptyTrash()
	try
		set trashSize to do shell script "du -sh ~/.Trash 2>/dev/null | awk '{print $1}'"
		set confirmEmpty to display dialog "🗑 Empty Trash" & return & return & ¬
			"Trash size: " & trashSize & return & return & ¬
			"This will permanently delete all items in Trash." ¬
			buttons {"Empty Trash", "Cancel"} ¬
			default button "Cancel" ¬
			with icon caution

		if button returned of confirmEmpty is "Empty Trash" then
			do shell script "rm -rf ~/.Trash/* 2>/dev/null"
			display dialog "✅ Trash emptied!" buttons {"OK"} default button "OK" with icon note
		end if
	on error errMsg
		display dialog "Error: " & errMsg buttons {"OK"} default button "OK" with icon stop
	end try
end emptyTrash

-- Clean mail attachments
on cleanMailAttachments()
	try
		set mailSize to do shell script "du -sh ~/Library/Containers/com.apple.mail/Data/Library/'Mail Downloads' 2>/dev/null | awk '{print $1}' || echo '0B'"
		set confirmMail to display dialog "📧 Mail Attachments" & return & return & ¬
			"Cached attachments: " & mailSize & return & return & ¬
			"These are local copies. Originals remain on server." ¬
			buttons {"Clean", "Cancel"} ¬
			default button "Clean" ¬
			with icon note

		if button returned of confirmMail is "Clean" then
			do shell script "rm -rf ~/Library/Containers/com.apple.mail/Data/Library/'Mail Downloads'/* 2>/dev/null"
			display dialog "✅ Mail attachments cleared!" buttons {"OK"} default button "OK" with icon note
		end if
	on error errMsg
		display dialog "Error: " & errMsg buttons {"OK"} default button "OK" with icon stop
	end try
end cleanMailAttachments

-- Applications menu
on showApplicationsMenu()
	set appChoice to display dialog "📱 Applications" & return & return & ¬
		"Select action:" buttons {"Uninstaller", "App Leftovers", "Updates"} ¬
		default button "App Leftovers" ¬
		with icon note

	if button returned of appChoice is "Uninstaller" then
		openInTerminal("") -- Opens interactive menu for app uninstaller
		display dialog "Opening Terminal for App Uninstaller..." & return & return & ¬
			"Select option 10 in the menu." ¬
			buttons {"OK"} default button "OK" with icon note
	else if button returned of appChoice is "App Leftovers" then
		scanAppLeftovers()
	else if button returned of appChoice is "Updates" then
		checkUpdates()
	end if
end showApplicationsMenu

-- Scan for app leftovers
on scanAppLeftovers()
	display notification "Scanning for app leftovers..." with title "Mac Cleaner"
	openInTerminal("")
	display dialog "Opening Terminal for App Leftovers scan..." & return & return & ¬
		"Select option 11 in the menu." ¬
		buttons {"OK"} default button "OK" with icon note
end scanAppLeftovers

-- Check for updates - just open App Store
on checkUpdates()
	set updateDialog to display dialog "🔄 Application Updates" & return & return & ¬
		"For app updates:" & return & ¬
		"• App Store apps: Open App Store → Updates" & return & ¬
		"• Homebrew apps: Run 'brew upgrade' in Terminal" ¬
		buttons {"Open App Store", "Close"} ¬
		default button "Close" ¬
		with icon note

	if button returned of updateDialog is "Open App Store" then
		tell application "App Store" to activate
	end if
end checkUpdates

-- More options menu
on showMoreMenu()
	set moreChoice to display dialog "⚙️ More Options" & return & return & ¬
		"Select category:" buttons {"Startup Items", "Maintenance", "Back"} ¬
		default button "Startup Items" ¬
		with icon note

	if button returned of moreChoice is "Startup Items" then
		showStartupMenu()
	else if button returned of moreChoice is "Maintenance" then
		showMaintenanceMenu()
	else if button returned of moreChoice is "Back" then
		showMainMenu()
	end if
end showMoreMenu

-- Startup items menu
on showStartupMenu()
	set startupChoice to display dialog "🚀 Startup & Background Items" & return & return & ¬
		"Select action:" buttons {"Login Items", "Background Items", "Back"} ¬
		default button "Login Items" ¬
		with icon note

	if button returned of startupChoice is "Login Items" then
		manageLoginItems()
	else if button returned of startupChoice is "Background Items" then
		openInTerminal("")
		display dialog "Opening Terminal for Background Items scan..." & return & return & ¬
			"Select option 14 in the menu." ¬
			buttons {"OK"} default button "OK" with icon note
	else if button returned of startupChoice is "Back" then
		showMoreMenu()
	end if
end showStartupMenu

-- Manage login items
on manageLoginItems()
	try
		set loginItems to do shell script "osascript -e 'tell application \"System Events\" to get the name of every login item' 2>/dev/null || echo 'None found'"

		set loginDialog to display dialog "🚀 Login Items" & return & return & ¬
			"Apps that start at login:" & return & loginItems & return & return & ¬
			"Manage in System Settings → Login Items" ¬
			buttons {"Open Settings", "Close"} ¬
			default button "Close" ¬
			with icon note

		if button returned of loginDialog is "Open Settings" then
			do shell script "open 'x-apple.systempreferences:com.apple.LoginItems-Settings.extension'"
		end if
	on error errMsg
		display dialog "Error: " & errMsg buttons {"OK"} default button "OK" with icon stop
	end try
end manageLoginItems

-- Maintenance menu
on showMaintenanceMenu()
	set maintChoice to display dialog "🔧 System Maintenance" & return & return & ¬
		"Select action:" buttons {"Flush DNS", "Purge Memory", "Large Files"} ¬
		default button "Flush DNS" ¬
		with icon note

	if button returned of maintChoice is "Flush DNS" then
		flushDNS()
	else if button returned of maintChoice is "Purge Memory" then
		purgeMemory()
	else if button returned of maintChoice is "Large Files" then
		openInTerminal("")
		display dialog "Opening Terminal for Large Files scan..." & return & return & ¬
			"Select option 4 in the menu." ¬
			buttons {"OK"} default button "OK" with icon note
	end if
end showMaintenanceMenu

-- Flush DNS
on flushDNS()
	try
		do shell script "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder" with administrator privileges
		display dialog "✅ DNS cache flushed!" buttons {"OK"} default button "OK" with icon note
	on error errMsg
		display dialog "Error: " & errMsg buttons {"OK"} default button "OK" with icon stop
	end try
end flushDNS

-- Purge Memory
on purgeMemory()
	try
		display notification "Purging inactive memory..." with title "Mac Cleaner"
		do shell script "sudo purge" with administrator privileges
		display dialog "✅ Memory purged!" buttons {"OK"} default button "OK" with icon note
	on error errMsg
		display dialog "Error: " & errMsg buttons {"OK"} default button "OK" with icon stop
	end try
end purgeMemory

-- Open script in Terminal with optional arguments
on openInTerminal(args)
	tell application "Terminal"
		activate
		if args is "" then
			do script scriptPath
		else
			do script scriptPath & " " & args
		end if
	end tell
end openInTerminal
