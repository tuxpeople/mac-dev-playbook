# Broken Domain Settings (Non-Existent Domains)

**Source**: `~/development/github/tuxpeople/dotfiles/.macos`
**Total**: 33 active settings using domains that don't exist
**Date Analyzed**: 2025-12-24
**macOS Version**: 26.2

These settings are **NOT commented out** in .macos, but they **will fail silently** because their domains no longer exist in modern macOS.

---

## ❌ com.apple.Safari (24 settings)

**Status**: Domain does not exist in macOS 26.2
**Verification**: `defaults read com.apple.Safari` → "Domain com.apple.Safari does not exist"
**Impact**: All Safari preferences fail silently (no error shown, but settings not applied)

### Privacy & Search (Lines 460-461)

```bash
# Privacy: don't send search queries to Apple
defaults write com.apple.Safari UniversalSearchEnabled -bool false
defaults write com.apple.Safari SuppressSearchSuggestions -bool true
```

**Purpose**: Disable Spotlight suggestions in Safari search
**Current Status**: ❌ Not working (domain doesn't exist)
**Alternative**: Configure manually in Safari → Settings → Search

---

### Navigation & UI (Lines 464-471)

```bash
# Press Tab to highlight each item on a web page
defaults write com.apple.Safari WebKitTabToLinksPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2TabsToLinks -bool true

# Show the full URL in the address bar (note: this still hides the scheme)
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

# Set Safari's home page to `about:blank` for faster loading
defaults write com.apple.Safari HomePage -string "about:blank"
```

**Purpose**:

- Enable Tab navigation for links
- Show full URLs (privacy/security)
- Set blank homepage for speed

**Current Status**: ❌ Not working
**Alternative**: Safari → Settings → General/Advanced

---

### Downloads & File Handling (Lines 473-475)

```bash
# Prevent Safari from opening 'safe' files automatically after downloading
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

# Allow hitting the Backspace key to go to the previous page in history
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled -bool true
```

**Purpose**:

- Security: Prevent auto-opening downloaded files
- Enable Backspace for navigation

**Current Status**: ❌ Not working
**Alternative**: Safari → Settings → General → "Open 'safe' files after downloading"

---

### Debug & Developer Features (Lines 487-500)

```bash
# Disable Safari's thumbnail cache for History and Top Sites
defaults write com.apple.Safari DebugSnapshotsUpdatePolicy -int 2

# Enable Safari's debug menu
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

# Make Safari's search banners default to Contains instead of Starts With
defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false

# Enable the Develop menu and the Web Inspector in Safari
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
```

**Purpose**:

- Enable debug/developer tools
- Customize search behavior
- Disable thumbnail cache

**Current Status**: ❌ Not working
**Alternative**: Safari → Settings → Advanced → "Show Develop menu"

---

### Text & Spelling (Lines 502-505)

```bash
# Enable continuous spellchecking
defaults write com.apple.Safari WebContinuousSpellCheckingEnabled -bool true

# Disable auto-correct
defaults write com.apple.Safari WebAutomaticSpellingCorrectionEnabled -bool false
```

**Purpose**: Enable spellcheck but disable auto-correct
**Current Status**: ❌ Not working
**Alternative**: Safari → Settings → AutoFill/Search

---

### Security Settings (Lines 517-533)

```bash
# Warn about fraudulent websites
defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true

# Disable Java
defaults write com.apple.Safari WebKitJavaEnabled -bool false
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabled -bool false
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabledForLocalFiles -bool false

# Block pop-up windows
defaults write com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically -bool false
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaScriptCanOpenWindowsAutomatically -bool false
```

**Purpose**:

- Enable phishing protection
- Disable Java (deprecated anyway)
- Block JavaScript pop-ups

**Current Status**: ❌ Not working
**Note**: Java support removed from Safari anyway, so Java settings are irrelevant

---

### Privacy & Tracking (Lines 540-541)

```bash
# Enable "Do Not Track"
defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true
```

**Purpose**: Send Do Not Track header with requests
**Current Status**: ❌ Not working
**Note**: Do Not Track is deprecated web standard anyway

---

### Extensions (Line 544)

```bash
# Update extensions automatically
defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool true
```

**Purpose**: Auto-update Safari extensions
**Current Status**: ❌ Not working
**Alternative**: Safari → Settings → Extensions (auto-update is default anyway)

---

## ❌ com.apple.mail (9 settings)

**Status**: Domain does not exist in macOS 26.2
**Verification**: `defaults read com.apple.mail` → "Domain com.apple.mail does not exist"
**Impact**: All Mail.app preferences fail silently

### UI Animations (Lines 549-550)

```bash
# Disable send and reply animations in Mail.app
defaults write com.apple.mail DisableReplyAnimations -bool true
defaults write com.apple.mail DisableSendAnimations -bool true
```

**Purpose**: Disable animations when sending/replying to emails (faster)
**Current Status**: ❌ Not working
**Alternative**: None - animations cannot be disabled via preferences

---

### Email Address Formatting (Line 553)

```bash
# Copy email addresses as `foo@example.com` instead of `Foo Bar <foo@example.com>` in Mail.app
defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false
```

**Purpose**: Copy only email address, not display name
**Current Status**: ❌ Not working
**Alternative**: None - must manually edit when pasting

---

### Keyboard Shortcut (Line 556)

```bash
# Add the keyboard shortcut ⌘ + Enter to send an email in Mail.app
defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Send" "@\U21a9"
```

**Purpose**: Add ⌘+Enter shortcut to send emails (like Gmail)
**Current Status**: ❌ Not working
**Alternative**: System Settings → Keyboard → Keyboard Shortcuts → App Shortcuts

---

### Threading & Sorting (Lines 559-561)

```bash
# Display emails in threaded mode, sorted by date (oldest at the top)
defaults write com.apple.mail DraftsViewerAttributes -dict-add "DisplayInThreadedMode" -string "yes"
defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortedDescending" -string "yes"
defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortOrder" -string "received-date"
```

**Purpose**: Configure email threading and sort order
**Current Status**: ❌ Not working
**Alternative**: Mail → View → Organize by Conversation / Sort By

---

### Attachments (Line 564)

```bash
# Disable inline attachments (just show the icons)
defaults write com.apple.mail DisableInlineAttmentViewing -bool true
```

**Purpose**: Show attachment icons instead of inline previews
**Current Status**: ❌ Not working (also has typo: "Attachm**ent**")
**Alternative**: None - inline attachments are default

---

### Spell Checking (Line 567)

```bash
# Disable automatic spell checking
defaults write com.apple.mail SpellCheckingBehavior -string "NoSpellCheckingEnabled"
```

**Purpose**: Disable spell checking in composed emails
**Current Status**: ❌ Not working
**Alternative**: Mail → Edit → Spelling and Grammar

---

## Impact Analysis

### Safari Settings (24 broken)

| Category | Count | Severity |
|----------|-------|----------|
| Privacy/Security | 8 | 🔴 High |
| Developer Tools | 5 | 🟡 Medium |
| UI/UX | 6 | 🟢 Low |
| Deprecated (Java/Plugins) | 5 | ⚪ None |

**Total Impact**: 🔴 **High** - Many important privacy/security settings not being applied

---

### Mail Settings (9 broken)

| Category | Count | Severity |
|----------|-------|----------|
| UX (animations, shortcuts) | 4 | 🟡 Medium |
| Threading/Sorting | 3 | 🟢 Low |
| Spell Check | 1 | 🟢 Low |
| Attachments | 1 | 🟢 Low |

**Total Impact**: 🟡 **Medium** - Mostly convenience features, not critical

---

## Recommendations

### Immediate Action Required

1. **Research new Safari preferences location**:
   - Check `~/Library/Safari/`
   - Check if preferences moved to iCloud sync
   - Check if new domain exists (e.g., `com.apple.Safari.v2`)

2. **Test Safari settings manually**:

   ```bash
   # Find Safari-related domains
   defaults domains | tr ',' '\n' | grep -i safari
   ```

3. **Research new Mail preferences location**:

   ```bash
   # Find Mail-related domains
   defaults domains | tr ',' '\n' | grep -i mail
   ```

---

### Short-term Solutions

**Option A: Remove broken settings**

```bash
# Comment out or remove lines 460-544 (Safari)
# Comment out or remove lines 549-567 (Mail)
```

**Pros**: Clean up .macos script, reduce confusion
**Cons**: Settings will need to be configured manually

---

**Option B: Add compatibility check**

```bash
# Add to .macos before Safari settings:
if defaults read com.apple.Safari &> /dev/null; then
    echo "Configuring Safari settings..."
    # ... Safari settings here ...
else
    echo "⚠️  Safari domain not found - skipping Safari settings"
    echo "   Configure manually in Safari → Settings"
fi
```

**Pros**: Script won't fail silently, user gets feedback
**Cons**: Still need to configure manually

---

**Option C: Research and update**

- Spend time finding new preference locations
- Update .macos with working commands
- Test on macOS 26.2

**Pros**: Settings work again
**Cons**: Time-consuming, may break on future macOS updates

---

### Long-term Strategy

1. **Accept that Safari/Mail preferences are no longer scriptable**:
   - Apple is moving away from `defaults` for app preferences
   - More settings are now synced via iCloud
   - Some settings are intentionally not exposed to prevent abuse

2. **Document manual configuration**:
   - Create checklist for Safari settings
   - Create checklist for Mail settings
   - Include in new Mac setup docs

3. **Focus Ansible on system-level settings**:
   - Keep Finder, Dock, System Preferences in Ansible
   - App-specific settings stay manual
   - Better separation of concerns

---

## Testing Commands

### Check if Safari domain exists (different variations)

```bash
defaults domains | tr ',' '\n' | grep -i safari
ls ~/Library/Preferences/com.apple.Safari*
ls ~/Library/Safari/
```

### Check if Mail domain exists

```bash
defaults domains | tr ',' '\n' | grep -i mail
ls ~/Library/Preferences/com.apple.mail*
ls ~/Library/Mail/
```

### Find all preferences domains

```bash
defaults domains | tr ',' '\n' | sort
```

---

## Statistics

- **Total broken settings**: 33 (24 Safari + 9 Mail)
- **Lines affected**: 460-567 in .macos script
- **Percentage of .macos**: ~11% of script is broken
- **Est. impact**: High for Safari (privacy/security), Medium for Mail (UX)

---

## Related Files

- **Source**: `~/development/github/tuxpeople/dotfiles/.macos`
- **See also**: `docs/analysis/COMMENTED_MACOS_SETTINGS.md` (51 already-commented settings)
- **Audit report**: `docs/sessions/MACOS_SETTINGS_AUDIT_2025-12-24.md`

---

**Next Steps**: Decide whether to remove, comment out, or research alternatives for these 33 broken settings.
