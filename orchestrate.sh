#!/bin/bash

# Master Orchestration Script for Zotero Plugin Development Pipeline
# Coordinates all build, test, optimize, debug, and release operations

set -e

PLUGINS_DIR="/home/zotero-plugins"
RELEASE_DIR="/home/releases"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MASTER_LOG="/tmp/zotero-master-${TIMESTAMP}.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Initialize
mkdir -p "$RELEASE_DIR"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$MASTER_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$MASTER_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$MASTER_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$MASTER_LOG"
}

log_section() {
    echo "" | tee -a "$MASTER_LOG"
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}" | tee -a "$MASTER_LOG"
    echo -e "${CYAN}║ $1${NC}" | tee -a "$MASTER_LOG"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}" | tee -a "$MASTER_LOG"
    echo "" | tee -a "$MASTER_LOG"
}

# Display usage
usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
    -b, --build         Run build pipeline only
    -o, --optimize      Run optimization pipeline only
    -d, --debug         Run MCP debug pipeline only
    -r, --release       Run release pipeline only
    -a, --all           Run all pipelines (default)
    -t, --token TOKEN   GitHub API token for releases
    -h, --help          Display this help message

Examples:
    $0 --all                          # Run complete pipeline
    $0 --build --optimize --release   # Build, optimize, and release
    $0 --release --token ghp_xxxxx    # Release with GitHub API token

EOF
    exit 0
}

# Parse arguments
PIPELINE_BUILD=false
PIPELINE_OPTIMIZE=false
PIPELINE_DEBUG=false
PIPELINE_RELEASE=false
GITHUB_TOKEN=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--build)
            PIPELINE_BUILD=true
            shift
            ;;
        -o|--optimize)
            PIPELINE_OPTIMIZE=true
            shift
            ;;
        -d|--debug)
            PIPELINE_DEBUG=true
            shift
            ;;
        -r|--release)
            PIPELINE_RELEASE=true
            shift
            ;;
        -a|--all)
            PIPELINE_BUILD=true
            PIPELINE_OPTIMIZE=true
            PIPELINE_DEBUG=true
            PIPELINE_RELEASE=true
            shift
            ;;
        -t|--token)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Default to all pipelines if none specified
if [ "$PIPELINE_BUILD" = false ] && [ "$PIPELINE_OPTIMIZE" = false ] && [ "$PIPELINE_DEBUG" = false ] && [ "$PIPELINE_RELEASE" = false ]; then
    PIPELINE_BUILD=true
    PIPELINE_OPTIMIZE=true
    PIPELINE_DEBUG=true
    PIPELINE_RELEASE=true
fi

# Check prerequisites
check_prerequisites() {
    log_section "Checking Prerequisites"
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed"
        return 1
    fi
    log_success "Node.js: $(node --version)"
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        log_error "npm is not installed"
        return 1
    fi
    log_success "npm: $(npm --version)"
    
    # Check git
    if ! command -v git &> /dev/null; then
        log_error "git is not installed"
        return 1
    fi
    log_success "git: $(git --version)"
    
    # Check zip
    if ! command -v zip &> /dev/null; then
        log_error "zip is not installed"
        return 1
    fi
    log_success "zip: $(zip --version | head -1)"
    
    return 0
}

# Run build pipeline
run_build_pipeline() {
    log_section "Build Pipeline"
    
    if [ ! -f "$PLUGINS_DIR/build-all-plugins.sh" ]; then
        log_error "Build script not found"
        return 1
    fi
    
    bash "$PLUGINS_DIR/build-all-plugins.sh" 2>&1 | tee -a "$MASTER_LOG"
    return $?
}

# Run optimization pipeline
run_optimize_pipeline() {
    log_section "Optimization Pipeline"
    
    if [ ! -f "$PLUGINS_DIR/optimize-plugins.sh" ]; then
        log_error "Optimization script not found"
        return 1
    fi
    
    bash "$PLUGINS_DIR/optimize-plugins.sh" 2>&1 | tee -a "$MASTER_LOG"
    return $?
}

# Run debug pipeline
run_debug_pipeline() {
    log_section "Debug Pipeline (MCP)"
    
    if [ ! -f "$PLUGINS_DIR/mcp-debug.sh" ]; then
        log_error "Debug script not found"
        return 1
    fi
    
    bash "$PLUGINS_DIR/mcp-debug.sh" 2>&1 | tee -a "$MASTER_LOG"
    return $?
}

# Run release pipeline
run_release_pipeline() {
    log_section "Release Pipeline"
    
    if [ ! -f "$PLUGINS_DIR/release-plugins.sh" ]; then
        log_error "Release script not found"
        return 1
    fi
    
    if [ -n "$GITHUB_TOKEN" ]; then
        bash "$PLUGINS_DIR/release-plugins.sh" "$GITHUB_TOKEN" 2>&1 | tee -a "$MASTER_LOG"
    else
        bash "$PLUGINS_DIR/release-plugins.sh" 2>&1 | tee -a "$MASTER_LOG"
    fi
    return $?
}

