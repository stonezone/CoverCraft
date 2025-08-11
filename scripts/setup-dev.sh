#!/bin/bash

# CoverCraft Development Environment Setup
# Installs and configures all development tools

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 CoverCraft Development Environment Setup${NC}"
echo -e "${BLUE}=============================================${NC}"

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

# Check if running from correct directory
if [ ! -f "CoverCraft.xcworkspace/contents.xcworkspacedata" ]; then
    print_error "This script must be run from the project root directory"
    print_error "Expected to find: CoverCraft.xcworkspace/"
    exit 1
fi

print_info "Setting up development environment for CoverCraft..."

# Check system requirements
print_info "Checking system requirements..."

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
MACOS_MAJOR=$(echo $MACOS_VERSION | cut -d. -f1)
MACOS_MINOR=$(echo $MACOS_VERSION | cut -d. -f2)

if [ "$MACOS_MAJOR" -lt 14 ]; then
    print_error "macOS 14.0+ required for iOS 18 development (found: $MACOS_VERSION)"
    exit 1
fi

print_status "macOS version: $MACOS_VERSION ✓"

# Check Xcode installation
if ! command -v xcodebuild >/dev/null 2>&1; then
    print_error "Xcode not found! Install Xcode 16.0+ from the App Store"
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -n1 | awk '{print $2}')
print_status "Xcode version: $XCODE_VERSION ✓"

# Check Homebrew installation
if ! command -v brew >/dev/null 2>&1; then
    print_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

print_status "Homebrew installed ✓"

# Install development tools
print_info "Installing development tools..."

# SwiftLint
if ! command -v swiftlint >/dev/null 2>&1; then
    print_info "Installing SwiftLint..."
    brew install swiftlint
else
    print_status "SwiftLint already installed"
fi

SWIFTLINT_VERSION=$(swiftlint version)
print_status "SwiftLint version: $SWIFTLINT_VERSION ✓"

# xcbeautify (for readable build logs)
if ! command -v xcbeautify >/dev/null 2>&1; then
    print_info "Installing xcbeautify..."
    brew install xcbeautify
else
    print_status "xcbeautify already installed"
fi

# jq (for JSON processing in CI)
if ! command -v jq >/dev/null 2>&1; then
    print_info "Installing jq..."
    brew install jq
else
    print_status "jq already installed"
fi

# bc (for floating point calculations)
if ! command -v bc >/dev/null 2>&1; then
    print_info "Installing bc..."
    brew install bc
else
    print_status "bc already installed"
fi

# OWASP Dependency Check (for security scanning)
if ! command -v dependency-check >/dev/null 2>&1; then
    print_info "Installing OWASP Dependency Check..."
    brew install dependency-check
else
    print_status "OWASP Dependency Check already installed"
fi

# Set up Git hooks
print_info "Setting up Git hooks..."

if [ -d ".git" ]; then
    # Install pre-commit hook
    if [ -f ".githooks/pre-commit" ]; then
        cp ".githooks/pre-commit" ".git/hooks/pre-commit"
        chmod +x ".git/hooks/pre-commit"
        print_status "Pre-commit hook installed"
    fi
    
    # Configure Git to use local hooks
    git config core.hooksPath .githooks
    print_status "Git hooks configured"
else
    print_warning "Not a Git repository - skipping hook installation"
fi

# Create necessary directories
print_info "Creating project directories..."

mkdir -p dependency-check-reports
mkdir -p .dependency-backups
mkdir -p build-logs
mkdir -p test-reports

print_status "Project directories created"

# Validate project structure
print_info "Validating project structure..."

REQUIRED_FILES=(
    "CoverCraft.xcworkspace/contents.xcworkspacedata"
    "CoverCraftPackage/Package.swift"
    ".swiftlint.yml"
    ".github/workflows/ci.yml"
    "docs/DEPENDENCIES.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_status "$file ✓"
    else
        print_error "Missing required file: $file"
        exit 1
    fi
done

# Test Swift Package resolution
print_info "Testing Swift Package resolution..."
cd CoverCraftPackage
if swift package resolve; then
    print_status "Swift packages resolved successfully"
else
    print_error "Failed to resolve Swift packages"
    exit 1
fi
cd ..

# Test build
print_info "Testing project build..."
if xcodebuild -workspace CoverCraft.xcworkspace -scheme CoverCraft -configuration Debug -destination "platform=iOS Simulator,name=iPhone 16" build >/dev/null 2>&1; then
    print_status "Project builds successfully"
else
    print_warning "Project build test failed - this may be expected if simulators aren't set up"
fi

# Run SwiftLint validation
print_info "Running SwiftLint validation..."
if swiftlint --config .swiftlint.yml; then
    print_status "SwiftLint validation passed"
else
    print_warning "SwiftLint found issues - run 'swiftlint autocorrect' to fix automatically"
fi

# Create .env file for local development
print_info "Creating development environment file..."
cat > .env.local << EOF
# CoverCraft Local Development Environment
# This file is ignored by Git - add local settings here

# Xcode settings
XCODE_VERSION=16.0
IOS_VERSION=18.0
SWIFT_VERSION=6.0

# Simulator settings
DEFAULT_SIMULATOR=iPhone 16

# Build settings
BUILD_CONFIGURATION=Debug
DERIVED_DATA_PATH=./DerivedData

# Testing settings
RUN_TESTS_ON_BUILD=false
COVERAGE_ENABLED=true
MIN_COVERAGE_THRESHOLD=90

# Development flags
ENABLE_PREVIEW_FEATURES=false
STRICT_CONCURRENCY_CHECKING=true

# Logging
LOG_LEVEL=debug
STRUCTURED_LOGGING=true
EOF

print_status "Development environment file created (.env.local)"

# Summary
print_info "Development environment setup complete! 🎉"
echo ""
print_info "Next steps:"
print_info "1. Open CoverCraft.xcworkspace in Xcode"
print_info "2. Select your preferred simulator (iPhone 16 recommended)"
print_info "3. Build and run the project (⌘+R)"
print_info "4. Run tests (⌘+U)"
echo ""
print_info "Available commands:"
print_info "- ./scripts/update-dependencies.sh    # Update dependencies"
print_info "- swiftlint autocorrect               # Fix linting issues"
print_info "- dependency-check --help             # Security scanning"
echo ""
print_info "Documentation:"
print_info "- docs/DEPENDENCIES.md               # Dependency information"
print_info "- docs/DEPENDENCY_POLICY.md          # Dependency policies"
print_info "- CLAUDE.md                          # Project guidelines"
echo ""
print_status "Happy coding! 🚀"