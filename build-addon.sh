#!/bin/bash

# ShaguScan Addon Build Script
# Creates a release package containing only the files needed for WoW

set -e

# Configuration
ADDON_NAME="ShaguScan"
BUILD_DIR="build"
PACKAGE_DIR="$BUILD_DIR/$ADDON_NAME"
RELEASE_DIR="releases"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "ShaguScan.toc" ]; then
    log_error "ShaguScan.toc not found. Please run this script from the addon root directory."
    exit 1
fi

# Extract version from TOC file
VERSION=$(grep "^## Version:" ShaguScan.toc | cut -d' ' -f3)
if [ -z "$VERSION" ]; then
    log_warning "Version not found in TOC file, using 'dev'"
    VERSION="dev"
fi

log_info "Building $ADDON_NAME version $VERSION"

# Clean previous build
if [ -d "$BUILD_DIR" ]; then
    log_info "Cleaning previous build..."
    rm -rf "$BUILD_DIR"
fi

# Create build directory structure
log_info "Creating build directory structure..."
mkdir -p "$PACKAGE_DIR"
mkdir -p "$RELEASE_DIR"

# Copy addon files (exclude development files)
log_info "Copying addon files..."

# Essential addon files
cp "ShaguScan.toc" "$PACKAGE_DIR/"
cp "ShaguScan.lua" "$PACKAGE_DIR/"
cp "LICENSE" "$PACKAGE_DIR/"

# Copy directory structures
cp -r "init/" "$PACKAGE_DIR/"
cp -r "core/" "$PACKAGE_DIR/"
cp -r "api/" "$PACKAGE_DIR/"
cp -r "modules/" "$PACKAGE_DIR/"
cp -r "fonts/" "$PACKAGE_DIR/"
cp -r "img/" "$PACKAGE_DIR/"

# Include user documentation
if [ -f "README.md" ]; then
    cp "README.md" "$PACKAGE_DIR/"
fi

# Exclude development files from the package
log_info "Cleaning development files from package..."
find "$PACKAGE_DIR" -name "*.bak" -delete
find "$PACKAGE_DIR" -name "*.tmp" -delete
find "$PACKAGE_DIR" -name ".DS_Store" -delete

# Remove development documentation
rm -rf "$PACKAGE_DIR"/*.md 2>/dev/null || true
rm -rf "$PACKAGE_DIR"/pfui-reference 2>/dev/null || true
rm -rf "$PACKAGE_DIR"/node_modules 2>/dev/null || true
rm -rf "$PACKAGE_DIR"/.git* 2>/dev/null || true
rm -rf "$PACKAGE_DIR"/.vscode 2>/dev/null || true
rm -rf "$PACKAGE_DIR"/screenshots 2>/dev/null || true
rm -rf "$PACKAGE_DIR"/mcp.json 2>/dev/null || true
rm -rf "$PACKAGE_DIR"/package*.json 2>/dev/null || true
rm -rf "$PACKAGE_DIR"/build-addon.sh 2>/dev/null || true
rm -rf "$PACKAGE_DIR"/*_PLAN.md 2>/dev/null || true
rm -rf "$PACKAGE_DIR"/*_ANALYSIS.md 2>/dev/null || true
rm -rf "$PACKAGE_DIR"/*_REFERENCE.md 2>/dev/null || true
rm -rf "$PACKAGE_DIR"/CLAUDE.md 2>/dev/null || true

# Verify essential files exist
log_info "Verifying package contents..."
ESSENTIAL_FILES=("ShaguScan.toc" "ShaguScan.lua" "init" "core" "api" "modules")
for file in "${ESSENTIAL_FILES[@]}"; do
    if [ ! -e "$PACKAGE_DIR/$file" ]; then
        log_error "Essential file/directory missing: $file"
        exit 1
    fi
done

# Display package contents
log_info "Package contents:"
find "$PACKAGE_DIR" -type f | sort | sed 's|^'$PACKAGE_DIR'/||' | sed 's/^/  /'

# Create zip archive
ARCHIVE_NAME="$ADDON_NAME-$VERSION.zip"
log_info "Creating archive: $ARCHIVE_NAME"

cd "$BUILD_DIR"
zip -r "../$RELEASE_DIR/$ARCHIVE_NAME" "$ADDON_NAME" -q

cd ..

# Display final information
ARCHIVE_SIZE=$(du -h "$RELEASE_DIR/$ARCHIVE_NAME" | cut -f1)
log_success "Build complete!"
log_info "Archive: $RELEASE_DIR/$ARCHIVE_NAME ($ARCHIVE_SIZE)"
log_info "Package directory: $PACKAGE_DIR"

# Instructions for testing
echo ""
log_info "Testing Instructions:"
echo "  1. Extract $RELEASE_DIR/$ARCHIVE_NAME to your WoW AddOns directory"
echo "  2. The addon should appear as: Interface/AddOns/$ADDON_NAME/"
echo "  3. Restart WoW and test the addon with /scan"
echo ""
log_info "Development: Package contents available in $PACKAGE_DIR for inspection"

# Optional: Open releases directory
if command -v nautilus &> /dev/null; then
    log_info "Opening releases directory..."
    nautilus "$RELEASE_DIR" 2>/dev/null || true
elif command -v explorer &> /dev/null; then
    log_info "Opening releases directory..."
    explorer "$RELEASE_DIR" 2>/dev/null || true
fi