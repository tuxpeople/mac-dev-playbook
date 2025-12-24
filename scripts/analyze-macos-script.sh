#!/bin/bash
#
# Analyze .macos script for obsolete settings
# Extracts all 'defaults write' commands and checks if domains/keys still exist
#
# Usage: ./scripts/analyze-macos-script.sh

set -u

MACOS_SCRIPT="${HOME}/development/github/tuxpeople/dotfiles/.macos"
MACOS_VERSION=$(sw_vers -productVersion)

echo "=================================================="
echo ".macos Script Analyzer"
echo "=================================================="
echo "Script: ${MACOS_SCRIPT}"
echo "macOS Version: ${MACOS_VERSION}"
echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=================================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ ! -f "${MACOS_SCRIPT}" ]; then
    echo -e "${RED}ERROR: .macos script not found at ${MACOS_SCRIPT}${NC}"
    exit 1
fi

echo "Extracting 'defaults write' commands..."
echo ""

# Extract all non-commented defaults write commands
grep -n "defaults write" "${MACOS_SCRIPT}" | grep -v "^[[:space:]]*#" > /tmp/defaults-commands.txt

TOTAL_COMMANDS=$(wc -l < /tmp/defaults-commands.txt | tr -d ' ')
echo "Found ${TOTAL_COMMANDS} 'defaults write' commands"
echo ""

# Count by domain
echo "=================================================="
echo "Commands by Domain"
echo "=================================================="
echo ""

grep "defaults write" "${MACOS_SCRIPT}" | grep -v "^[[:space:]]*#" | \
    awk '{print $3}' | sort | uniq -c | sort -rn

echo ""
echo "=================================================="
echo "Testing Settings (Sample)"
echo "=================================================="
echo ""

# Test a sample of domains to see if they exist
DOMAINS=(
    "com.apple.applicationaccess"
    "NSGlobalDomain"
    "com.apple.dock"
    "com.apple.finder"
    "com.apple.desktopservices"
    "com.apple.screensaver"
    "com.apple.screencapture"
    "com.apple.menuextra.clock"
    "com.apple.TextEdit"
    "com.apple.DiskUtility"
    "com.apple.Safari"
    "com.apple.mail"
    "com.apple.terminal"
    "com.apple.ActivityMonitor"
)

for domain in "${DOMAINS[@]}"; do
    echo -n "Testing domain: ${domain}..."

    if defaults read "${domain}" &> /dev/null; then
        echo -e " ${GREEN}EXISTS${NC}"
        # Count how many settings use this domain
        count=$(grep "defaults write ${domain}" "${MACOS_SCRIPT}" | grep -v "^[[:space:]]*#" | wc -l | tr -d ' ')
        echo "  Used in ${count} commands in .macos"
    else
        echo -e " ${RED}DOES NOT EXIST${NC}"
        # Show which settings try to use this domain
        echo "  Lines in .macos using this domain:"
        grep -n "defaults write ${domain}" "${MACOS_SCRIPT}" | grep -v "^[[:space:]]*#" | head -3 | sed 's/^/    /'
    fi
    echo ""
done

echo "=================================================="
echo "Commented-Out Settings (Potentially Obsolete)"
echo "=================================================="
echo ""

grep -n "^[[:space:]]*# defaults write" "${MACOS_SCRIPT}" | head -20
echo ""
echo "... (showing first 20, total: $(grep -c "^[[:space:]]*# defaults write" "${MACOS_SCRIPT}"))"
echo ""

echo "=================================================="
echo "Deprecated Commands (sudo nvram, etc.)"
echo "=================================================="
echo ""

echo "sudo nvram commands:"
grep -n "sudo nvram" "${MACOS_SCRIPT}" | grep -v "^[[:space:]]*#"
echo ""

echo "systemsetup commands:"
grep -n "systemsetup" "${MACOS_SCRIPT}" | grep -v "^[[:space:]]*#"
echo ""

echo "=================================================="
echo "Recommendations"
echo "=================================================="
echo ""

cat <<'EOF'
1. Review commented-out settings - these were likely disabled because they
   stopped working or were no longer needed.

2. Test the .macos script on a test Mac to see which settings fail.

3. Consider converting frequently-used settings from .macos to Ansible
   tasks in defaults.yml (using community.general.osx_defaults).

4. Focus on these categories for conversion:
   - Finder settings (many already in defaults.yml)
   - Dock settings (many already in defaults.yml)
   - Keyboard/Trackpad settings
   - Screen/Display settings

5. Keep OS-version-specific settings in .macos, convert stable ones to Ansible.

Next step: Run the .macos script and capture errors:
  cd ~/development/github/tuxpeople/dotfiles
  ./.macos 2>&1 | tee /tmp/macos-script-output.txt
EOF

echo ""
echo "=================================================="
echo "Analysis Complete"
echo "=================================================="
