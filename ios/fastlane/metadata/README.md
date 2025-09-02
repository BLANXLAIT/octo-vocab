# App Store Metadata

This directory contains automated App Store Connect metadata for Octo Vocab.

## File Structure

```
metadata/
└── en-US/
    ├── promotional_text.txt    # 170 character promotional text
    ├── description.txt         # 4000 character app description  
    ├── keywords.txt           # 100 character comma-separated keywords
    ├── support_url.txt        # Customer support URL
    ├── marketing_url.txt      # Marketing website URL
    ├── privacy_url.txt        # Privacy policy URL
    └── copyright.txt          # Copyright notice
```

## Usage

### Update Metadata Only
```bash
fastlane ios update_metadata
```

### Full Release with Metadata
```bash
fastlane ios release
```

## Editing Metadata

1. **Edit files in `metadata/en-US/`** - Each file contains the text for one App Store field
2. **Run `fastlane ios update_metadata`** - Uploads changes to App Store Connect
3. **Character limits** are enforced by App Store Connect, not fastlane

## Supported Languages

Currently configured for:
- **en-US** (English - United States)

Additional languages can be added by creating directories like:
- `metadata/es-ES/` (Spanish)
- `metadata/fr-FR/` (French)
- etc.

## Privacy-First Content

All metadata emphasizes Octo Vocab's privacy-first approach:
- Zero data collection
- Offline-first design
- Educational compliance (COPPA/FERPA)
- Open source transparency