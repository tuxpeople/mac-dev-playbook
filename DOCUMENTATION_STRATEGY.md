# Documentation Strategy - mac-dev-playbook

> **How documentation is organized across Repository and Obsidian**

## 🔑 TL;DR - Quick Reference

**Need technical implementation details?** → Look here (Git Repository)

- How to install: `README.md`
- Complete reference: `CLAUDE.md`
- Detailed guides: `docs/`

**Need conceptual understanding & integration?** → Look in Obsidian

- Path: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Personal/📚 Wissen/🏠 Persönlich/🎨 Hobbys/Homelab/Clients/macOS/`
- Why Ansible was chosen (Decision Records)
- How this integrates with Homelab infrastructure
- Business vs. Private conceptual differences
- Operational procedures & workflows

**Key Principle:** Repository = HOW | Obsidian = WHY & WHAT

## 🎯 Philosophy: Layered Documentation

This repository follows a **layered documentation approach** that separates operational truth (code) from conceptual integration (knowledge management).

### Two Documentation Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    OBSIDIAN (Conceptual)                     │
│  📚 Homelab/Clients/macOS/                                   │
│  - WHY these tools/choices?                                  │
│  - Integration into Homelab                                  │
│  - Business vs Private differences (concepts)                │
│  - Decision Records                                          │
│  - Operational procedures                                    │
│  - Cross-references to other Homelab areas                   │
└─────────────────────────────────────────────────────────────┘
                              ↕
                    Cross-References
                              ↕
┌─────────────────────────────────────────────────────────────┐
│              GIT REPOSITORY (Operational)                    │
│  💻 /Volumes/development/github/tuxpeople/mac-dev-playbook   │
│  - HOW to run playbooks?                                     │
│  - Technical setup & installation                            │
│  - Ansible playbook code (source of truth)                   │
│  - Role documentation                                        │
│  - Variable references                                       │
│  - Troubleshooting (technical)                               │
└─────────────────────────────────────────────────────────────┘
```

## 📂 What Goes Where?

### Repository (This Location)

**Operational Truth - How Things Work:**

```
mac-dev-playbook/
├── README.md               # Quick Start, Setup, Basic Usage
├── CLAUDE.md              # Complete technical reference for AI
├── DOCUMENTATION_STRATEGY.md  # This file
│
├── docs/                  # Technical Documentation
│   ├── installation.md    # Detailed setup instructions
│   ├── playbooks.md       # Playbook reference
│   ├── roles.md           # Role documentation
│   ├── variables.md       # Variable reference
│   └── troubleshooting.md # Technical issues & solutions
│
├── playbooks/             # Ansible playbooks (code)
├── roles/                 # Ansible roles (code)
├── inventory/             # Inventory files (config)
└── group_vars/            # Variables (config)
```

**Repository Documentation Contains:**

- ✅ Installation & setup instructions
- ✅ How to run playbooks
- ✅ Technical reference (variables, roles, tasks)
- ✅ Code-level documentation
- ✅ Troubleshooting technical issues
- ✅ Contribution guidelines
- ✅ Changelog

### Obsidian Vault (External)

**Conceptual Integration - Why & Context:**

```
Obsidian: ~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Personal/
└── 📚 Wissen/🏠 Persönlich/🎨 Hobbys/Homelab/Clients/macOS/
    ├── README.md                  # Overview & Integration
    ├── Ansible-Playbooks.md       # What each playbook does (concepts)
    ├── Application-Management.md  # App lifecycle philosophy
    ├── Configuration-Profiles.md  # Why these settings
    └── Business-vs-Private.md     # Conceptual differences
```

**Obsidian Documentation Contains:**

- ✅ WHY Ansible was chosen (Decision Records)
- ✅ Integration with Homelab infrastructure
- ✅ Business vs Private differences (conceptual)
- ✅ Links to related Homelab documentation
- ✅ High-level operational procedures
- ✅ Context & decision history

> ⚠️ **Important:** Concepts, decisions, and integration context live in Obsidian, NOT in this repository.
> Don't duplicate conceptual content here - use cross-references instead.

## 🔗 Cross-Referencing

### From Repository → Obsidian

**In repository documentation, reference Obsidian for context:**

```markdown
# README.md

For the conceptual overview and integration with the Homelab:
See: Obsidian → Homelab/Clients/macOS/README.md

For decision history (why Ansible, not manual setup):
See: Obsidian → Homelab/Decisions/Why Ansible for Mac Management.md
```

### From Obsidian → Repository

**In Obsidian documentation, reference Repository for technical details:**

```markdown
# Obsidian: Homelab/Clients/macOS/README.md

For technical setup and playbook execution:
See: `/Volumes/development/github/tuxpeople/mac-dev-playbook/README.md`

For complete technical reference:
See: `/Volumes/development/github/tuxpeople/mac-dev-playbook/CLAUDE.md`
```

## 📝 Documentation Files in This Repository

### Core Documentation

#### README.md

**Purpose:** Quick start for humans
**Content:**

- Project overview
- Prerequisites
- Quick installation
- Basic usage examples
- Common tasks
- Links to detailed docs

**Keep it:** Short, actionable, beginner-friendly

---

#### CLAUDE.md

**Purpose:** Complete technical reference for AI assistants
**Content:**

- Full project structure
- All playbooks & roles explained
- Variables & their purposes
- Technical decisions
- Troubleshooting reference
- Best practices

**Keep it:** Comprehensive, technical, AI-optimized

---

