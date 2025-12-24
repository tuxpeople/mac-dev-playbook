# .macos to Ansible Migration Plan

**Date**: 2025-12-24
**Goal**: Migrate working settings from .macos to Ansible, remove broken/commented settings

---

## Overview

**Current State**:
- .macos script: 952 lines
- 228 `defaults write` commands total
- 51 commented out (documented in COMMENTED_MACOS_SETTINGS.md)
- 33 broken (Safari/Mail, documented in BROKEN_DOMAIN_SETTINGS.md)
- **182 working settings** to evaluate for migration

**Target State**:
- System-level settings → Ansible (defaults.yml)
- App-specific stable settings → Ansible (optional)
- User app settings (Chrome, iTerm2) → Stay in .macos
- Broken/commented → Removed (documented)

---

## Phase 1: High-Priority System Settings → Ansible

**Total**: 71 settings
**Priority**: 🔴 High
**Timeline**: Now

### Categories

#### 1. NSGlobalDomain (25 settings)
**Currently in Ansible**: 1 (AppleShowAllExtensions)
**To migrate**: 24

**Examples**:
```bash
# Sidebar icon size
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2

# Always show scrollbars
defaults write NSGlobalDomain AppleShowScrollBars -string "Always"

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true

# Disable automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
```

**Ansible format**:
```yaml
- domain: NSGlobalDomain
  key: NSTableViewDefaultSizeMode
  name: Set sidebar icon size to medium
  type: int
  value: '2'
```

---

#### 2. Finder (19 settings)
**Currently in Ansible**: 7 (Desktop icons, hidden files, status bar, path bar)
**To migrate**: 12

**Examples**:
```bash
# Show icons for hard drives, servers, and removable media on the desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Finder: show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Disable warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Default view style (list view)
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
```

---

#### 3. Dock (22 settings)
**Currently in Ansible**: 3 (tilesize, orientation, autohide)
**To migrate**: 19

**Examples**:
```bash
# Minimize windows into their application's icon
defaults write com.apple.dock minimize-to-application -bool true

# Show indicator lights for open applications
defaults write com.apple.dock show-process-indicators -bool true

# Don't animate opening applications
defaults write com.apple.dock launchanim -bool false

# Don't show recent applications
defaults write com.apple.dock show-recents -bool false
```

---

#### 4. Screen Settings (5 settings)
**Currently in Ansible**: 1 (screensaver idleTime)
**To migrate**: 4

**Examples**:
```bash
# Screenshot format
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# Save screenshots to ~/Screenshots
defaults write com.apple.screencapture location -string "${HOME}/Screenshots"
```

---

## Phase 2: Medium-Priority App Settings → Ansible

**Total**: 13 settings
**Priority**: 🟡 Medium
**Timeline**: Later (optional)

### Categories

#### 1. Activity Monitor (5 settings)
```bash
# Show all processes
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
```

#### 2. TextEdit (3 settings)
**Currently in Ansible**: 1 (RichText)
**To migrate**: 2

```bash
# Use plain text mode for new documents
defaults write com.apple.TextEdit RichText -int 0

# Open and save files as UTF-8
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4
```

#### 3. Terminal (3 settings)
```bash
# Only use UTF-8 in Terminal.app
defaults write com.apple.terminal StringEncodings -array 4
```

#### 4. DiskUtility (2 settings)
```bash
# Enable debug menu
defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
```

---

## Phase 3: Keep in .macos (Low-Priority)

**Total**: ~98 settings
**Priority**: 🟢 Low
**Action**: Keep in .macos

### Categories

1. **Chrome/Chrome Canary** (8 settings)
   - External app, frequent updates
   - Better to keep in .macos

2. **iTerm2** (1 setting)
   - External app
   - Better to keep in .macos

3. **Other app-specific** (~89 settings)
   - Software Update, Time Machine, etc.
   - Less critical, can migrate later if desired

---

## Phase 4: Cleanup .macos

**Action**: Remove documented broken/commented settings

