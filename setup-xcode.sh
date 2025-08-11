#!/bin/bash

# CoverCraft Xcode Setup Script
# This script opens and configures the CoverCraft project in Xcode

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 CoverCraft Xcode Setup${NC}"
echo -e "${BLUE}=========================${NC}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Get the script directory (project root)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Check if we're in the right directory
if [ ! -f "CoverCraft.xcworkspace/contents.xcworkspacedata" ]; then
    print_error "This script must be run from the CoverCraft_Xcode_Project directory"
    exit 1
fi

print_info "Setting up CoverCraft in Xcode..."

# Check if Xcode is installed
if ! command -v xcodebuild >/dev/null 2>&1; then
    print_error "Xcode is not installed!"
    print_info "Please install Xcode from the App Store"
    exit 1
fi

# Get Xcode version
XCODE_VERSION=$(xcodebuild -version | head -n1 | awk '{print $2}')
print_status "Xcode version: $XCODE_VERSION"

# Clean derived data (optional, but helps avoid cached issues)
print_info "Cleaning derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/CoverCraft-* 2>/dev/null || true

# Resolve Swift packages
print_info "Resolving Swift package dependencies..."
cd CoverCraftPackage
if swift package resolve; then
    print_status "Swift packages resolved successfully"
else
    print_warning "Failed to resolve packages - Xcode will try again when opened"
fi
cd ..

# Select Xcode if multiple versions installed
if command -v xcode-select >/dev/null 2>&1; then
    XCODE_PATH=$(xcode-select -p)
    print_info "Using Xcode at: $XCODE_PATH"
fi

# Create a simple Xcode configuration file
print_info "Creating Xcode workspace settings..."
mkdir -p CoverCraft.xcworkspace/xcshareddata/
cat > CoverCraft.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>BuildSystemType</key>
    <string>Latest</string>
    <key>DisableBuildSystemDeprecationDiagnostic</key>
    <true/>
    <key>PreviewsEnabled</key>
    <true/>
    <key>ShowSharedSchemesAutomaticallyEnabled</key>
    <true/>
</dict>
</plist>
EOF

# Set recommended scheme settings
print_info "Configuring build scheme..."
mkdir -p CoverCraft.xcodeproj/xcshareddata/xcschemes/ 2>/dev/null || true

# Check if simulator is available
print_info "Checking for iPhone 16 simulator..."
if xcrun simctl list devices | grep -q "iPhone 16"; then
    print_status "iPhone 16 simulator found"
    SIMULATOR_FOUND=true
else
    print_warning "iPhone 16 simulator not found - you may need to download it in Xcode"
    SIMULATOR_FOUND=false
fi

# Build the project to verify setup
print_info "Performing test build..."
if [ "$SIMULATOR_FOUND" = true ]; then
    if xcodebuild -workspace CoverCraft.xcworkspace \
                  -scheme CoverCraft \
                  -configuration Debug \
                  -destination "platform=iOS Simulator,name=iPhone 16" \
                  -quiet \
                  build 2>/dev/null; then
        print_status "Test build successful!"
    else
        print_warning "Test build failed - check Xcode for details"
    fi
else
    print_info "Skipping test build (simulator not available)"
fi

# Open Xcode with the workspace
print_info "Opening Xcode..."
open CoverCraft.xcworkspace

# Wait a moment for Xcode to open
sleep 2

# Print instructions
echo ""
print_status "Xcode setup complete!"
echo ""
print_info "Next steps in Xcode:"
echo "  1. Wait for package resolution to complete (see progress in Activity View)"
echo "  2. Select 'CoverCraft' scheme in the toolbar (if not already selected)"
echo "  3. Select 'iPhone 16' as the destination device"
echo "  4. Press ⌘+B to build or ⌘+R to run"
echo ""

if [ "$SIMULATOR_FOUND" = false ]; then
    print_warning "Additional setup needed:"
    echo "  - Download iPhone 16 simulator: Xcode → Settings → Platforms → iOS"
fi

print_info "Project structure:"
echo "  • Main app: CoverCraft/"
echo "  • Swift Package: CoverCraftPackage/"
echo "  • Documentation: docs/"
echo "  • CI/CD: .github/workflows/"
echo ""

print_info "Development tips:"
echo "  • Always open CoverCraft.xcworkspace (not .xcodeproj)"
echo "  • Main development happens in CoverCraftPackage/Sources/CoverCraftFeature/"
echo "  • Run tests with ⌘+U"
echo "  • Clean build with ⌘+Shift+K"
echo ""

print_status "Happy coding! 🎉"