#!/bin/bash

################################################################################
# Zotero Plugins Pipeline - Automated Execution Script
# 
# This script automates the complete pipeline for building, optimizing, and
# releasing Zotero plugins.
#
# Usage:
#   ./run-pipeline.sh [OPTIONS]
#
# Options:
#   -b, --build         Build plugins only
#   -o, --optimize      Optimize code only
#   -r, --release       Release only
#   -a, --all           Run all stages (default)
#   -t, --token TOKEN   GitHub API token for releases
#   -h, --help          Show this help message
#
# Examples:
#   ./run-pipeline.sh --all --token ghp_xxxxx
#   ./run-pipeline.sh --build --optimize
#   ./run-pipeline.sh --release --token ghp_xxxxx
#
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASES_DIR="/home/releases"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/tmp/zotero-pipeline-${TIMESTAMP}.log"

# Defaults
RUN_BUILD=false
RUN_OPTIMIZE=false
RUN_RELEASE=false
GITHUB_TOKEN=""

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_section() {
    echo "" | tee -a "$LOG_FILE"
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}" | tee -a "$LOG_FILE"
    echo -e "${CYAN}║ $1${NC}" | tee -a "$LOG_FILE"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
    -b, --build         Build plugins only
    -o, --optimize      Optimize code only
    -r, --release       Release only
    -a, --all           Run all stages (default)
    -t, --token TOKEN   GitHub API token for releases
    -h, --help          Show this help message

Examples:
    $0 --all --token ghp_xxxxx
    $0 --build --optimize
    $0 --release --token ghp_xxxxx

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--build)
            RUN_BUILD=true
            shift
            ;;
        -o|--optimize)
            RUN_OPTIMIZE=true
            shift
            ;;
        -r|--release)
            RUN_RELEASE=true
            shift
            ;;
        -a|--all)
            RUN_BUILD=true
            RUN_OPTIMIZE=true
            RUN_RELEASE=true
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

# Default to all if none specified
if [ "$RUN_BUILD" = false ] && [ "$RUN_OPTIMIZE" = false ] && [ "$RUN_RELEASE" = false ]; then
    RUN_BUILD=true
    RUN_OPTIMIZE=true
    RUN_RELEASE=true
fi

# Main execution
main() {
    log_section "Zotero Plugins Pipeline - Automated Execution"
    
    log_info "Timestamp: $TIMESTAMP"
    log_info "Log file: $LOG_FILE"
    log_info "Script directory: $SCRIPT_DIR"
    log_info "Releases directory: $RELEASES_DIR"
    
    # Verify prerequisites
    log_section "Verifying Prerequisites"
    
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed"
        exit 1
    fi
    log_success "Node.js: $(node --version)"
    
    if ! command -v npm &> /dev/null; then
        log_error "npm is not installed"
        exit 1
    fi
    log_success "npm: $(npm --version)"
    
    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 is not installed"
        exit 1
    fi
    log_success "Python: $(python3 --version)"
    
    if ! command -v git &> /dev/null; then
        log_error "Git is not installed"
        exit 1
    fi
    log_success "Git: $(git --version)"
    
    # Create releases directory
    mkdir -p "$RELEASES_DIR"
    
    # Run build stage
    if [ "$RUN_BUILD" = true ]; then
        log_section "Build Stage"
        
        if [ ! -f "$SCRIPT_DIR/build-xpi.py" ]; then
            log_error "build-xpi.py not found"
            exit 1
        fi
        
        cd "$SCRIPT_DIR"
        if python3 build-xpi.py 2>&1 | tee -a "$LOG_FILE"; then
            log_success "Build stage completed successfully"
        else
            log_error "Build stage failed"
            exit 1
        fi
    fi
    
    # Run optimization stage
    if [ "$RUN_OPTIMIZE" = true ]; then
        log_section "Optimization Stage"
        
        if [ ! -f "$SCRIPT_DIR/optimize-plugins.sh" ]; then
            log_error "optimize-plugins.sh not found"
            exit 1
        fi
        
        cd "$SCRIPT_DIR"
        if bash optimize-plugins.sh 2>&1 | tee -a "$LOG_FILE"; then
            log_success "Optimization stage completed successfully"
        else
            log_warning "Optimization stage completed with warnings"
        fi
    fi
    
    # Run release stage
    if [ "$RUN_RELEASE" = true ]; then
        log_section "Release Stage"
        
        if [ ! -f "$SCRIPT_DIR/publish-releases.py" ]; then
            log_error "publish-releases.py not found"
            exit 1
        fi
        
        cd "$SCRIPT_DIR"
        if [ -n "$GITHUB_TOKEN" ]; then
            if python3 publish-releases.py "$GITHUB_TOKEN" 2>&1 | tee -a "$LOG_FILE"; then
                log_success "Release stage completed successfully"
            else
                log_warning "Release stage completed with warnings"
            fi
        else
            if python3 publish-releases.py 2>&1 | tee -a "$LOG_FILE"; then
                log_success "Release stage completed successfully"
            else
                log_warning "Release stage completed with warnings"
            fi
        fi
    fi
    
    # Final summary
    log_section "Pipeline Execution Complete"
    
    log_success "All requested stages completed"
    log_info "Log file: $LOG_FILE"
    log_info "Releases directory: $RELEASES_DIR"
    
    # List artifacts
    if [ -d "$RELEASES_DIR" ]; then
        log_info "Generated artifacts:"
        ls -lh "$RELEASES_DIR" | tail -n +2 | awk '{print "  - " $9 " (" $5 ")"}' | tee -a "$LOG_FILE"
    fi
    
    echo ""
    log_success "Pipeline execution finished successfully!"
}

# Run main
main
