#!/bin/bash

# MCP Server Integration Script for Zotero Plugin Development
# Integrates mcp-server-zotero-dev for debugging and testing

set -e

PLUGINS_DIR="/home/zotero-plugins"
MCP_DIR="$PLUGINS_DIR/mcp-server-zotero-dev"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MCP_LOG="/tmp/mcp-server-${TIMESTAMP}.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$MCP_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$MCP_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$MCP_LOG"
}

# Setup MCP Server
setup_mcp_server() {
    log_info "Setting up MCP Server for Zotero Development..."
    
    if [ ! -d "$MCP_DIR" ]; then
        log_error "MCP directory not found: $MCP_DIR"
        return 1
    fi
    
    cd "$MCP_DIR"
    
    # Install dependencies
    log_info "Installing MCP server dependencies..."
    npm install 2>&1 | tee -a "$MCP_LOG"
    
    # Build MCP server
    if grep -q '"build"' package.json; then
        log_info "Building MCP server..."
        npm run build 2>&1 | tee -a "$MCP_LOG"
    fi
    
    log_success "MCP server setup complete"
    return 0
}

# Start MCP Server
start_mcp_server() {
    log_info "Starting MCP server..."
    
    cd "$MCP_DIR"
    
    if grep -q '"start"' package.json; then
        npm start > "$MCP_LOG" 2>&1 &
        MCP_PID=$!
        log_success "MCP server started with PID: $MCP_PID"
        echo "$MCP_PID" > /tmp/mcp-server.pid
        sleep 2
        return 0
    else
        log_error "No start script found in MCP package.json"
        return 1
    fi
}

# Test MCP Server
test_mcp_server() {
    log_info "Testing MCP server connection..."
    
    # Check if server is running
    if [ -f /tmp/mcp-server.pid ]; then
        MCP_PID=$(cat /tmp/mcp-server.pid)
        if ps -p "$MCP_PID" > /dev/null; then
            log_success "MCP server is running (PID: $MCP_PID)"
            return 0
        fi
    fi
    
    log_error "MCP server is not running"
    return 1
}

# Debug plugin with MCP
debug_plugin_with_mcp() {
    local plugin=$1
    local plugin_path="$PLUGINS_DIR/$plugin"
    
    log_info "Debugging $plugin with MCP server..."
    
    if [ ! -d "$plugin_path" ]; then
        log_error "Plugin not found: $plugin"
        return 1
    fi
    
    cd "$plugin_path"
    
    # Create debug configuration
    cat > .mcp-debug.json <<EOF
{
  "plugin": "$plugin",
  "timestamp": "$TIMESTAMP",
  "mcp_server": "http://localhost:3000",
  "debug_level": "verbose",
  "features": {
    "code_analysis": true,
    "dependency_check": true,
    "type_checking": true,
    "performance_profiling": true
  }
}
EOF
    
    log_info "Debug configuration created: .mcp-debug.json"
    
    # Run type checking
    if [ -f "tsconfig.json" ]; then
        log_info "Running TypeScript type checking..."
        npx tsc --noEmit 2>&1 | tee -a "$MCP_LOG" || log_error "Type checking failed"
    fi
    
    # Run ESLint if available
    if grep -q '"lint"' package.json; then
        log_info "Running ESLint..."
        npm run lint 2>&1 | tee -a "$MCP_LOG" || log_error "Linting failed"
    fi
    
    # Analyze code complexity
    log_info "Analyzing code complexity..."
    find src -name "*.ts" -o -name "*.js" 2>/dev/null | while read file; do
        lines=$(wc -l < "$file")
        if [ "$lines" -gt 200 ]; then
            log_error "File $file has high complexity ($lines lines)"
        fi
    done
    
    log_success "Debug analysis complete for $plugin"
    return 0
}

# Generate debug report
generate_debug_report() {
    local report_file="/home/releases/debug-report-${TIMESTAMP}.md"
    
    log_info "Generating debug report..."
    
    cat > "$report_file" <<EOF
# Zotero Plugin Debug Report
Generated: $TIMESTAMP

## Environment
- Node Version: $(node --version)
- NPM Version: $(npm --version)
- Platform: $(uname -s)

## MCP Server Status
EOF
    
    if [ -f /tmp/mcp-server.pid ]; then
        MCP_PID=$(cat /tmp/mcp-server.pid)
        if ps -p "$MCP_PID" > /dev/null; then
            echo "- Status: Running (PID: $MCP_PID)" >> "$report_file"
        else
            echo "- Status: Not Running" >> "$report_file"
        fi
    fi
    
    echo "" >> "$report_file"
    echo "## Plugin Analysis" >> "$report_file"
    
    for plugin in zotero-metadata-plugin zotero-jisedigi-api zotero-vercel-ocr; do
        plugin_path="$PLUGINS_DIR/$plugin"
        if [ -d "$plugin_path" ]; then
            echo "" >> "$report_file"
            echo "### $plugin" >> "$report_file"
            
            cd "$plugin_path"
            
            # Get version
            version=$(grep '"version"' package.json | head -1 | sed 's/.*"version": "\([^"]*\)".*/\1/')
            echo "- Version: $version" >> "$report_file"
            
            # Count files
            ts_files=$(find src -name "*.ts" 2>/dev/null | wc -l)
            js_files=$(find src -name "*.js" 2>/dev/null | wc -l)
            echo "- TypeScript Files: $ts_files" >> "$report_file"
            echo "- JavaScript Files: $js_files" >> "$report_file"
            
            # Check build status
            if [ -d "dist" ]; then
                echo "- Build Status: ✓ Built" >> "$report_file"
            else
                echo "- Build Status: ✗ Not Built" >> "$report_file"
            fi
        fi
    done
    
    log_success "Debug report generated: $report_file"
    return 0
}

# Stop MCP Server
stop_mcp_server() {
    log_info "Stopping MCP server..."
    
    if [ -f /tmp/mcp-server.pid ]; then
        MCP_PID=$(cat /tmp/mcp-server.pid)
        if ps -p "$MCP_PID" > /dev/null; then
            kill "$MCP_PID"
            log_success "MCP server stopped"
            rm /tmp/mcp-server.pid
        fi
    fi
}

# Main execution
main() {
    echo "=== Zotero Plugin MCP Debug Pipeline ===" | tee "$MCP_LOG"
    echo "Timestamp: $TIMESTAMP" | tee -a "$MCP_LOG"
    echo "" | tee -a "$MCP_LOG"
    
    # Setup and start MCP server
    if setup_mcp_server; then
        if start_mcp_server; then
            if test_mcp_server; then
                # Debug each plugin
                for plugin in zotero-metadata-plugin zotero-jisedigi-api zotero-vercel-ocr; do
                    debug_plugin_with_mcp "$plugin"
                    echo "" | tee -a "$MCP_LOG"
                done
                
                # Generate report
                generate_debug_report
            fi
        fi
    fi
    
    # Cleanup
    stop_mcp_server
    
    log_info "MCP debug pipeline complete"
    log_info "Log file: $MCP_LOG"
}

# Trap to ensure cleanup
trap stop_mcp_server EXIT

# Run main
main
