# 02 — WordPress Plugin Architecture (100% Open Source)

## License & principles

- **License:** GPL-2.0-or-later (required for WordPress.org directory compatibility)
- **No phone-home telemetry** in v1 (trust = growth in WP community)
- **Export is portable:** JSON works without Liefle servers (self-host friendly)
- **Optional Liefle cloud:** template marketplace, AI mapping, deploy hooks (paid later)

## Plugin name (working)

**Liefle Headless Bridge**  
Slug: `liefle-headless-bridge`  
Text domain: `liefle-headless-bridge`

## File structure (target)

```
plugin/liefle-headless-bridge/
├── liefle-headless-bridge.php    # Bootstrap, hooks, constants
├── readme.txt                    # WP.org readme
├── uninstall.php                 # Clean options on delete
├── includes/
│   ├── class-exporter.php        # Build export array → JSON
│   ├── class-mapper.php          # Key ↔ WP entity resolution
│   ├── class-rest.php            # REST routes for headless frontend
│   ├── class-webhook.php         # Optional: POST to Vercel deploy hook
│   └── class-schema.php          # Validate export against JSON Schema
├── admin/
│   ├── class-admin-page.php      # Settings + mapper UI
│   ├── views/
│   │   ├── dashboard.php
│   │   ├── mapper.php
│   │   └── export.php
│   └── assets/
│       ├── admin.css
│       └── admin.js
└── languages/
```

## Core WordPress APIs you’ll use

| API | Purpose |
|-----|---------|
| `register_setting()` | Store mapper config |
| `add_options_page()` | Admin UI |
| `get_posts()` / `WP_Query` | Pull content |
| `get_post_meta()` / ACF `get_field()` | Custom fields |
| `wp_get_attachment_url()` | Media |
| `register_rest_route()` | Optional live endpoints for forms |
| `save_post` hook | Future: auto-export / webhook |

## Admin UI screens (MVP)

### 1. Dashboard

- Plugin version, export schema version
- Last export time + download button
- Link to docs

### 2. Key Mapper

Table UI:

| Key (you define) | Source type | Source |
|------------------|-------------|--------|
| `hero.title` | Page title | Page: Home |
| `hero.subtitle` | Custom field | Page: Home → `subtitle` |
| `about.body` | Post content | Page: About |
| `site.logo` | Media | Attachment ID 42 |

Store as option: `liefle_mapper_config` (JSON array).

### 3. Export

- **Download JSON** button
- Copy to clipboard
- Optional: **Push to URL** (user’s GitHub Gist, S3, or Liefle API key)

## REST endpoints (optional for forms / hybrid)

```
GET  /wp-json/liefle/v1/export     → same as JSON file (public or keyed)
POST /wp-json/liefle/v1/contact    → proxy to wp_mail or CF7
```

For **static MVP**, frontend doesn’t need runtime WP — only the JSON at build time. Add REST when you ship live forms.

## Security

- Export download: capability `manage_options` only
- Public REST export: **disabled by default**; optional read-only key in header
- Sanitize all mapper keys: `[a-z0-9._-]+` only
- Nonce on all admin actions

## ACF / page builder compatibility (later)

- **ACF:** read field keys by name
- **Elementor:** hard — stores JSON in post meta; v2+ module
- **Native blocks:** parse `post_content` block tree → extract headings (advanced)

MVP: **native title, content, excerpt, featured image, custom fields table**

## Bootstrap snippet (starting point)

```php
<?php
/**
 * Plugin Name: Liefle Headless Bridge
 * Description: Export WordPress content as structured key-value data for headless Next.js frontends.
 * Version: 0.1.0
 * License: GPL-2.0-or-later
 */

defined('ABSPATH') || exit;

define('LIEFLE_HB_VERSION', '0.1.0');
define('LIEFLE_HB_SCHEMA_VERSION', '1');

require_once __DIR__ . '/includes/class-exporter.php';
require_once __DIR__ . '/admin/class-admin-page.php';

add_action('plugins_loaded', function () {
    new Liefle_Admin_Page();
});
```

## Distribution

1. **GitHub** public repo (immediate)
2. **WordPress.org** plugin directory (after v0.2 stability + readme assets)
3. **Composer** not required for WP plugins; zip install is standard

Next: [03-export-schema.md](./03-export-schema.md)