# Generate final report
generate_final_report() {
    log_section "Final Report"
    
    local report_file="$RELEASE_DIR/final-report-${TIMESTAMP}.md"
    
    cat > "$report_file" <<EOF
# Zotero Plugin Development Pipeline - Final Report
**Execution Date:** $(date +%Y-%m-%d\ %H:%M:%S)
**Timestamp:** $TIMESTAMP

## Pipeline Configuration
- Build Pipeline: $PIPELINE_BUILD
- Optimization Pipeline: $PIPELINE_OPTIMIZE
- Debug Pipeline: $PIPELINE_DEBUG
- Release Pipeline: $PIPELINE_RELEASE

## Environment
- Node Version: $(node --version)
- npm Version: $(npm --version)
- Git Version: $(git --version)
- Platform: $(uname -s)
- User: $(whoami)

## Execution Summary
EOF
    
    # Add pipeline results
    if [ "$PIPELINE_BUILD" = true ]; then
        echo "### Build Pipeline" >> "$report_file"
        echo "Status: Executed" >> "$report_file"
        echo "" >> "$report_file"
    fi
    
    if [ "$PIPELINE_OPTIMIZE" = true ]; then
        echo "### Optimization Pipeline" >> "$report_file"
        echo "Status: Executed" >> "$report_file"
        echo "" >> "$report_file"
    fi
    
    if [ "$PIPELINE_DEBUG" = true ]; then
        echo "### Debug Pipeline" >> "$report_file"
        echo "Status: Executed" >> "$report_file"
        echo "" >> "$report_file"
    fi
    
    if [ "$PIPELINE_RELEASE" = true ]; then
        echo "### Release Pipeline" >> "$report_file"
        echo "Status: Executed" >> "$report_file"
        echo "" >> "$report_file"
    fi
    
    # Add artifacts
    echo "## Generated Artifacts" >> "$report_file"
    echo "" >> "$report_file"
    
    if [ -d "$RELEASE_DIR" ]; then
        echo "### Release Directory Contents" >> "$report_file"
        ls -lh "$RELEASE_DIR" | tail -n +2 | awk '{print "- " $9 " (" $5 ")"}' >> "$report_file"
    fi
    
    echo "" >> "$report_file"
    echo "## Logs" >> "$report_file"
    echo "- Master Log: $MASTER_LOG" >> "$report_file"
    
    log_success "Final report generated: $report_file"
}

# Main execution
main() {
    echo "╔════════════════════════════════════════════════════════════╗" | tee "$MASTER_LOG"
    echo "║   Zotero Plugin Development Pipeline - Master Orchestrator  ║" | tee -a "$MASTER_LOG"
    echo "╚════════════════════════════════════════════════════════════╝" | tee -a "$MASTER_LOG"
    echo "" | tee -a "$MASTER_LOG"
    echo "Timestamp: $TIMESTAMP" | tee -a "$MASTER_LOG"
    echo "Master Log: $MASTER_LOG" | tee -a "$MASTER_LOG"
    echo "" | tee -a "$MASTER_LOG"
    
    # Check prerequisites
    if ! check_prerequisites; then
        log_error "Prerequisites check failed"
        exit 1
    fi
    
    # Run pipelines
    local failed_pipelines=()
    
    if [ "$PIPELINE_BUILD" = true ]; then
        if ! run_build_pipeline; then
            failed_pipelines+=("Build")
        fi
    fi
    
    if [ "$PIPELINE_OPTIMIZE" = true ]; then
        if ! run_optimize_pipeline; then
            failed_pipelines+=("Optimize")
        fi
    fi
    
    if [ "$PIPELINE_DEBUG" = true ]; then
        if ! run_debug_pipeline; then
            failed_pipelines+=("Debug")
        fi
    fi
    
    if [ "$PIPELINE_RELEASE" = true ]; then
        if ! run_release_pipeline; then
            failed_pipelines+=("Release")
        fi
    fi
    
    # Generate final report
    generate_final_report
    
    # Summary
    log_section "Execution Summary"
    
    if [ ${#failed_pipelines[@]} -eq 0 ]; then
        log_success "All pipelines completed successfully!"
    else
        log_warning "Some pipelines had issues:"
        for pipeline in "${failed_pipelines[@]}"; do
            echo "  - $pipeline" | tee -a "$MASTER_LOG"
        done
    fi
    
    echo "" | tee -a "$MASTER_LOG"
    log_info "Release directory: $RELEASE_DIR" | tee -a "$MASTER_LOG"
    log_info "Master log: $MASTER_LOG" | tee -a "$MASTER_LOG"
    
    # List release artifacts
    if [ -d "$RELEASE_DIR" ]; then
        echo "" | tee -a "$MASTER_LOG"
        log_section "Release Artifacts"
        ls -lh "$RELEASE_DIR" | tail -n +2 | tee -a "$MASTER_LOG"
    fi
}

# Run main
main
