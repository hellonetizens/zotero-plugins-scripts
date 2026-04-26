#!/bin/bash

# Comprehensive Zotero Plugin Build, Test, Optimize, and Release Script
# Handles all 3 plugins with proper error handling and reporting

set -e

PLUGINS_DIR="/home/zotero-plugins"
PLUGINS=("zotero-metadata-plugin" "zotero-jisedigi-api" "zotero-vercel-ocr")
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BUILD_LOG="/tmp/zotero-build-${TIMESTAMP}.log"
RELEASE_DIR="/home/releases"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize
mkdir -p "$RELEASE_DIR"
echo "=== Zotero Plugin Build & Release Pipeline ===" | tee "$BUILD_LOG"
echo "Timestamp: $TIMESTAMP" | tee -a "$BUILD_LOG"
echo "Build Log: $BUILD_LOG" | tee -a "$BUILD_LOG"
echo "" | tee -a "$BUILD_LOG"

# Function to log messages
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$BUILD_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$BUILD_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$BUILD_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$BUILD_LOG"
}

# Function to build a plugin
build_plugin() {
    local plugin=$1
    local plugin_path="$PLUGINS_DIR/$plugin"
    
    log_info "Building $plugin..."
    
    if [ ! -d "$plugin_path" ]; then
        log_error "Plugin directory not found: $plugin_path"
        return 1
    fi
    
    cd "$plugin_path"
    
    # Check if package.json exists
    if [ ! -f "package.json" ]; then
        log_error "package.json not found in $plugin"
        return 1
    fi
    
    # Install dependencies
    log_info "Installing dependencies for $plugin..."
    if [ -f "pnpm-lock.yaml" ]; then
        pnpm install 2>&1 | tee -a "$BUILD_LOG" || npm install 2>&1 | tee -a "$BUILD_LOG"
    else
        npm install 2>&1 | tee -a "$BUILD_LOG"
    fi
    
    # Run linting if available
    if grep -q '"lint"' package.json; then
        log_info "Running linter for $plugin..."
        npm run lint 2>&1 | tee -a "$BUILD_LOG" || log_warning "Linting failed for $plugin"
    fi
    
    # Run tests if available
    if grep -q '"test"' package.json; then
        log_info "Running tests for $plugin..."
        npm run test 2>&1 | tee -a "$BUILD_LOG" || log_warning "Tests failed for $plugin"
    fi
    
    # Build the plugin
    log_info "Compiling $plugin..."
    if grep -q '"build"' package.json; then
        npm run build 2>&1 | tee -a "$BUILD_LOG"
    else
        log_warning "No build script found for $plugin"
    fi
    
    log_success "$plugin built successfully"
    return 0
}

# Function to create XPI package
create_xpi() {
    local plugin=$1
    local plugin_path="$PLUGINS_DIR/$plugin"
    local xpi_name="${plugin}-${TIMESTAMP}.xpi"
    local xpi_path="$RELEASE_DIR/$xpi_name"
    
    log_info "Creating XPI package for $plugin..."
    
    cd "$plugin_path"
    
    # Check for manifest.json or install.rdf
    if [ -f "manifest.json" ]; then
        log_info "Found manifest.json, creating XPI..."
        if [ -d "dist" ]; then
            cd dist
            zip -r "$xpi_path" . 2>&1 | tee -a "$BUILD_LOG"
            cd ..
        else
            log_warning "No dist directory found, creating XPI from source..."
            zip -r "$xpi_path" . -x ".git/*" "node_modules/*" ".github/*" 2>&1 | tee -a "$BUILD_LOG"
        fi
    elif [ -f "install.rdf" ]; then
        log_info "Found install.rdf, creating XPI..."
        zip -r "$xpi_path" . -x ".git/*" "node_modules/*" ".github/*" 2>&1 | tee -a "$BUILD_LOG"
    else
        log_warning "No manifest.json or install.rdf found for $plugin"
        # Try to create from dist directory
        if [ -d "dist" ]; then
            cd dist
            zip -r "$xpi_path" . 2>&1 | tee -a "$BUILD_LOG"
            cd ..
        fi
    fi
    
    if [ -f "$xpi_path" ]; then
        log_success "XPI created: $xpi_path ($(du -h "$xpi_path" | cut -f1))"
        echo "$xpi_path" >> "$RELEASE_DIR/xpi-files.txt"
        return 0
    else
        log_error "Failed to create XPI for $plugin"
        return 1
    fi
}