### Step 1: Remove Commented Settings (51 lines)
**Source**: COMMENTED_MACOS_SETTINGS.md

**Lines to remove**:
- Lines 21, 24, 34, 44 (NSGlobalDomain commented settings)
- Lines 68, 74, 80 (More NSGlobalDomain)
- Lines 131, 150-151 (Input devices)
- Lines 480-521 (Safari - all commented)
- Line 725 (Dashboard)
- And more...

**Method**:
```bash
# Create backup first
cp ~/.macos ~/.macos.backup-$(date +%Y%m%d)

# Manual removal or sed script
```

---

### Step 2: Remove Broken Domain Settings (46 lines)
**Source**: BROKEN_DOMAIN_SETTINGS.md

**Lines to remove**:
- Lines 460-544 (Safari - domain doesn't exist)
- Lines 549-567 (Mail - domain doesn't exist)

**Method**:
```bash
# Remove Safari section
sed -i.bak '/### Safari ###/,/### Mail ###/d' ~/.macos

# Or manual removal
```

---

## Implementation Steps

### Prep
```bash
# 1. Backup .macos
cp ~/development/github/tuxpeople/dotfiles/.macos \
   ~/development/github/tuxpeople/dotfiles/.macos.backup-2025-12-24

# 2. Backup defaults.yml
cp inventories/group_vars/macs/defaults.yml \
   inventories/group_vars/macs/defaults.yml.backup-2025-12-24
```

### Phase 1: Migrate High-Priority Settings
```bash
# Extract working settings from .macos
# Convert to Ansible YAML format
# Add to defaults.yml
# Test on current Mac
```

### Phase 2: Cleanup .macos
```bash
# Remove commented lines
# Remove broken Safari/Mail settings
# Test .macos script still works
```

### Phase 3: Verify
```bash
# Run Ansible to apply new settings
./scripts/macapply --tags osx

# Run cleaned .macos script
cd ~/development/github/tuxpeople/dotfiles
./.macos
```

---

## Migration Template

### From .macos:
```bash
defaults write com.apple.dock show-recents -bool false
```

### To Ansible (defaults.yml):
```yaml
- domain: com.apple.dock
  key: show-recents
  name: Don't show recent applications in Dock
  type: bool
  value: 'false'
```

### Conversion Rules:
- `-bool true` → `type: bool`, `value: 'true'`
- `-bool false` → `type: bool`, `value: 'false'`
- `-int 2` → `type: int`, `value: '2'`
- `-string "foo"` → `type: string`, `value: 'foo'`
- `-array 4` → `type: array`, `value: '<array><integer>4</integer></array>'`
- `-dict-add` → Multiple entries or complex structure

---

## Benefits

### After Migration:
1. **Idempotent**: Ansible ensures settings are applied consistently
2. **Versionable**: Settings tracked in git with history
3. **Testable**: Can test on one Mac before rolling out
4. **Documented**: Each setting has a descriptive name
5. **Grouped**: Settings organized by domain in defaults.yml
6. **Cleaner .macos**: Only app-specific settings remain

### Statistics:
- **Before**: 952 lines in .macos, 17 settings in Ansible
- **After**: ~600 lines in .macos, ~90 settings in Ansible
- **Reduction**: ~37% smaller .macos script
- **Coverage**: 5x more settings managed by Ansible

---

## Next Steps

**Immediate**:
1. ✅ Backup both files
2. 🔄 Start with Phase 1 - migrate high-priority settings (71)
3. ⏳ Test on current Mac
4. ⏳ Clean up .macos (remove 97 broken/commented lines)

**Later** (optional):
5. Migrate Phase 2 settings (13 app-specific)
6. Review remaining .macos settings
7. Document any manual settings discovered

---

**Estimated Time**:
- Phase 1 (migration): 2-3 hours
- Cleanup: 30 minutes
- Testing: 30 minutes
- **Total**: ~3-4 hours

**Risk**: Low (we have backups and documentation)
