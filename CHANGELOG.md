# Changelog

All notable changes to the DOGE Network Ruby Template will be documented in this file.

State sites can use this to understand what changed between versions and decide which updates to adopt.

## [0.3.0] - 2025-10-06

### Enhanced media updates

#### YouTube Embed Component
- **`_includes/youtube.html`** - New component for embedding YouTube videos
  - Easy to use: `{% include youtube.html id="VIDEO_ID" %}`
  - Responsive 16:9 aspect ratio
  - Styled to match site design
  - Loading spinner animation

#### Enhanced Tweet Embed Component
- **Loading spinner** - Visual feedback while tweets load
  - CSS animation for smooth spinning
  - Consistent with YouTube loading design
  - Improves user experience

### 🔄 Changed

#### Documentation
- **`README.md`** - Significantly enhanced with:
  - Better structured sections
  - Template contribution guidelines
  - Improved setup instructions
  - More comprehensive troubleshooting

- **`setup.rb`** - Code style improvements
  - Consistent string quoting
  - Better Ruby idioms

### 🗑️ Removed

#### Duplicate Files
- **`assets/css/main.scss`** - Removed duplicate SCSS file
  - Consolidated into `assets/main.scss`

### 📊 File Changes Summary

Files modified:
- `README.md` (+159 lines) - Enhanced documentation
- `_includes/tweet.html` (+113 lines) - Added loading spinner
- `assets/main.scss` (+38 lines) - Consolidated SCSS
- `setup.rb` (+22 lines) - Code style improvements
- `CHANGELOG.md` - this file

Files added:
- `_includes/youtube.html` (+73 lines) - New component

Files removed:
- `assets/css/main.scss` (-80 lines) - Duplicate removed

---

## [0.2.0] - 2025-10-05

### Template System Released

Converted from Kansas DOGE v0.1.0 into a reusable template for all state DOGE sites.

### ✨ Added

#### Template Variable System
- **Template variables** in all files for easy state customization:
  - `{{STATE_NAME}}` - Full state name (e.g., "Kansas")
  - `{{STATE_ABBREV}}` - State abbreviation (e.g., "KS") 
  - `{{STATE_SUBDOMAIN}}` - URL subdomain (e.g., "kansas")

- **Updated files** to use template variables:
  - `_config.yml` - Site configuration
  - `index.md` - Homepage
  - `savings.md` - Savings page
  - `regulations.md` - Regulations page
  - `_includes/header.html` - Site header

#### Automation Tools
- **`setup.rb`** - Interactive script to customize template for your state
  - Prompts for state information
  - Automatically replaces template variables
  - Provides next steps guidance

#### Documentation
- **`CHANGELOG.md`** (this file) - Version history
- Enhanced **`README.md`** with template usage instructions

### 🔄 Changed

#### Configuration (`_config.yml`)
- Added template variable definitions at top of file
- Changed `title` from hardcoded to template variable
- Changed `description` from hardcoded to template variable
- Changed `url` from hardcoded to template variable
- Changed `logo_state` path from `/Flag_of_Kansas.svg` to `/state-flag.svg`
- Added `template_repo` field for version tracking
- Updated version from `0.1.0` to `0.2.0`

#### Content Files
- **`index.md`**:
  - Changed FRED link to use template variables
  - Made state name dynamic in all references

- **`savings.md`**:
  - Changed page description to use template variables
  - Changed heading to use template variables
  - Changed state abbreviation in links to use template variables

- **`regulations.md`**:
  - Changed page description to use template variables
  - Changed heading to use template variables
  - Changed state references to use template variables

#### Assets
- Renamed `Flag_of_Kansas.svg` → `state-flag.svg` for generic placeholder

### 🔒 Backward Compatibility

This release maintains compatibility with:
- Jekyll 4.3.4
- Ruby 3.3.0
- Minima theme 2.5.1
- All existing Gemfile dependencies

No breaking changes to:
- Site structure
- URL patterns
- Styling/appearance
- Navigation system
- Include files (footer, header, tweet)

---

## [0.1.0] - 2025-10-05

### Initial Release (Kansas DOGE)

Original Kansas DOGE site features:
- Jekyll static site with Minima theme
- Custom header with state flag and DOGE Network logo
- Custom footer with DOGE Network branding
- Responsive card-based layout
- Page navigation system
- Example pages: Savings, Regulations
- Twitter embed support
- YouTube embed support

Files included:
- `_config.yml` - Kansas-specific configuration
- `index.md` - Homepage with Kansas data
- `savings.md` - Kansas government savings data
- `regulations.md` - Kansas regulatory information
- `_includes/header.html` - Custom header
- `_includes/footer.html` - Custom footer
- `_includes/tweet.html` - Twitter embed component
- `assets/main.scss` - Custom styling
- `Gemfile` - Ruby dependencies
- `README.md` - Setup instructions
- `LICENSE.md` - Apache 2.0 license

---

## Version Numbering

This template follows semantic versioning:

- **Major (X.0.0)**: Breaking changes requiring state site updates
- **Minor (0.X.0)**: New features, safe to adopt
- **Patch (0.0.X)**: Bug fixes, styling improvements

### What This Means for State Sites

- **0.2.0 → 0.3.0**: New features added, review and adopt what you want
- **0.2.0 → 1.0.0**: Breaking changes, careful migration required
- **0.2.0 → 0.2.1**: Bug fixes, safe to merge immediately

---

## How to Stay Updated

### Check for Updates

```bash
git diff template/master --name-only
```

### Review Before Merging

Always review changes before merging template updates:
1. Check this CHANGELOG for version notes
2. Test in a branch before merging to master
3. Preserve your state-specific customizations

---

## Questions?

- **Template issues**: Open issue at [DOGE_Network_Ruby_Template](https://github.com/DOGE-network/DOGE_Network_Ruby_Template)
- **General help**: [community@dogenetwork.org](mailto:community@dogenetwork.org)
- **Documentation**: [dogenetwork.org/docs](https://dogenetwork.org/docs)