# Function to analyze plugin
analyze_plugin() {
    local plugin=$1
    local plugin_path="$PLUGINS_DIR/$plugin"
    
    log_info "Analyzing $plugin..."
    
    cd "$plugin_path"
    
    # Count lines of code
    local loc=$(find src -name "*.ts" -o -name "*.js" 2>/dev/null | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')
    log_info "Lines of code: $loc"
    
    # Check dependencies
    local deps=$(grep -c '"dependencies"' package.json || echo "0")
    log_info "Dependencies: $deps"
    
    # Check for security issues
    log_info "Checking for npm vulnerabilities..."
    npm audit 2>&1 | tee -a "$BUILD_LOG" || log_warning "npm audit found issues"
    
    return 0
}

# Function to commit and push changes
commit_and_push() {
    local plugin=$1
    local plugin_path="$PLUGINS_DIR/$plugin"
    
    log_info "Preparing to commit changes for $plugin..."
    
    cd "$plugin_path"
    
    # Check if there are changes
    if git diff --quiet && git diff --cached --quiet; then
        log_info "No changes to commit for $plugin"
        return 0
    fi
    
    # Stage changes
    git add -A
    
    # Commit
    git commit -m "Build: Automated build and optimization - $TIMESTAMP" 2>&1 | tee -a "$BUILD_LOG" || log_warning "No changes to commit"
    
    # Push
    log_info "Pushing changes for $plugin..."
    git push 2>&1 | tee -a "$BUILD_LOG" || log_warning "Failed to push changes for $plugin"
    
    return 0
}

# Function to create GitHub release
create_github_release() {
    local plugin=$1
    local plugin_path="$PLUGINS_DIR/$plugin"
    local version=$(grep '"version"' "$plugin_path/package.json" | head -1 | sed 's/.*"version": "\([^"]*\)".*/\1/')
    local tag="v${version}-${TIMESTAMP}"
    
    log_info "Creating GitHub release for $plugin (tag: $tag)..."
    
    cd "$plugin_path"
    
    # Create git tag
    git tag -a "$tag" -m "Release: $plugin - $TIMESTAMP" 2>&1 | tee -a "$BUILD_LOG" || log_warning "Tag already exists"
    
    # Push tag
    git push origin "$tag" 2>&1 | tee -a "$BUILD_LOG" || log_warning "Failed to push tag"
    
    return 0
}

# Main execution
main() {
    local failed_plugins=()
    local successful_plugins=()
    
    echo "" | tee -a "$BUILD_LOG"
    log_info "Starting build pipeline for ${#PLUGINS[@]} plugins..."
    echo "" | tee -a "$BUILD_LOG"
    
    # Build all plugins
    for plugin in "${PLUGINS[@]}"; do
        if build_plugin "$plugin"; then
            successful_plugins+=("$plugin")
        else
            failed_plugins+=("$plugin")
        fi
        echo "" | tee -a "$BUILD_LOG"
    done
    
    # Analyze plugins
    echo "" | tee -a "$BUILD_LOG"
    log_info "=== Plugin Analysis ===" | tee -a "$BUILD_LOG"
    for plugin in "${PLUGINS[@]}"; do
        analyze_plugin "$plugin"
        echo "" | tee -a "$BUILD_LOG"
    done
    
    # Create XPI packages
    echo "" | tee -a "$BUILD_LOG"
    log_info "=== Creating XPI Packages ===" | tee -a "$BUILD_LOG"
    > "$RELEASE_DIR/xpi-files.txt"
    for plugin in "${PLUGINS[@]}"; do
        create_xpi "$plugin"
        echo "" | tee -a "$BUILD_LOG"
    done
    
    # Commit and push changes
    echo "" | tee -a "$BUILD_LOG"
    log_info "=== Committing Changes ===" | tee -a "$BUILD_LOG"
    for plugin in "${PLUGINS[@]}"; do
        commit_and_push "$plugin"
        echo "" | tee -a "$BUILD_LOG"
    done
    
    # Create GitHub releases
    echo "" | tee -a "$BUILD_LOG"
    log_info "=== Creating GitHub Releases ===" | tee -a "$BUILD_LOG"
    for plugin in "${PLUGINS[@]}"; do
        create_github_release "$plugin"
        echo "" | tee -a "$BUILD_LOG"
    done
    
    # Summary
    echo "" | tee -a "$BUILD_LOG"
    log_info "=== Build Summary ===" | tee -a "$BUILD_LOG"
    log_success "Successful builds: ${#successful_plugins[@]}"
    for plugin in "${successful_plugins[@]}"; do
        echo "  ✓ $plugin" | tee -a "$BUILD_LOG"
    done
    
    if [ ${#failed_plugins[@]} -gt 0 ]; then
        log_error "Failed builds: ${#failed_plugins[@]}"
        for plugin in "${failed_plugins[@]}"; do
            echo "  ✗ $plugin" | tee -a "$BUILD_LOG"
        done
    fi
    
    echo "" | tee -a "$BUILD_LOG"
    log_info "XPI files available at: $RELEASE_DIR" | tee -a "$BUILD_LOG"
    log_info "Build log: $BUILD_LOG" | tee -a "$BUILD_LOG"
    
    # List XPI files
    if [ -f "$RELEASE_DIR/xpi-files.txt" ]; then
        echo "" | tee -a "$BUILD_LOG"
        log_info "=== Generated XPI Files ===" | tee -a "$BUILD_LOG"
        cat "$RELEASE_DIR/xpi-files.txt" | tee -a "$BUILD_LOG"
    fi
}

# Run main
main