#### DOCUMENTATION_STRATEGY.md (This File)

**Purpose:** Explain documentation architecture
**Content:**

- Layered documentation concept
- What goes where (Repository vs Obsidian)
- Cross-referencing guidelines
- Update procedures

---

### Extended Documentation (docs/)

#### docs/installation.md

**Purpose:** Detailed setup guide
**Content:**

- Prerequisites (detailed)
- Step-by-step installation
- Configuration options
- Verification steps

---

#### docs/playbooks.md

**Purpose:** Playbook reference
**Content:**

- List of all playbooks
- What each playbook does (technical)
- Parameters & options
- Example invocations

---

#### docs/roles.md

**Purpose:** Role reference
**Content:**

- Role structure
- Tasks in each role
- Dependencies
- Variables

---

#### docs/variables.md

**Purpose:** Variable reference
**Content:**

- All available variables
- Default values
- Where they're used
- Examples

---

#### docs/troubleshooting.md

**Purpose:** Common issues & solutions
**Content:**

- Error messages & fixes
- Platform-specific issues
- Workarounds
- Known limitations

## 🔄 Keeping Documentation in Sync

### When Code Changes

**Repository Update Process:**

1. Update code (playbooks, roles, variables)
2. Update `CLAUDE.md` (technical reference)
3. Update relevant `docs/*.md` files
4. Update `README.md` if usage changes
5. Commit with clear message

**Obsidian Update Process:**

1. Only if *concepts* change (why, integration)
2. Update Decision Records if architecture changes
3. Update integration docs if dependencies change
4. Cross-references should remain stable

### Version Control

**Repository:**

- All changes tracked in Git
- Semantic versioning for major changes
- Changelog maintained

**Obsidian:**

- Versioned via Obsidian Git Plugin (if enabled)
- Or manual backups (iCloud)
- Date stamps in frontmatter

## 🎨 Documentation Best Practices

### For Repository Documentation

**Style:**

- ✅ Technical and precise
- ✅ Code examples included
- ✅ Markdown formatting
- ✅ Keep it DRY (Don't Repeat Yourself)

**Structure:**

- Clear headings
- Table of contents for long docs
- Examples before explanations
- Links to related docs

**Maintenance:**

- Update with code changes
- Test examples regularly
- Remove outdated content
- Keep CLAUDE.md comprehensive

### For Obsidian Documentation

**Style:**

- ✅ Conceptual and contextual
- ✅ Links to other Homelab areas
- ✅ Decision-focused
- ✅ Integration-focused

**Structure:**

- Emoji prefixes for visual navigation
- Cross-references to repository
- Tags for discoverability
- Frontmatter for metadata

**Maintenance:**

- Update when concepts change
- Add Decision Records for major choices
- Maintain cross-references
- Keep integration current

## 🤖 AI Assistant Support

### CLAUDE.md (Primary AI Reference)

This repository includes `CLAUDE.md` as a complete technical reference for AI assistants like Claude.

**Purpose:**

- Provide full context to AI in a single file
- Enable autonomous task completion
- Maintain consistency across sessions
- Reduce need for repeated explanations

**Update When:**

- New playbooks/roles added
- Structure changes
- New features implemented
- Best practices evolve

### Documentation Strategy for AI

**AI assistants should:**

1. Read `CLAUDE.md` first for full context
2. Reference `README.md` for quick overview
3. Check `docs/` for specific details
4. Understand Repository vs Obsidian separation
5. Maintain both documentation layers when changes occur

## 📊 Documentation Metrics

**Good Documentation:**

- New user can set up in < 30 minutes
- Common tasks have clear examples
- AI assistant can complete tasks autonomously
- Cross-references are accurate and helpful
- No conflicting information across layers

**Maintenance Indicators:**

- Last updated date on each doc
- Changelog tracks major changes
- Examples tested and working
- No dead links

## 🔗 Related Documentation

**In This Repository:**

- `README.md` - Quick start
- `CLAUDE.md` - Complete technical reference
- `CHANGELOG.md` - Version history

**In Obsidian Vault:**

- `Homelab/Clients/macOS/README.md` - macOS overview
- `Homelab/Clients/README.md` - Client management
- `Homelab/README.md` - Homelab hub
- `Homelab/Documentation Strategy.md` - Vault-wide strategy

**External:**

- [Ansible Documentation](https://docs.ansible.com/)
- [Homebrew Documentation](https://docs.brew.sh/)
- [macOS Defaults](https://macos-defaults.com/)

## 📋 Checklist: Adding New Features

When adding a new feature/playbook/role:

**Repository:**

- [ ] Implement code (playbook/role)
- [ ] Update `CLAUDE.md` with technical details
- [ ] Update `docs/playbooks.md` or `docs/roles.md`
- [ ] Add examples to relevant docs
- [ ] Update `README.md` if necessary
- [ ] Test thoroughly
- [ ] Commit with clear message
- [ ] Update `CHANGELOG.md`

**Obsidian (if applicable):**

- [ ] Update concept docs if *why* changes
- [ ] Add Decision Record for major choices
- [ ] Update integration docs if dependencies change
- [ ] Refresh cross-references

---

**Maintained By:** Thomas Deutsch
**Last Updated:** 2025-12-20
**Repository:** `/Volumes/development/github/tuxpeople/mac-dev-playbook`
**Obsidian Vault:** `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Personal/📚 Wissen/🏠 Persönlich/🎨 Hobbys/Homelab/Clients/macOS/`
