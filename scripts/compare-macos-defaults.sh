#!/usr/bin/env bash
#
# Compare current macOS defaults with a baseline/fresh system
#
# This script helps identify which settings YOU have changed
# from the default macOS configuration
#
# Usage:
#   ./compare-macos-defaults.sh [baseline_file]
#
# If no baseline file is provided, it will create one for future comparison

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BASELINE_FILE="${1:-$HOME/.macos-defaults-baseline.txt}"
CURRENT_FILE="/tmp/current-defaults-$$.txt"

trap 'rm -f "$CURRENT_FILE"' EXIT

echo -e "${BLUE}=== macOS Defaults Comparator ===${NC}"
echo ""

# Function to export current defaults
export_current_defaults() {
    local output="$1"

    echo "# macOS Defaults Snapshot" > "$output"
    echo "# Date: $(date)" >> "$output"
    echo "# macOS: $(sw_vers -productVersion)" >> "$output"
    echo "# User: $(whoami)" >> "$output"
    echo "" >> "$output"

    # Important domains
    local domains=(
        "NSGlobalDomain"
        "com.apple.dock"
        "com.apple.finder"
        "com.apple.Safari"
        "com.apple.screencapture"
        "com.apple.screensaver"
        "com.apple.ActivityMonitor"
        "com.apple.desktopservices"
        "com.apple.menuextra.clock"
        "com.apple.loginwindow"
    )

    for domain in "${domains[@]}"; do
        if defaults read "$domain" &>/dev/null; then
            echo "### DOMAIN: $domain ###" >> "$output"
            defaults read "$domain" 2>/dev/null | \
                grep -E "^[[:space:]]*[^[:space:]]+ =" | \
                sort >> "$output"
            echo "" >> "$output"
        fi
    done
}

# Export current state
echo -e "${GREEN}Exporting current defaults...${NC}"
export_current_defaults "$CURRENT_FILE"

# Check if baseline exists
if [[ ! -f "$BASELINE_FILE" ]]; then
    echo -e "${YELLOW}No baseline file found.${NC}"
    echo -e "Creating baseline at: ${BLUE}$BASELINE_FILE${NC}"
    cp "$CURRENT_FILE" "$BASELINE_FILE"
    echo ""
    echo -e "${GREEN}✓ Baseline created!${NC}"
    echo ""
    echo "Run this script again in the future to see what changed:"
    echo -e "  ${BLUE}$0${NC}"
    exit 0
fi

# Compare with baseline
echo -e "${GREEN}Comparing with baseline...${NC}"
echo -e "Baseline: ${BLUE}$BASELINE_FILE${NC}"
echo ""

# Parse baseline date
BASELINE_DATE=$(grep "^# Date:" "$BASELINE_FILE" | cut -d: -f2- | xargs)
BASELINE_MACOS=$(grep "^# macOS:" "$BASELINE_FILE" | cut -d: -f2- | xargs)

echo -e "Baseline from: ${YELLOW}$BASELINE_DATE${NC}"
echo -e "Baseline macOS: ${YELLOW}$BASELINE_MACOS${NC}"
echo ""

# Show differences
echo -e "${BLUE}=== Changed Settings ===${NC}"
echo ""

# Use diff to find changes
DIFF_OUTPUT=$(diff -u "$BASELINE_FILE" "$CURRENT_FILE" 2>/dev/null || true)

if [[ -z "$DIFF_OUTPUT" ]]; then
    echo -e "${GREEN}No changes detected!${NC}"
    exit 0
fi

# Parse and display changes
CHANGES_FOUND=0

while IFS= read -r line; do
    # New settings (not in baseline)
    if [[ "$line" =~ ^\+[[:space:]]*([^[:space:]]+)[[:space:]]*=[[:space:]]*(.+) ]]; then
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        echo -e "${GREEN}+ NEW:${NC} $key = $value"
        ((CHANGES_FOUND++))

    # Removed settings (were in baseline, now gone)
    elif [[ "$line" =~ ^\-[[:space:]]*([^[:space:]]+)[[:space:]]*=[[:space:]]*(.+) ]]; then
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        echo -e "${RED}- REMOVED:${NC} $key = $value"
        ((CHANGES_FOUND++))

    # Domain changes
    elif [[ "$line" =~ ^\+###\ DOMAIN: ]]; then
        domain="${line#+### DOMAIN: }"
        domain="${domain% ###}"
        echo ""
        echo -e "${BLUE}Domain: $domain${NC}"
    fi
done <<< "$DIFF_OUTPUT"

echo ""
echo -e "${BLUE}=== Summary ===${NC}"
echo -e "Total changes: ${GREEN}$CHANGES_FOUND${NC}"
echo ""

# Generate defaults write commands for changes
echo -e "${YELLOW}Generating defaults commands for changes...${NC}"

OUTPUT_SCRIPT="/tmp/apply-defaults-changes-$$.sh"

cat > "$OUTPUT_SCRIPT" << 'HEADER'
#!/usr/bin/env bash
#
# Apply macOS defaults changes
# Auto-generated from comparison

set -e

echo "Applying macOS defaults changes..."

HEADER

# Extract new/changed settings and generate commands
CURRENT_DOMAIN=""

while IFS= read -r line; do
    # Track current domain
    if [[ "$line" =~ ###\ DOMAIN:\ (.+)\ ### ]]; then
        CURRENT_DOMAIN="${BASH_REMATCH[1]}"
        echo "" >> "$OUTPUT_SCRIPT"
        echo "# Domain: $CURRENT_DOMAIN" >> "$OUTPUT_SCRIPT"
        continue
    fi

    # Only process additions (new settings)
    if [[ "$line" =~ ^\+[[:space:]]*([^[:space:]]+)[[:space:]]*=[[:space:]]*(.+); ]]; then
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"

        # Clean value
        value="${value%;}"

        # Determine type
        if [[ "$value" =~ ^[0-9]+$ ]]; then
            type="-int"
        elif [[ "$value" =~ ^[0-9]+\.[0-9]+$ ]]; then
            type="-float"
        elif [[ "$value" == "0" ]] || [[ "$value" == "1" ]]; then
            type="-bool"
            [[ "$value" == "1" ]] && value="true" || value="false"
        elif [[ "$value" =~ ^\( ]]; then
            type="-array"
            value="<array value>"
        else
            type="-string"
            value="${value#\"}"
            value="${value%\"}"
        fi

        # Generate command
        if [[ "$type" == "-array" ]]; then
            echo "# defaults write \"$CURRENT_DOMAIN\" \"$key\" $type ... (manual edit needed)" >> "$OUTPUT_SCRIPT"
        else
            echo "defaults write \"$CURRENT_DOMAIN\" \"$key\" $type \"$value\"" >> "$OUTPUT_SCRIPT"
        fi
    fi
done <<< "$DIFF_OUTPUT"

echo "" >> "$OUTPUT_SCRIPT"
echo "echo 'Done! Restart affected applications.'" >> "$OUTPUT_SCRIPT"

chmod +x "$OUTPUT_SCRIPT"

echo -e "${GREEN}✓ Script generated: ${BLUE}$OUTPUT_SCRIPT${NC}"
echo ""
echo "To apply these changes on another Mac:"
echo -e "  ${BLUE}$OUTPUT_SCRIPT${NC}"
echo ""
echo "To update baseline with current settings:"
echo -e "  ${BLUE}cp $CURRENT_FILE $BASELINE_FILE${NC}"
echo ""
