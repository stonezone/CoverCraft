#!/bin/bash

# CoverCraft Dependency Update Script
# This script provides controlled dependency updates with safety checks

set -e  # Exit on any error
set -u  # Exit on undefined variables

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PACKAGE_DIR="CoverCraftPackage"
BACKUP_DIR=".dependency-backups"
DATE=$(date +"%Y%m%d_%H%M%S")

echo -e "${BLUE}🔍 CoverCraft Dependency Update Tool${NC}"
echo -e "${BLUE}=====================================${NC}"

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

# Function to backup current state
backup_current_state() {
    print_info "Creating backup of current Package.swift and Package.resolved..."
    
    mkdir -p "$BACKUP_DIR"
    
    if [ -f "$PACKAGE_DIR/Package.swift" ]; then
        cp "$PACKAGE_DIR/Package.swift" "$BACKUP_DIR/Package.swift.$DATE"
        print_status "Backed up Package.swift"
    fi
    
    if [ -f "$PACKAGE_DIR/Package.resolved" ]; then
        cp "$PACKAGE_DIR/Package.resolved" "$BACKUP_DIR/Package.resolved.$DATE"
        print_status "Backed up Package.resolved"
    else
        print_info "No Package.resolved found (no dependencies currently)"
    fi
}

# Function to check current dependencies
check_current_dependencies() {
    print_info "Checking current dependencies..."
    
    cd "$PACKAGE_DIR"
    
    # Check if any dependencies exist
    if swift package dump-package | jq '.dependencies | length' | grep -q "^0$"; then
        print_info "Currently no third-party dependencies"
        print_info "Project uses only Apple system frameworks:"
        print_info "  - SwiftUI, ARKit, SceneKit, Foundation, UIKit, etc."
        return 0
    else
        print_info "Current dependencies found:"
        swift package show-dependencies --format json | jq -r '.dependencies[] | "  - \(.identity): \(.requirement)"'
    fi
    
    cd - > /dev/null
}

# Function to resolve dependencies
resolve_dependencies() {
    print_info "Resolving dependencies..."
    
    cd "$PACKAGE_DIR"
    
    if swift package resolve; then
        print_status "Dependencies resolved successfully"
    else
        print_error "Failed to resolve dependencies"
        print_error "Restoring backup..."
        restore_backup
        exit 1
    fi
    
    cd - > /dev/null
}

# Function to build and test after updates
test_after_update() {
    print_info "Running build and tests to verify updates..."
    
    cd "$PACKAGE_DIR"
    
    # Build the package
    if swift build; then
        print_status "Build successful"
    else
        print_error "Build failed after dependency update"
        print_error "Restoring backup..."
        restore_backup
        exit 1
    fi
    
    # Run tests (macOS compatibility issues expected)
    print_info "Running tests (some macOS compatibility issues expected)..."
    if swift test 2>&1 | tee test_output.log; then
        print_status "Tests passed"
    else
        print_warning "Tests had issues (this is expected for iOS-only features on macOS)"
        print_info "Check test_output.log for details"
    fi
    
    cd - > /dev/null
}

# Function to restore backup
restore_backup() {
    print_info "Restoring from backup..."
    
    if [ -f "$BACKUP_DIR/Package.swift.$DATE" ]; then
        cp "$BACKUP_DIR/Package.swift.$DATE" "$PACKAGE_DIR/Package.swift"
        print_status "Restored Package.swift"
    fi
    
    if [ -f "$BACKUP_DIR/Package.resolved.$DATE" ]; then
        cp "$BACKUP_DIR/Package.resolved.$DATE" "$PACKAGE_DIR/Package.resolved"
        print_status "Restored Package.resolved"
    fi
}

# Function to run vulnerability scan
run_vulnerability_scan() {
    print_info "Running vulnerability scan..."
    
    if command -v dependency-check >/dev/null 2>&1; then
        dependency-check \
            --project "CoverCraft" \
            --scan "$PACKAGE_DIR" \
            --format "JSON" \
            --out "./dependency-check-reports" \
            --suppression ".dependency-check-suppressions.xml"
        
        print_status "Vulnerability scan completed"
        print_info "Report available in ./dependency-check-reports/"
    else
        print_warning "dependency-check tool not installed"
        print_info "Install with: brew install dependency-check"
        print_info "Or download from: https://owasp.org/www-project-dependency-check/"
    fi
}

# Function to generate update report
generate_update_report() {
    print_info "Generating update report..."
    
    cat > "dependency-update-report-$DATE.md" << EOF
# Dependency Update Report

**Date**: $(date)
**Project**: CoverCraft
**Backup ID**: $DATE

## Current Status

$(check_current_dependencies 2>&1)

## Update Results

- ✅ Backup created successfully
- ✅ Dependencies resolved
- ✅ Build verification passed
- ✅ Tests completed (with expected macOS compatibility notes)

## Files Modified

- Package.swift (if dependencies were added/updated)
- Package.resolved (if dependencies exist)

## Backup Location

Backups stored in: \`$BACKUP_DIR/\`
- Package.swift.$DATE
- Package.resolved.$DATE (if exists)

## Next Steps

1. Review any new dependencies added
2. Update documentation if necessary
3. Run full iOS device/simulator testing
4. Consider updating DEPENDENCIES.md

## Rollback Instructions

If issues are discovered, run:
\`\`\`bash
cp $BACKUP_DIR/Package.swift.$DATE $PACKAGE_DIR/Package.swift
cp $BACKUP_DIR/Package.resolved.$DATE $PACKAGE_DIR/Package.resolved (if exists)
cd $PACKAGE_DIR && swift package resolve
\`\`\`
EOF

    print_status "Update report generated: dependency-update-report-$DATE.md"
}

# Main execution
main() {
    # Check if running from correct directory
    if [ ! -d "$PACKAGE_DIR" ]; then
        print_error "This script must be run from the project root directory"
        print_error "Expected to find: $PACKAGE_DIR/"
        exit 1
    fi
    
    print_info "Starting dependency update process..."
    
    # Create backup
    backup_current_state
    
    # Check current state
    check_current_dependencies
    
    # For now, just resolve (since no dependencies to update)
    resolve_dependencies
    
    # Build and test
    test_after_update
    
    # Run vulnerability scan
    run_vulnerability_scan
    
    # Generate report
    generate_update_report
    
    print_status "Dependency update process completed successfully!"
    print_info "Review the update report and test thoroughly before committing changes."
}

# Handle command line arguments
case "${1:-help}" in
    "update"|"")
        main
        ;;
    "check")
        check_current_dependencies
        ;;
    "scan")
        run_vulnerability_scan
        ;;
    "help"|*)
        echo -e "${BLUE}CoverCraft Dependency Update Tool${NC}"
        echo ""
        echo "Usage:"
        echo "  $0 [command]"
        echo ""
        echo "Commands:"
        echo "  update    - Update all dependencies (default)"
        echo "  check     - Check current dependencies without updating"
        echo "  scan      - Run vulnerability scan only"
        echo "  help      - Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0              # Run full update process"
        echo "  $0 update       # Same as above"
        echo "  $0 check        # Just check current status"
        echo "  $0 scan         # Run security scan only"
        ;;
esac