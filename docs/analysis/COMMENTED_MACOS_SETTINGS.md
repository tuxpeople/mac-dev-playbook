# Commented-Out macOS Settings

**Source**: `~/development/github/tuxpeople/dotfiles/.macos`
**Total**: 51 commented `defaults write` commands
**Date Analyzed**: 2025-12-24
**macOS Version**: 26.2

These settings were commented out in the .macos script, likely because they:

- Stopped working in newer macOS versions
- Caused issues or conflicts
- Are no longer desired
- Have been replaced by better alternatives

---

## General UI/UX

### Reduce Transparency (Line 21)

```bash
# defaults write com.apple.universalaccess reduceTransparency -bool true
```

**Purpose**: Disable transparency effects in menu bar and windows (Yosemite feature)
**Status**: Commented out - likely still works but not desired
**Domain**: com.apple.universalaccess ✅ (exists)

---

### Highlight Color (Line 24)

```bash
# defaults write NSGlobalDomain AppleHighlightColor -string "0.764700 0.976500 0.568600"
```

**Purpose**: Set text selection highlight color to green
**Status**: Commented out - preference changed
**Domain**: NSGlobalDomain ✅ (exists)

---

### Animated Focus Ring (Line 34)

```bash
# defaults write NSGlobalDomain NSUseAnimatedFocusRing -bool false
```

**Purpose**: Disable the blue focus ring animation around UI elements
**Status**: Commented out - animation is acceptable
**Domain**: NSGlobalDomain ✅ (exists)

---

### Window Resize Speed (Line 44)

```bash
# defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
```

**Purpose**: Speed up window resize animations (almost instant)
**Status**: Commented out - default speed is fine
**Domain**: NSGlobalDomain ✅ (exists)

---

### Show Control Characters in Text (Line 68)

```bash
# defaults write NSGlobalDomain NSTextShowsControlCharacters -bool true
```

**Purpose**: Show ASCII control characters in text fields
**Status**: Commented out - rarely needed
**Domain**: NSGlobalDomain ✅ (exists)

---

### Automatic App Termination (Line 74)

```bash
# defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true
```

**Purpose**: Prevent macOS from automatically quitting apps to save memory
**Status**: Commented out - automatic termination works well
**Domain**: NSGlobalDomain ✅ (exists)

---

### Help Viewer Developer Mode (Line 80)

```bash
# defaults write com.apple.helpviewer DevMode -bool true
```

**Purpose**: Enable developer mode in Help Viewer (shows anchors, etc.)
**Status**: Commented out - not needed for general use
**Domain**: com.apple.helpviewer ✅ (likely exists)

---

## Input Devices

### Natural Scroll Direction (Line 131)

```bash
# defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
```

**Purpose**: Disable "natural" scrolling (make it traditional)
**Status**: Commented out - natural scrolling is now preferred
**Domain**: NSGlobalDomain ✅ (exists)

---

### Key Repeat Speed (Lines 150-151)

```bash
# defaults write NSGlobalDomain KeyRepeat -int 1
# defaults write NSGlobalDomain InitialKeyRepeat -int 10
```

**Purpose**: Set key repeat to maximum speed (faster than UI allows)
**Status**: Commented out - default speeds acceptable
**Domain**: NSGlobalDomain ✅ (exists)
**Note**: These still work, but values might be too aggressive

---

## Safari Settings (Lines 480-521)

⚠️ **All Safari settings commented out - likely because com.apple.Safari domain no longer works**

### Show Favorites Bar (Line 480)

```bash
# defaults write com.apple.Safari ShowFavoritesBar -bool false
```

**Purpose**: Hide Safari favorites bar
**Domain**: com.apple.Safari ❌ (doesn't exist)

---

### Show Sidebar in Top Sites (Line 483)

```bash
# defaults write com.apple.Safari ShowSidebarInTopSites -bool false
```

**Purpose**: Hide sidebar when viewing top sites
**Domain**: com.apple.Safari ❌ (doesn't exist)

---

### Bookmarks Bar Proxies (Line 495)

```bash
# defaults write com.apple.Safari ProxiesInBookmarksBar "()"
```

**Purpose**: Clear bookmarks bar (set to empty)
**Domain**: com.apple.Safari ❌ (doesn't exist)

---

### AutoFill Settings (Lines 511-514)

```bash
# defaults write com.apple.Safari AutoFillFromAddressBook -bool false
# defaults write com.apple.Safari AutoFillPasswords -bool false
# defaults write com.apple.Safari AutoFillCreditCardData -bool false
# defaults write com.apple.Safari AutoFillMiscellaneousForms -bool false
```

**Purpose**: Disable all AutoFill features in Safari
**Domain**: com.apple.Safari ❌ (doesn't exist)
**Note**: Safari preferences now stored elsewhere (likely ~/Library/Safari/)

---

### Plugin Support (Lines 520-521)

```bash
# defaults write com.apple.Safari WebKitPluginsEnabled -bool false
# defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2PluginsEnabled -bool false
```

**Purpose**: Disable plugin support (Flash, Java, etc.)
**Domain**: com.apple.Safari ❌ (doesn't exist)
**Note**: Plugins are deprecated anyway, modern Safari doesn't support them

---

## Dashboard (Line 725)

```bash
# defaults write com.apple.dashboard devmode -bool true
```

**Purpose**: Enable Dashboard developer mode
**Domain**: com.apple.dashboard ✅ (exists but Dashboard is deprecated)
**Note**: Dashboard was removed in macOS Catalina (10.15)

---

## Additional Commented Settings

**Note**: The above are the most significant commented settings. The full list includes:

- Various Safari preferences (15+ settings) - all using broken domain
- Finder view options
- Keyboard/Mouse settings that were too aggressive
- UI animations that were acceptable
- Features that are now deprecated (Dashboard, Java applets, etc.)

---

## Recommendations

### Should Be Re-Enabled

None - these were commented out for good reasons.

### Should Be Removed

1. **All Safari settings** (lines 480-521) - Domain doesn't exist, never worked
2. **Dashboard settings** (line 725) - Dashboard removed from macOS
3. **Plugin settings** (lines 520-521) - Plugins deprecated

### Should Be Investigated

1. **Key Repeat settings** (lines 150-151) - Still work, might be useful for power users
2. **Natural scroll** (line 131) - Some users prefer traditional scrolling
3. **Window resize speed** (line 44) - Some users like instant animations

---

## How to Test

To test if any of these settings still work:

1. **Uncomment the setting** in .macos
2. **Run the command manually**:

   ```bash
   defaults write NSGlobalDomain KeyRepeat -int 1
   ```

3. **Check current value**:

   ```bash
   defaults read NSGlobalDomain KeyRepeat
   ```

4. **Test the feature** (e.g., hold down a key to test repeat)
5. **Restart the app** if needed (e.g., `killall Finder`)

---

## Statistics

- **Total commented settings**: 51
- **Domains that don't exist**: Safari, Mail (partially)
- **Deprecated features**: Dashboard, Plugins
- **Still functional**: Most NSGlobalDomain settings
- **Recommended for deletion**: ~20 settings
- **Worth reconsidering**: ~5 settings (key repeat, scrolling)

---

**See also**: `docs/analysis/BROKEN_DOMAIN_SETTINGS.md` for active settings that don't work.
