#!/bin/bash
# Launch the MacCleaner GUI app.
# Looks for MacCleaner.app next to this script, then falls back to /Applications.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="$SCRIPT_DIR/MacCleaner.app"
if [[ ! -d "$APP" ]]; then
  APP="/Applications/MacCleaner.app"
fi
open "$APP"
