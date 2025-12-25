---
# Font Management System

This directory manages fonts across all Mac devices with a three-tier system.

---

## 📁 Directory Structure

```
files/fonts/
├── common/          # Fonts for ALL Macs (committed to git)
├── private/         # Fonts for private Macs only (committed to git)
└── licensed/        # Licensed fonts (NOT committed - in .gitignore)
```

---

## 🎯 Font Categories

### 1. **Common Fonts** (`common/`)

**Purpose**: Fonts installed on **all** Macs (business + private)

**Location**: `files/fonts/common/`

**Committed to Git**: ✅ Yes

**Requirements**: Only free/open-source fonts that can be redistributed

**Example**:

```bash
files/fonts/common/
├── SourceCodePro-Regular.ttf
├── Roboto-Regular.ttf
└── OpenSans-Bold.ttf
```

---

### 2. **Private Fonts** (`private/`)

**Purpose**: Fonts installed only on **private** Macs (odin, thor)

**Location**: `files/fonts/private/`

**Committed to Git**: ✅ Yes

**Requirements**: Only free/open-source fonts that can be redistributed

**Example**:

```bash
files/fonts/private/
├── ComicSans.ttf
└── FunFont.otf
```

---

### 3. **Licensed Fonts** (iCloud)

**Purpose**: Fonts that **cannot be redistributed** (commercial/licensed)

**Location**: `~/iCloudDrive/Allgemein/fonts/licensed/`

**Committed to Git**: ❌ **No** (in `.gitignore`)

**Installed on**: Private Macs only (odin, thor)

**Example**:

```bash
~/iCloudDrive/Allgemein/fonts/licensed/
├── DebiHandschrift4-Regular-1.ttf
├── DorfladeSennhof-Bold.ttf
└── DorfladeSennhof-Regular-1.ttf
```

---

## 🚀 Usage

### **Installing Fonts**

Run the font installation playbook:

```bash
./scripts/macapply --tags fonts
```

This will:

1. Install fonts from `files/fonts/common/` (all Macs)
2. Install fonts from `files/fonts/private/` (private Macs only)
3. Install fonts from `~/iCloudDrive/Allgemein/fonts/licensed/` (private Macs only)
4. Download Basisschrift and Hack Nerd Font (if not already installed)
5. Rebuild font cache

---

### **Adding New Fonts**

#### **Common or Private Fonts** (free to redistribute)

1. **Place font files** in the appropriate directory:

   ```bash
   # For all Macs:
   cp MyFont.ttf files/fonts/common/

   # For private Macs only:
   cp PrivateFont.ttf files/fonts/private/
   ```

2. **Commit and push**:

   ```bash
   git add files/fonts/
   git commit -m "feat: add new fonts"
   git push
   ```

3. **Apply on Macs**:

   ```bash
   ./scripts/macapply --tags fonts
   ```

---

#### **Licensed Fonts** (cannot be redistributed)

1. **Place font files in iCloud**:

   ```bash
   cp LicensedFont.ttf ~/iCloudDrive/Allgemein/fonts/licensed/
   ```

2. **Wait for iCloud sync** (automatic)

3. **Apply on private Macs**:

   ```bash
   # On odin or thor:
   ./scripts/macapply --tags fonts
   ```

---

## ⚙️ Configuration

Font settings are configured in:

**`inventories/group_vars/macs/fonts.yml`**

```yaml
# Enable/disable font installation
configure_fonts: true

# Directories
fonts_common_dir: "{{ playbook_dir }}/../files/fonts/common"
fonts_private_dir: "{{ playbook_dir }}/../files/fonts/private"

# Licensed fonts from iCloud
fonts_licensed_enabled: true
fonts_licensed_source: "{{ myhomedir }}/iCloudDrive/Allgemein/fonts/licensed"

# Target directory (user fonts)
fonts_target_dir: "{{ myhomedir }}/Library/Fonts"

# Supported formats
fonts_extensions:
  - "*.ttf"
  - "*.otf"
  - "*.TTF"
  - "*.OTF"
```

---

## 🔒 Security & Licensing

**IMPORTANT**: Only place fonts in `common/` or `private/` directories if you have the **right to redistribute** them!

**For commercial/licensed fonts**:

- ✅ Use the `licensed/` directory (via iCloud)
- ✅ These are **NOT committed to git** (in `.gitignore`)
- ✅ Only installed on your private Macs
- ✅ Never shared publicly

---

## 🧪 Testing

To verify font installation:

```bash
# List installed fonts
ls -la ~/Library/Fonts/

# Test font cache rebuild
atsutil databases -removeUser
```

---

## 📝 Supported Formats

- `.ttf` - TrueType Font
- `.otf` - OpenType Font
- `.TTF` - TrueType Font (uppercase)
- `.OTF` - OpenType Font (uppercase)

---

## 🎯 How It Works

The font installation process:

1. **Downloaded Fonts** (legacy):
   - Basisschrift from basisschrift.ch
   - Hack Nerd Font from GitHub

2. **File-based Fonts** (new system):
   - Scans `common/`, `private/`, and `licensed/` directories
   - Copies matching fonts to `~/Library/Fonts/`
   - Rebuilds font cache for macOS

3. **Conditional Installation**:
   - Common fonts: Always installed
   - Private fonts: Only on `private_mac` group
   - Licensed fonts: Only on `private_mac` group + iCloud available

---

**See also**: `inventories/group_vars/macs/fonts.yml` for configuration options
