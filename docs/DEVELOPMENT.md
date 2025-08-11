# Development Setup Guide

## Prerequisites

### System Requirements
- **macOS 14.0+** (required for iOS 18 development)
- **Xcode 16.0+** with iOS 18.0 SDK
- **Git** (pre-installed with Xcode Command Line Tools)
- **Homebrew** (package manager for development tools)

### Hardware Requirements
- **Apple Silicon (M1/M2/M3/M4)** or Intel Mac with macOS 14+
- **16GB RAM minimum** (32GB recommended for large builds)
- **50GB free disk space** (for Xcode, simulators, and derived data)

## Quick Setup

### Option 1: Automated Setup (Recommended)
```bash
# Clone the repository
git clone <repository-url>
cd CoverCraft_Xcode_Project

# Run automated setup script
./scripts/setup-dev.sh
```

### Option 2: Manual Setup
Follow the manual installation steps below if the automated script fails or you prefer manual control.

## Manual Installation

### 1. Install Development Tools

#### Homebrew (if not installed)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### Essential Tools
```bash
# Code quality and linting
brew install swiftlint

# Build and testing tools  
brew install xcbeautify jq bc

# Security scanning
brew install dependency-check

# Optional: Additional utilities
brew install gh          # GitHub CLI
brew install fastlane    # iOS automation (if needed)
```

### 2. Configure Git Hooks
```bash
# Set up pre-commit hooks
git config core.hooksPath .githooks

# Verify hooks are executable
chmod +x .githooks/pre-commit
```

### 3. Validate Installation
```bash
# Check tool versions
swiftlint version
xcbeautify --version
dependency-check --version

# Test Swift package resolution
cd CoverCraftPackage
swift package resolve
swift build  # Should build successfully
cd ..
```

## Project Structure

```
CoverCraft_Xcode_Project/
├── CoverCraft.xcworkspace          # Main workspace
├── CoverCraft/                     # App target (minimal)
├── CoverCraftPackage/              # Swift Package (main development)
│   ├── Package.swift
│   ├── Sources/
│   │   ├── CoverCraftCore/         # Contracts and models
│   │   └── CoverCraftFeature/      # Main features
│   └── Tests/                      # All tests
├── Config/                         # Build configuration
├── docs/                           # Documentation
├── scripts/                        # Development scripts
└── .github/workflows/              # CI/CD pipelines
```

## Development Workflow

### 1. Daily Development

#### Opening the Project
```bash
# Always open the workspace, not the project
open CoverCraft.xcworkspace
```

#### Code Quality Checks
```bash
# Run linting (automatically runs on commit)
swiftlint lint --config .swiftlint.yml

# Auto-fix linting issues
swiftlint autocorrect --config .swiftlint.yml

# Manual build with pretty output
xcodebuild -workspace CoverCraft.xcworkspace \
           -scheme CoverCraft \
           -destination "platform=iOS Simulator,name=iPhone 16" \
           build | xcbeautify
```

#### Running Tests
```bash
# iOS tests through Xcode
xcodebuild test -workspace CoverCraft.xcworkspace \
                -scheme CoverCraft \
                -destination "platform=iOS Simulator,name=iPhone 16"

# Swift Package tests (may have macOS compatibility issues)
cd CoverCraftPackage
swift test
```

### 2. Before Committing

The pre-commit hook automatically runs these checks:
- SwiftLint validation
- Swift syntax checking  
- TODO/FIXME detection
- Print statement warnings
- Force unwrapping detection

To bypass (not recommended):
```bash
git commit --no-verify -m "Your message"
```

### 3. Dependency Management

#### Adding New Dependencies
```bash
# Edit CoverCraftPackage/Package.swift
# Then resolve dependencies
cd CoverCraftPackage
swift package resolve

# Test the build
swift build

# Update documentation
# Edit docs/DEPENDENCIES.md with new dependency info
```

#### Updating Dependencies
```bash
# Use the provided script
./scripts/update-dependencies.sh

# Or manually
cd CoverCraftPackage
swift package update
```

#### Security Scanning
```bash
# Run OWASP dependency check
dependency-check --project "CoverCraft" \
                 --scan "CoverCraftPackage" \
                 --format "HTML" \
                 --out "./dependency-reports"
```

## IDE Configuration

### Xcode Settings

#### Essential Settings
1. **Preferences → Text Editing → Indentation**
   - Prefer indent using: **Spaces**
   - Tab width: **4 spaces**
   - Indent width: **4 spaces**

2. **Preferences → Text Editing → Editing**
   - ✅ Automatically trim trailing whitespace
   - ✅ Including whitespace-only lines

3. **Preferences → Behaviors → Build**
   - ✅ Show navigator: **Issue Navigator**

