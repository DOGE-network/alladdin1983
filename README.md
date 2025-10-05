# DOGE Network Ruby Template

[![Version](https://img.shields.io/badge/Version-0.2.0-orange.svg)](https://github.com/DOGE-network/DOGE_Network_Ruby_Template)
[![Template](https://img.shields.io/badge/Template-DOGE%20Network%20Ruby-brightgreen.svg)](https://dogenetwork.org/)
[![Jekyll](https://img.shields.io/badge/Jekyll-4.3.4-blue.svg)](https://jekyllrb.com/)
[![Ruby](https://img.shields.io/badge/Ruby-3.3.0-red.svg)](https://www.ruby-lang.org/)
[![Minima Theme](https://img.shields.io/badge/Theme-Minima-green.svg)](https://github.com/jekyll/minima)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE.md)

A Jekyll template for creating state-specific DOGE Network websites. This template provides a clean, responsive design with built-in DOGE Network branding and easy customization for any US state.

## Quick Start

### 1. Use This Template

Click the **"Use this template"** button on GitHub to create your own repository from this template.

### 2. Run the Setup Script

```bash
ruby setup.rb
```

The script will ask for:
- State name (e.g., "Kansas")
- State abbreviation (e.g., "KS") 
- State URL subdomain (e.g., "kansas")

### 3. Install Dependencies

```bash
bundle install
```

### 4. Start Development Server

```bash
bundle exec jekyll serve
```

Visit [http://localhost:4000](http://localhost:4000) to see your site!

## Customization

### Replace State Flag

1. Download your state's flag SVG from [Wikipedia](https://en.wikipedia.org/wiki/List_of_U.S._state_flags)
2. Save it as `state-flag.svg` in the root directory
3. The site will automatically use your state's flag

### Update Content

Edit these files to add your state-specific content:

- **`index.md`** - Homepage content
- **`savings.md`** - Government savings and efficiency data
- **`regulations.md`** - State regulatory information
- **`_config.yml`** - Site configuration (already templated)

### Add New Pages

Create new `.md` files in the root directory. Each file with a `title` will automatically appear in the navigation menu.

Example:
```yaml
---
title: Workforce
description: State workforce and employment data
permalink: /workforce/
layout: page
---

## {{STATE_NAME}} Workforce Data

- Employment statistics
- Government hiring data
- Workforce development programs
```

## Template Variables

The template uses these variables that are automatically replaced by the setup script:

- `{{STATE_NAME}}` - Full state name (e.g., "Kansas")
- `{{STATE_ABBREV}}` - State abbreviation (e.g., "KS")
- `{{STATE_SUBDOMAIN}}` - URL subdomain (e.g., "kansas")

## Data Sources

- Start with [DOGE Network Tables Repository](https://github.com/DOGE-network/tables)
- Connect with people on [community@dogenetwork.org](mailto:community@dogenetwork.org) for ideas

## For State Sites: Syncing Template Updates

**This is the source template** that state sites sync FROM. When this template releases updates (v0.3.0, v0.4.0, etc.), state sites can review and adopt improvements.

### If You're Running a State Site

Check for template updates periodically:

```bash
ruby sync.rb
```

This interactive tool helps you:
1. Check for new template releases
2. Compare your files with latest template
3. Identify what's safe to merge vs. what needs review
4. View detailed file differences
5. Read the changelog

### Understanding File Categories

- **✅ Safe to merge**: Files without state-specific content (styling, dependencies, tools)
- **⚠️ Needs review**: Files with your state data (config, content pages)
- **🔧 Template tools**: Safe to update (setup.rb, sync.rb, docs)

See [CHANGELOG.md](CHANGELOG.md) for detailed version history and upgrade guidance.

### Manual Sync (Advanced)

For manual control:
```bash
# Setup template remote (run once)
ruby sync.rb  # Choose option 4

# Fetch template changes
git fetch template

# Compare specific file
git diff template/main -- _config.yml

# Review all changes
git diff template/main

# Merge specific file (after reviewing!)
git checkout template/main -- Gemfile
```

### Upgrade Guides

- **From v0.1.0 to v0.2.0**: See [UPGRADE_FROM_v0.1.0.md](UPGRADE_FROM_v0.1.0.md)
- **Future versions**: Check CHANGELOG.md for migration notes

## Deployment

### Vercel

- Request to be added to the Vercel deployment through [community@dogenetwork.org](mailto:community@dogenetwork.org)

## File Structure

```
├── _config.yml          # Site configuration (templated)
├── _includes/           # Reusable components
│   ├── header.html      # Site header (templated)
│   └── footer.html      # Site footer
├── assets/              # CSS and styling
├── index.md             # Homepage (templated)
├── savings.md           # Savings page (templated)
├── regulations.md       # Regulations page (templated)
├── state-flag.svg       # Your state's flag (replace this)
├── doge-network.png     # DOGE Network logo
├── setup.rb             # Template setup script
└── README.md            # This file
```

## Support

- **DOGE Network**: [community@dogenetwork.org](mailto:community@dogenetwork.org)
- **Documentation**: [dogenetwork.org/docs](https://dogenetwork.org/docs)

## License

This template is licensed under Apache 2.0 and CC-BY. See [LICENSE.md](LICENSE.md) for details.

---

**Built with ❤️ by the DOGE Network community**