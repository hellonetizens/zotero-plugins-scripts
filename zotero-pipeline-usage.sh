#!/bin/bash

# Zotero Plugin Development Pipeline - Complete Usage Guide
# This script demonstrates how to use the created pipeline

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
REPO_URL="https://github.com/hellonetizens/zotero-plugins-scripts.git"
WORK_DIR="${HOME}/zotero-plugins"
GITHUB_TOKEN="${1:-}"

# Functions
print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo -e "${YELLOW}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Main execution
main() {
    print_header "Zotero Plugin Development Pipeline - Usage Guide"
    
    # Step 1: Clone repository
    print_section "Step 1: Clone Scripts Repository"
    if [ ! -d "$WORK_DIR/zotero-plugins-scripts" ]; then
        mkdir -p "$WORK_DIR"
        cd "$WORK_DIR"
        git clone "$REPO_URL"
        print_success "Repository cloned"
    else
        print_success "Repository already exists"
    fi
    
    cd "$WORK_DIR/zotero-plugins-scripts"
    
    # Step 2: Show available scripts
    print_section "Step 2: Available Scripts"
    echo ""
    echo "📦 BUILD SCRIPTS:"
    echo "  • build-xpi.py (RECOMMENDED)"
    echo "    - Builds XPI files for all plugins"
    echo "    - Usage: python3 build-xpi.py"
    echo "    - Time: ~5 seconds"
    echo ""
    echo "  • build-all-plugins.sh"
    echo "    - Comprehensive build with testing"
    echo "    - Usage: bash build-all-plugins.sh"
    echo "    - Time: ~30 seconds"
    echo ""
    
    echo "🔧 OPTIMIZATION & DEBUG:"
    echo "  • optimize-plugins.sh"
    echo "    - Code optimization and quality checks"
    echo "    - Usage: bash optimize-plugins.sh"
    echo ""
    echo "  • mcp-debug.sh"
    echo "    - MCP-based debugging and analysis"
    echo "    - Usage: bash mcp-debug.sh"
    echo ""
    
    echo "📤 RELEASE SCRIPTS:"
    echo "  • release-plugins.sh"
    echo "    - Release management with changelog"
    echo "    - Usage: bash release-plugins.sh [TOKEN]"
    echo ""
    echo "  • publish-releases.py"
    echo "    - GitHub release publisher"
    echo "    - Usage: python3 publish-releases.py [TOKEN]"
    echo ""
    
    echo "🎯 MASTER ORCHESTRATOR:"
    echo "  • orchestrate.sh"
    echo "    - Coordinates all pipelines"
    echo "    - Usage: bash orchestrate.sh [OPTIONS]"
    echo "    - Options: --build, --optimize, --debug, --release, --all"
    echo ""
    
    # Step 3: Build XPI files
    print_section "Step 3: Build XPI Files (RECOMMENDED)"
    echo ""
    echo "Running: python3 build-xpi.py"
    echo ""
    
    if python3 build-xpi.py; then
        print_success "XPI files built successfully"
        echo ""
        echo "Generated files:"
        ls -lh releases/*.xpi 2>/dev/null | awk '{print "  • " $9 " (" $5 ")"}'
    else
        print_error "Build failed"
        return 1
    fi
    
    # Step 4: Show documentation
    print_section "Step 4: Documentation"
    echo ""
    echo "📚 Available Documentation:"
    echo "  • README.md - Quick start guide"
    echo "  • PIPELINE_GUIDE.md - Complete documentation"
    echo "  • EXECUTION_SUMMARY.md - Execution results"
    echo ""
    
    # Step 5: Show next steps
    print_section "Step 5: Next Steps"
    echo ""
    echo "✅ XPI files are ready for installation in Zotero"
    echo ""
    echo "Optional: Run complete pipeline"
    echo "  bash orchestrate.sh --all"
    echo ""
    echo "Optional: Optimize code"
    echo "  bash optimize-plugins.sh"
    echo ""
    echo "Optional: Debug with MCP"
    echo "  bash mcp-debug.sh"
    echo ""
    
    if [ -n "$GITHUB_TOKEN" ]; then
        print_section "Step 6: Publish to GitHub"
        echo ""
        echo "Running: bash release-plugins.sh $GITHUB_TOKEN"
        echo ""
        
        if bash release-plugins.sh "$GITHUB_TOKEN"; then
            print_success "Published to GitHub"
        else
            print_error "GitHub publish failed"
        fi
    else
        echo "Optional: Publish to GitHub"
        echo "  bash release-plugins.sh YOUR_GITHUB_TOKEN"
        echo ""
    fi
    
    # Summary
    print_header "Pipeline Usage Complete"
    
    echo "📊 Summary:"
    echo "  • XPI files: $(ls -1 releases/*.xpi 2>/dev/null | wc -l) files"
    echo "  • Location: $WORK_DIR/zotero-plugins-scripts/releases/"
    echo "  • Repository: $REPO_URL"
    echo ""
    
    echo "🚀 Quick Commands:"
    echo "  cd $WORK_DIR/zotero-plugins-scripts"
    echo "  python3 build-xpi.py              # Build XPI files"
    echo "  bash orchestrate.sh --all         # Run complete pipeline"
    echo "  bash optimize-plugins.sh          # Optimize code"
    echo "  bash mcp-debug.sh                 # Debug with MCP"
    echo ""
    
    print_success "Pipeline ready to use!"
}

# Run main
main "$@"
