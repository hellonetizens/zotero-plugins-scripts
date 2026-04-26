#!/bin/bash

# Zotero Plugin Optimization Script
# Optimizes code, dependencies, and build output

set -e

PLUGINS_DIR="/home/zotero-plugins"
PLUGINS=("zotero-metadata-plugin" "zotero-jisedigi-api" "zotero-vercel-ocr")
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OPT_LOG="/tmp/zotero-optimize-${TIMESTAMP}.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$OPT_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$OPT_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$OPT_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$OPT_LOG"
}

# Optimize dependencies
optimize_dependencies() {
    local plugin=$1
    local plugin_path="$PLUGINS_DIR/$plugin"
    
    log_info "Optimizing dependencies for $plugin..."
    
    cd "$plugin_path"
    
    # Audit and fix vulnerabilities
    log_info "Running npm audit fix..."
    npm audit fix 2>&1 | tee -a "$OPT_LOG" || log_warning "npm audit fix had issues"
    
    # Update dependencies
    log_info "Checking for outdated dependencies..."
    npm outdated 2>&1 | tee -a "$OPT_LOG" || true
    
    # Remove unused dependencies
    log_info "Checking for unused dependencies..."
    if command -v depcheck &> /dev/null; then
        npx depcheck 2>&1 | tee -a "$OPT_LOG" || log_warning "depcheck found unused dependencies"
    else
        log_warning "depcheck not installed, skipping unused dependency check"
    fi
    
    log_success "Dependency optimization complete for $plugin"
}

# Optimize code
optimize_code() {
    local plugin=$1
    local plugin_path="$PLUGINS_DIR/$plugin"
    
    log_info "Optimizing code for $plugin..."
    
    cd "$plugin_path"
    
    # Run prettier if available
    if grep -q '"prettier"' package.json || [ -f ".prettierrc" ]; then
        log_info "Running Prettier..."
        npx prettier --write "src/**/*.{ts,js,json}" 2>&1 | tee -a "$OPT_LOG" || log_warning "Prettier had issues"
    fi
    
    # Run ESLint with fix
    if grep -q '"lint"' package.json; then
        log_info "Running ESLint with auto-fix..."
        npx eslint --fix "src/**/*.{ts,js}" 2>&1 | tee -a "$OPT_LOG" || log_warning "ESLint had issues"
    fi
    
    # Analyze bundle size
    if [ -d "dist" ]; then
        log_info "Analyzing bundle size..."
        local total_size=$(du -sh dist | cut -f1)
        log_info "Total dist size: $total_size"
        
        # Find large files
        find dist -type f -size +100k 2>/dev/null | while read file; do
            local size=$(du -h "$file" | cut -f1)
            log_warning "Large file: $file ($size)"
        done
    fi
    
    log_success "Code optimization complete for $plugin"
}

# Optimize build configuration
optimize_build_config() {
    local plugin=$1
    local plugin_path="$PLUGINS_DIR/$plugin"
    
    log_info "Optimizing build configuration for $plugin..."
    
    cd "$plugin_path"
    
    # Check TypeScript configuration
    if [ -f "tsconfig.json" ]; then
        log_info "Checking TypeScript configuration..."
        
        # Verify strict mode
        if grep -q '"strict": true' tsconfig.json; then
            log_success "Strict mode enabled"
        else
            log_warning "Strict mode not enabled in tsconfig.json"
        fi
        
        # Check for source maps
        if grep -q '"sourceMap": true' tsconfig.json; then
            log_info "Source maps enabled"
        fi
    fi
    
    # Check webpack/build configuration
    if [ -f "webpack.config.js" ] || [ -f "vite.config.ts" ] || [ -f "rollup.config.js" ]; then
        log_info "Build configuration found"
    fi
    
    log_success "Build configuration optimization complete for $plugin"
}

# Generate optimization report
generate_optimization_report() {
    local report_file="/home/releases/optimization-report-${TIMESTAMP}.md"
    
    log_info "Generating optimization report..."
    
    cat > "$report_file" <<EOF
# Zotero Plugin Optimization Report
Generated: $TIMESTAMP

## Summary
This report details the optimization performed on all Zotero plugins.

## Plugins Optimized
EOF
    
    for plugin in "${PLUGINS[@]}"; do
        plugin_path="$PLUGINS_DIR/$plugin"
        if [ -d "$plugin_path" ]; then
            cd "$plugin_path"
            
            version=$(grep '"version"' package.json | head -1 | sed 's/.*"version": "\([^"]*\)".*/\1/')
            
            echo "" >> "$report_file"
            echo "### $plugin (v$version)" >> "$report_file"
            
            # Dependency count
            dep_count=$(grep -c '"dependencies"' package.json || echo "0")
            echo "- Dependencies: $dep_count" >> "$report_file"
            
            # Build size
            if [ -d "dist" ]; then
                build_size=$(du -sh dist | cut -f1)
                echo "- Build Size: $build_size" >> "$report_file"
            fi
            
            # Code metrics
            ts_lines=$(find src -name "*.ts" 2>/dev/null | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
            echo "- TypeScript Lines: $ts_lines" >> "$report_file"
        fi
    done
    
    echo "" >> "$report_file"
    echo "## Optimizations Applied" >> "$report_file"
    echo "- Dependency audit and fixes" >> "$report_file"
    echo "- Code formatting with Prettier" >> "$report_file"
    echo "- Linting with ESLint" >> "$report_file"
    echo "- Bundle size analysis" >> "$report_file"
    echo "- Build configuration review" >> "$report_file"
    
    log_success "Optimization report generated: $report_file"
}

# Main execution
main() {
    echo "=== Zotero Plugin Optimization Pipeline ===" | tee "$OPT_LOG"
    echo "Timestamp: $TIMESTAMP" | tee -a "$OPT_LOG"
    echo "" | tee -a "$OPT_LOG"
    
    for plugin in "${PLUGINS[@]}"; do
        log_info "Processing $plugin..." | tee -a "$OPT_LOG"
        
        optimize_dependencies "$plugin"
        echo "" | tee -a "$OPT_LOG"
        
        optimize_code "$plugin"
        echo "" | tee -a "$OPT_LOG"
        
        optimize_build_config "$plugin"
        echo "" | tee -a "$OPT_LOG"
    done
    
    # Generate report
    generate_optimization_report
    
    log_success "Optimization pipeline complete"
    log_info "Log file: $OPT_LOG"
}

# Run main
main
