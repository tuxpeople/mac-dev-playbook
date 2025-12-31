# Business Mac LaunchAgents Analysis (UMB-L3VWMGM77F)
**Date**: 2025-12-31
**Host**: UMB-L3VWMGM77F (Business Mac)

## Summary
- User LaunchAgents: 10
- System LaunchAgents: 30
- System LaunchDaemons: 30+

## Analysis by Category

### ✅ KEEP (Business-kritisch)

**MDM & Management:**
- com.microsoft.intuneMDMAgent.* (2) - Microsoft Intune MDM
- com.ws1.* (2) - Workspace ONE MDM
- com.googlecode.munki.* (11) - Munki Software Management

**Security:**
- com.sentinelone.* (6) - SentinelOne Antivirus
- com.qualys.* (3) - Qualys Security Scanner
- at.obdev.littlesnitch.daemon.plist - Firewall
- com.zscaler.tray.plist - Zscaler VPN/Security

**Business Tools:**
- ch.umb.* (2) - UMB custom agents
- com.citrix.* (12) - Citrix Workspace/VDI
- com.omnissa.horizon.CDSHelper - VMware Horizon
- com.logmein.GoToMeeting.* (2) - GoToMeeting

**Development Tools:**
- homebrew.mxcl.node_exporter.plist - Prometheus monitoring
- homebrew.mxcl.tailscale.plist - Tailscale VPN
- com.canonical.multipassd.plist - Multipass VMs

**Already in Config (disabled):**
- org.gpgtools.* (4) - GPGTools

### ⚠️ INVESTIGATE

**Unknown/Suspicious:**
- com.testsys.SBMonitor.plist - Was ist das?
- com.snap.AssistantService.plist - Snap? Welches Tool?

### 🔴 DISABLE (Auto-Updaters)

**Already disabled in base config:**
- ✅ com.google.keystone.* (3)
- ✅ com.google.GoogleUpdater.wake.plist

**Should add to base config:**
- com.microsoft.EdgeUpdater.* (2) - Edge Auto-Update
- com.microsoft.update.agent.plist - Office Auto-Update
- com.microsoft.autoupdate.helper.plist - Auto-Update Helper
- com.microsoft.OneDriveStandaloneUpdater* (2) - OneDrive Auto-Update
- com.microsoft.teams.TeamsUpdaterDaemon - Teams Auto-Update
- com.microsoft.SyncReporter.plist - Sync Reporter

**Optional (könnte auch behalten werden):**
- com.logi.optionsplus.* (2) - Logitech Options+ Auto-Update
- com.displaylink.loginscreen.plist - DisplayLink

### 📊 Comparison: Business vs Private Mac

**Only on Business Mac:**
- Intune MDM (2)
- Workspace ONE MDM (2)  
- SentinelOne (6)
- Qualys (3)
- Citrix (12)
- Zscaler (1)
- UMB custom (2)
- GoToMeeting (2)
- Omnissa Horizon (1)
- DisplayLink (1)
- Logitech Options+ (3)
- Snap Assistant (1)
- com.testsys.SBMonitor (1)

**Total Business-specific**: ~40 agents/daemons

## Recommendations

### 1. Disable Microsoft Auto-Updaters (business_mac config)
```yaml
# inventories/group_vars/business_mac/LaunchAgents.yml
launch_agents_to_disable:
  # Microsoft Auto-Updaters (managed by Intune)
  - "com.microsoft.EdgeUpdater.wake"
  - "com.microsoft.EdgeUpdater.update.system"
  - "com.microsoft.EdgeUpdater.wake.system"
  - "com.microsoft.update.agent"
  - "com.microsoft.autoupdate.helper"
  - "com.microsoft.OneDriveStandaloneUpdater"
  - "com.microsoft.OneDriveStandaloneUpdaterDaemon"
  - "com.microsoft.OneDriveUpdaterDaemon"
  - "com.microsoft.teams.TeamsUpdaterDaemon"
  - "com.microsoft.SyncReporter"
```

### 2. Investigate Unknown Agents
- com.testsys.SBMonitor - Security tool? Hardware monitoring?
- com.snap.AssistantService - Snap Camera? Screen recording?

### 3. Keep Everything Else
- Security tools are business-critical (SentinelOne, Qualys, Zscaler)
- MDM must stay (Intune, Workspace ONE, Munki)
- Business tools needed (Citrix, Horizon, GoToMeeting)
