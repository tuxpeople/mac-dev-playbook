#!/bin/bash
#
# macOS Settings Checker
# Checks if settings defined in Ansible still work on current macOS version
#
# Usage: ./scripts/check-macos-settings.sh

set -u  # Only fail on undefined variables, not on command failures

MACOS_VERSION=$(sw_vers -productVersion)
echo "=================================================="
echo "macOS Settings Checker"
echo "=================================================="
echo "macOS Version: ${MACOS_VERSION}"
echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

check_defaults_setting() {
    local domain=$1
    local key=$2
    local expected=$3
    local name=$4

    echo -n "Checking: ${name}..."

    # Try to read the setting
    actual=$(defaults read "${domain}" "${key}" 2>/dev/null || echo "NOT_FOUND")

    if [ "${actual}" = "NOT_FOUND" ]; then
        echo -e " ${RED}NOT FOUND${NC}"
        echo "  Domain: ${domain}"
        echo "  Key: ${key}"
        return 1
    else
        echo -e " ${GREEN}EXISTS${NC}"
        echo "  Current value: ${actual}"
        if [ -n "${expected}" ]; then
            if [ "${actual}" = "${expected}" ]; then
                echo -e "  ${GREEN}✓ Matches expected value${NC}"
            else
                echo -e "  ${YELLOW}! Differs from expected: ${expected}${NC}"
            fi
        fi
        return 0
    fi
}

check_command_exists() {
    local cmd=$1
    local name=$2

    echo -n "Checking command: ${name} (${cmd})..."

    if command -v "${cmd}" &> /dev/null; then
        echo -e " ${GREEN}EXISTS${NC}"
        "${cmd}" --version 2>&1 | head -1 | sed 's/^/  Version: /'
        return 0
    else
        echo -e " ${RED}NOT FOUND${NC}"
        return 1
    fi
}

check_file_exists() {
    local path=$1
    local name=$2

    echo -n "Checking file: ${name}..."

    if [ -f "${path}" ]; then
        echo -e " ${GREEN}EXISTS${NC}"
        ls -lh "${path}" | awk '{print "  Size: " $5 "  Modified: " $6 " " $7 " " $8}'
        return 0
    else
        echo -e " ${RED}NOT FOUND${NC}"
        echo "  Path: ${path}"
        return 1
    fi
}

echo "=================================================="
echo "1. Checking defaults.yml Settings"
echo "=================================================="
echo ""

# From inventories/group_vars/macs/defaults.yml
check_defaults_setting "com.apple.applicationaccess" "allowAutoUnlock" "1" "Apple Watch Unlock"
echo ""

check_defaults_setting "com.apple.dock" "tilesize" "30" "Dock Tile Size"
echo ""

check_defaults_setting "com.apple.dock" "orientation" "bottom" "Dock Position"
echo ""

check_defaults_setting "com.apple.dock" "autohide" "0" "Dock Auto-Hide (disabled)"
echo ""

check_defaults_setting "com.apple.screensaver" "idleTime" "0" "Screensaver Idle Time"
echo ""

check_defaults_setting "com.apple.finder" "ShowHardDrivesOnDesktop" "1" "Show Hard Drives on Desktop"
echo ""

check_defaults_setting "com.apple.finder" "ShowExternalHardDrivesOnDesktop" "1" "Show External Drives on Desktop"
echo ""

check_defaults_setting "com.apple.finder" "ShowRemovableMediaOnDesktop" "1" "Show Removable Media on Desktop"
echo ""

check_defaults_setting "com.apple.finder" "AppleShowAllFiles" "1" "Show Hidden Files"
echo ""

check_defaults_setting "com.apple.finder" "AppleShowAllExtensions" "1" "Show All File Extensions"
echo ""

check_defaults_setting "com.apple.finder" "ShowStatusBar" "1" "Show Finder Status Bar"
echo ""

check_defaults_setting "com.apple.finder" "ShowPathbar" "1" "Show Finder Path Bar"
echo ""

check_defaults_setting "com.apple.TextEdit" "RichText" "0" "TextEdit Plain Text Mode"
echo ""

echo "=================================================="
echo "2. Checking various-settings.yml Tools"
echo "=================================================="
echo ""

check_command_exists "dockutil" "DockUtil"
echo ""

