# ShaguScan Build Process

This document describes how to build and release ShaguScan addon packages.

## Local Development Build

### Prerequisites
- Bash shell (Linux/macOS/WSL)
- `zip` command available
- Run from the addon root directory

### Build Script
```bash
./build-addon.sh
```

### What the Script Does
1. **Extracts version** from `ShaguScan.toc` file
2. **Creates build directory** structure
3. **Copies addon files**:
   - `ShaguScan.toc` and `ShaguScan.lua`
   - `init/`, `core/`, `api/`, `modules/` directories
   - `fonts/` and `img/` media files
   - `LICENSE` file
4. **Cleans development files**:
   - Removes `*.bak`, `*.tmp`, development docs
   - Excludes `pfui-reference/`, `node_modules/`, etc.
5. **Verifies package** contains essential files
6. **Creates ZIP archive** in `releases/` directory

### Output
- **Archive**: `releases/ShaguScan-{version}.zip`
- **Package directory**: `build/ShaguScan/` (for inspection)
- **Size**: ~400KB (fonts and images included)

### Testing
1. Extract the generated ZIP to your WoW AddOns directory
2. Restart WoW
3. Test with `/scan` command

## Automated GitHub Releases

### Triggering a Release
```bash
# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0
```

### What the GitHub Action Does
1. **Triggers on version tags** (e.g., `v1.0.0`)
2. **Builds addon package** using same logic as local script
3. **Generates release notes** with installation instructions
4. **Creates GitHub release** with ZIP attachment
5. **Uploads build artifact** for 30-day retention

### Manual Release
You can also trigger a release manually:
1. Go to GitHub Actions tab
2. Select "Create Release" workflow
3. Click "Run workflow"

## File Structure

### Included in Release
```
ShaguScan/
├── ShaguScan.toc          # Addon manifest
├── ShaguScan.lua          # Bootstrap file
├── LICENSE                # License file
├── init/                  # XML manifests
├── core/                  # Core environment
├── api/                   # API layer
├── modules/               # Feature modules
├── fonts/                 # Embedded fonts
└── img/                   # Textures and images
```

### Excluded from Release
- Development documentation (`*.md` except README)
- Reference repositories (`pfui-reference/`)
- Build tools (`build-addon.sh`, `.github/`)
- Configuration files (`.vscode/`, `mcp.json`, etc.)
- Temporary files (`*.bak`, `*.tmp`)

## Version Management

### Version Sources
1. **Git tags**: `v1.0.0` → version `1.0.0`
2. **TOC file**: `## Version: 1.0` → version `1.0`
3. **Fallback**: `dev-{timestamp}` for manual builds

### Updating Version
Update the version in `ShaguScan.toc`:
```
## Version: 1.1.0
```

Then create a git tag:
```bash
git tag v1.1.0
git push origin v1.1.0
```

## Build Verification

### Essential Files Check
The build process verifies these files exist:
- `ShaguScan.toc`
- `ShaguScan.lua`
- `init/` directory
- `core/` directory
- `api/` directory
- `modules/` directory

### Package Contents
The script displays all files included in the package for verification.

## Troubleshooting

### Common Issues
1. **"ShaguScan.toc not found"**: Run script from addon root directory
2. **"Essential file missing"**: Check if required directories exist
3. **"Permission denied"**: Make script executable with `chmod +x build-addon.sh`

### Build Directory
The `build/` directory contains the uncompressed package for inspection and debugging.

## Development Workflow

### Local Testing
1. Make changes to addon files
2. Run `./build-addon.sh`
3. Extract to WoW AddOns directory
4. Test in-game

### Release Process
1. Test changes locally
2. Update version in `ShaguScan.toc`
3. Commit changes
4. Create and push version tag
5. GitHub automatically creates release