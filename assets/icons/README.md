# App Icons

## Required Icons

The following app icons are required for the Flutter launcher icons configuration:

### Production
- `app_icon.png` - Main production app icon (1024x1024)

### Development
- `app_icon_dev.png` - Development environment icon (1024x1024)
  - Should have a visual indicator (e.g., "DEV" badge or green tint)

### Staging
- `app_icon_staging.png` - Staging environment icon (1024x1024)
  - Should have a visual indicator (e.g., "STAGING" badge or yellow tint)

## Current Icons

The following logo files are available and can be used as base:
- `logo.png`
- `logo_16.png`
- `logo_32.png`
- `logo_64.png`
- `logo_128.png`
- `logo_256.png`
- `logo_512.png`
- `logo_1024.png`

## Generating Icons

You can use `logo_1024.png` as the base for app icons:

```bash
# Copy logo as production icon
cp logo_1024.png app_icon.png

# For dev and staging, add badges using image editing tools
# or use the generate_icons.py script in the tools/ directory
```

## After Adding Icons

Run the following command to generate platform-specific icons:

```bash
flutter pub run flutter_launcher_icons
```