check_command_exists "m" "m-cli"
echo ""

check_command_exists "mysides" "mysides"
echo ""

check_command_exists "/usr/libexec/PlistBuddy" "PlistBuddy"
echo ""

check_command_exists "systemsetup" "systemsetup"
echo ""

echo "=================================================="
echo "3. Checking PlistBuddy Settings"
echo "=================================================="
echo ""

FINDER_PLIST="${HOME}/Library/Preferences/com.apple.finder.plist"
check_file_exists "${FINDER_PLIST}" "Finder Preferences"
if [ -f "${FINDER_PLIST}" ]; then
    echo ""
    echo -n "  DesktopViewSettings:IconViewSettings:arrangeBy: "
    /usr/libexec/PlistBuddy -c "Print :DesktopViewSettings:IconViewSettings:arrangeBy" "${FINDER_PLIST}" 2>/dev/null || echo "NOT FOUND"

    echo -n "  DesktopViewSettings:IconViewSettings:gridSpacing: "
    /usr/libexec/PlistBuddy -c "Print :DesktopViewSettings:IconViewSettings:gridSpacing" "${FINDER_PLIST}" 2>/dev/null || echo "NOT FOUND"

    echo -n "  DesktopViewSettings:IconViewSettings:iconSize: "
    /usr/libexec/PlistBuddy -c "Print :DesktopViewSettings:IconViewSettings:iconSize" "${FINDER_PLIST}" 2>/dev/null || echo "NOT FOUND"
fi
echo ""

echo "=================================================="
echo "4. Checking File/Folder States"
echo "=================================================="
echo ""

echo -n "~/Library visibility: "
if ls -lOd "${HOME}/Library" | grep -q "hidden"; then
    echo -e "${YELLOW}HIDDEN${NC}"
else
    echo -e "${GREEN}VISIBLE${NC}"
fi

echo -n "/Volumes visibility: "
if ls -lOd "/Volumes" | grep -q "hidden"; then
    echo -e "${YELLOW}HIDDEN${NC}"
else
    echo -e "${GREEN}VISIBLE${NC}"
fi
echo ""

echo "=================================================="
echo "5. Checking SSH Status"
echo "=================================================="
echo ""

echo -n "SSH (Remote Login) status: "
if sudo systemsetup -getremotelogin 2>/dev/null | grep -q "On"; then
    echo -e "${GREEN}ENABLED${NC}"
else
    echo -e "${YELLOW}DISABLED${NC}"
fi
echo ""

echo "=================================================="
echo "6. Export Current Settings to File"
echo "=================================================="
echo ""

OUTPUT_FILE="/tmp/macos-current-settings-$(date +%Y%m%d-%H%M%S).txt"
echo "Exporting all current defaults to: ${OUTPUT_FILE}"

{
    echo "=================================================="
    echo "Current macOS Defaults Export"
    echo "Date: $(date)"
    echo "macOS Version: ${MACOS_VERSION}"
    echo "=================================================="
    echo ""

    echo "=== Dock Settings ==="
    defaults read com.apple.dock
    echo ""

    echo "=== Finder Settings ==="
    defaults read com.apple.finder
    echo ""

    echo "=== Screensaver Settings ==="
    defaults read com.apple.screensaver 2>/dev/null || echo "No screensaver settings found"
    echo ""

    echo "=== Application Access Settings ==="
    defaults read com.apple.applicationaccess 2>/dev/null || echo "No application access settings found"
    echo ""

    echo "=== TextEdit Settings ==="
    defaults read com.apple.TextEdit 2>/dev/null || echo "No TextEdit settings found"
    echo ""

} > "${OUTPUT_FILE}"

echo -e "${GREEN}✓ Export complete${NC}"
echo "Review file: ${OUTPUT_FILE}"
echo ""

echo "=================================================="
echo "Summary"
echo "=================================================="
echo ""
echo "Next steps:"
echo "1. Review the output above for any NOT FOUND or DIFFERS warnings"
echo "2. Check ${OUTPUT_FILE} for full current settings"
echo "3. Compare with Ansible definitions in:"
echo "   - inventories/group_vars/macs/defaults.yml"
echo "   - tasks/post/various-settings.yml"
echo "4. Test modifying a setting and see if it persists"
echo ""