#### Recommended Xcode Extensions
- **SwiftLint for Xcode** (real-time linting)
- **Git Streaks** (Git integration)
- **SimSim** (simulator management)

### Build Schemes

#### CoverCraft Scheme Configuration
- **Build Configuration**: Debug (development), Release (App Store)
- **Destination**: iPhone 16 (primary), iPad Pro 13-inch M4 (tablet testing)
- **Coverage**: Enabled for Debug builds
- **Warnings as Errors**: Enabled in Release builds

## Troubleshooting

### Common Issues

#### Build Failures
```bash
# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData/CoverCraft-*

# Clean Swift Package build
cd CoverCraftPackage
swift package clean
swift package resolve

# Reset Xcode package caches
File → Packages → Reset Package Caches
```

#### SwiftLint Issues
```bash
# Update SwiftLint
brew upgrade swiftlint

# Check configuration
swiftlint lint --config .swiftlint.yml --reporter emoji

# Fix auto-correctable issues
swiftlint autocorrect --config .swiftlint.yml
```

#### Simulator Issues
```bash
# List available simulators
xcrun simctl list devices available

# Reset simulator
xcrun simctl shutdown all
xcrun simctl erase all

# Boot specific simulator
xcrun simctl boot "iPhone 16"
```

#### Git Hooks Not Working
```bash
# Verify hooks are executable
ls -la .githooks/
chmod +x .githooks/pre-commit

# Check Git configuration
git config core.hooksPath
git config core.hooksPath .githooks
```

### Performance Issues

#### Slow Builds
1. **Enable parallel builds**: Xcode → Preferences → Behaviors → Build → Parallel
2. **Increase build threads**: Defaults write com.apple.dt.Xcode IDEBuildOperationMaxNumberOfConcurrentCompileTasks 8
3. **SSD optimization**: Ensure Xcode and project are on SSD

#### Memory Issues
1. **Close unused Xcode tabs** and projects
2. **Restart Xcode** periodically during long development sessions
3. **Monitor Activity Monitor** for memory usage

## CI/CD Integration

### GitHub Actions
The project includes automated CI/CD that runs on:
- **Push to main/develop**: Full pipeline
- **Pull requests**: All checks required to pass
- **Daily**: Dependency security scans

### Pipeline Stages
1. **Lint**: SwiftLint code quality checks
2. **Build**: Multi-configuration builds (Debug/Release)
3. **Test**: Unit and integration tests
4. **Coverage**: 90% minimum code coverage
5. **Security**: OWASP dependency vulnerability scanning

### Local CI Testing
```bash
# Simulate CI environment locally
export CI=true
.github/workflows/ci.yml  # Use act or similar tool
```

## Documentation

### Key Documents
- **[DEPENDENCIES.md](DEPENDENCIES.md)**: Dependency tracking
- **[DEPENDENCY_POLICY.md](DEPENDENCY_POLICY.md)**: Dependency approval process  
- **[API_VERSIONS.md](API_VERSIONS.md)**: API version compatibility
- **[DEPRECATED_APIS.md](DEPRECATED_APIS.md)**: Deprecated API tracking
- **[CLAUDE.md](../CLAUDE.md)**: Project architecture and guidelines

### Code Documentation
- Use Swift documentation comments (`///`) for all public APIs
- Include usage examples in documentation
- Document actor isolation requirements
- Explain concurrency patterns

## Team Collaboration

### Code Review Guidelines
1. **Automated checks must pass** before review
2. **Test coverage must be ≥90%** for new code
3. **Documentation required** for public APIs
4. **Performance impact** should be considered for UI changes

### Branch Strategy
- **main**: Production-ready code
- **develop**: Integration branch for features
- **feature/***: Individual feature development
- **hotfix/***: Critical production fixes

### Commit Message Format
```
type(scope): brief description

Longer explanation if needed

- Specific changes
- Breaking changes noted
- References to issues/PRs
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

---

## Quick Reference

### Essential Commands
```bash
# Setup
./scripts/setup-dev.sh

# Development
open CoverCraft.xcworkspace
swiftlint lint
swiftlint autocorrect

# Testing  
xcodebuild test -workspace CoverCraft.xcworkspace -scheme CoverCraft -destination "platform=iOS Simulator,name=iPhone 16"

# Dependencies
./scripts/update-dependencies.sh
dependency-check --project "CoverCraft" --scan "CoverCraftPackage"

# Cleanup
rm -rf ~/Library/Developer/Xcode/DerivedData/CoverCraft-*
cd CoverCraftPackage && swift package clean
```

### Support
- **Issues**: Create GitHub issue with reproduction steps
- **Questions**: Check existing documentation first
- **Improvements**: Submit PR with tests and documentation

---

*Last updated: 2025-01-14*  
*Next review: 2025-04-14*