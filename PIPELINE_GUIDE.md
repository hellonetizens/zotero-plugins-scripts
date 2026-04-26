# Zotero Plugin Development Pipeline - Complete Guide

## Overview

This comprehensive automation pipeline manages the complete lifecycle of three Zotero plugins:
1. **zotero-metadata-plugin** - TypeScript-based metadata retrieval plugin
2. **zotero-jisedigi-api** - WebExtension-based JPS API integration
3. **zotero-vercel-ocr** - WebExtension-based Vercel OCR integration

## Architecture

### Components

```
/home/zotero-plugins/
├── zotero-metadata-plugin/          # TypeScript plugin
├── zotero-jisedigi-api/             # WebExtension plugin
├── zotero-vercel-ocr/               # WebExtension plugin
├── zotero-plugin-template/          # Reference template
├── zotero-plugin-toolkit/           # Development toolkit
├── zotero-plugin-scaffold/          # Build scaffold
├── mcp-server-zotero-dev/           # MCP debugging server
├── build-all-plugins.sh             # Legacy build script
├── build-xpi.py                     # XPI builder (RECOMMENDED)
├── optimize-plugins.sh              # Code optimization
├── mcp-debug.sh                     # MCP debugging
├── release-plugins.sh               # Release management
├── publish-releases.py              # GitHub publishing
└── orchestrate.sh                   # Master orchestrator
```

## Quick Start

### 1. Build All Plugins and Create XPI Files

```bash
cd /home/zotero-plugins
python3 build-xpi.py
```

**Output:**
- XPI files in `/home/releases/`
- Release manifest: `release-manifest-*.json`
- XPI file list: `xpi-files.txt`

### 2. Optimize Code

```bash
bash optimize-plugins.sh
```

**Performs:**
- Dependency audit and fixes
- Code formatting (Prettier)
- Linting (ESLint)
- Bundle size analysis

### 3. Debug with MCP

```bash
bash mcp-debug.sh
```

**Provides:**
- Type checking
- Code complexity analysis
- Debug configuration
- Performance profiling

### 4. Publish Releases

```bash
# Without GitHub API
python3 publish-releases.py

# With GitHub API token
python3 publish-releases.py YOUR_GITHUB_TOKEN
```

**Actions:**
- Creates changelogs
- Commits changes
- Creates git tags
- Publishes to GitHub (with API token)

## Detailed Usage

### Master Orchestrator

Run the complete pipeline with options:

```bash
bash orchestrate.sh [OPTIONS]

Options:
  -b, --build         Build plugins only
  -o, --optimize      Optimize code only
  -d, --debug         Debug with MCP only
  -r, --release       Release only
  -a, --all           Run all pipelines (default)
  -t, --token TOKEN   GitHub API token
  -h, --help          Show help
```

**Examples:**

```bash
# Complete pipeline
bash orchestrate.sh --all

# Build and optimize
bash orchestrate.sh --build --optimize

# Release with GitHub token
bash orchestrate.sh --release --token ghp_xxxxx
```

### XPI Builder (Recommended)

The Python-based XPI builder is the most reliable method:

```bash
python3 build-xpi.py
```

**Features:**
- Handles both TypeScript and WebExtension plugins
- Automatic version detection
- Generates release manifest
- Creates properly formatted XPI files
- Comprehensive logging

### Individual Scripts

#### Build Script
```bash
bash build-all-plugins.sh
```
- Installs dependencies
- Runs linting and tests
- Compiles code
- Creates XPI packages
- Analyzes plugins

#### Optimization Script
```bash
bash optimize-plugins.sh
```
- Audits and fixes vulnerabilities
- Formats code with Prettier
- Runs ESLint
- Analyzes bundle sizes

#### Debug Script
```bash
bash mcp-debug.sh
```
- Sets up MCP server
- Runs type checking
- Analyzes code complexity
- Generates debug report

#### Release Script
```bash
bash release-plugins.sh [GITHUB_TOKEN]
```
- Generates changelogs
- Updates versions
- Commits changes
- Creates git tags
- Publishes to GitHub

## Generated Artifacts

### Release Directory (`/home/releases/`)

```
release-manifest-20260426_102111.json    # Release metadata
xpi-files.txt                             # List of XPI files
zotero-metadata-plugin-1.0.0-*.xpi       # Metadata plugin XPI
zotero-jisedigi-api-1.0.0-*.xpi          # JPS API plugin XPI
zotero-vercel-ocr-1.0.0-*.xpi            # Vercel OCR plugin XPI
```

### Release Manifest Format

```json
{
  "timestamp": "20260426_102111",
  "date": "2026-04-26T10:21:12.808910",
  "plugins": {
    "zotero-metadata-plugin": {
      "version": "1.0.0",
      "xpi_file": "/home/releases/zotero-metadata-plugin-1.0.0-20260426_102111.xpi",
      "type": "typescript"
    },
    "zotero-jisedigi-api": {
      "version": "1.0.0",
      "xpi_file": "/home/releases/zotero-jisedigi-api-1.0.0-20260426_102111.xpi",
      "type": "webext"
    },
    "zotero-vercel-ocr": {
      "version": "1.0.0",
      "xpi_file": "/home/releases/zotero-vercel-ocr-1.0.0-20260426_102111.xpi",
      "type": "webext"
    }
  }
}
```

## Plugin Details

### zotero-metadata-plugin

**Type:** TypeScript  
**Build:** `npm run build` (TypeScript compilation)  
**Output:** `dist/` directory  
**XPI Size:** ~11.5 KB

**Features:**
- Metadata retrieval via mediaarts-db dataset
- JPS WebAPI entity lookup
- Jest test suite (7 tests)
- ESLint configuration
- TypeScript strict mode

**Build Process:**
1. Install dependencies
2. Run linting
3. Run tests
4. Compile TypeScript
5. Package dist/ into XPI

### zotero-jisedigi-api

**Type:** WebExtension  
**Build:** Python build script  
**Output:** `src/` directory  
**XPI Size:** ~5.5 KB

**Features:**
- JPS WebAPI integration
- Manifest.json configuration
- Localization support (en-US)
- Preferences UI
- Bootstrap initialization

**Build Process:**
1. Run Python build script
2. Package src/ into XPI

### zotero-vercel-ocr

**Type:** WebExtension  
**Build:** Python build script  
**Output:** `src/` directory  
**XPI Size:** ~6.0 KB

**Features:**
- Vercel API integration
- OCR functionality
- Manifest.json configuration
- Localization support
- Updates configuration

**Build Process:**
1. Run Python build script
2. Package src/ into XPI

## Logs and Debugging

### Log Files

All scripts generate timestamped log files:

```
/tmp/zotero-build-*.log              # Build pipeline logs
/tmp/zotero-optimize-*.log           # Optimization logs
/tmp/mcp-server-*.log                # MCP server logs
/tmp/zotero-xpi-builder-*.log        # XPI builder logs
/tmp/github-release-*.log            # Release logs
/tmp/zotero-master-*.log             # Master orchestrator logs
```

### Viewing Logs

```bash
# View latest build log
tail -f /tmp/zotero-build-*.log

# Search for errors
grep ERROR /tmp/zotero-*.log

# View complete log
cat /tmp/zotero-xpi-builder-*.log
```

## Troubleshooting

### Issue: "zip: command not found"

**Solution:** The XPI builder uses Python's zipfile module, which doesn't require the zip command.

### Issue: "package.json not found"

**Solution:** The build script automatically creates package.json for WebExtension plugins.

### Issue: Build timeout

**Solution:** Run scripts individually instead of using the master orchestrator.

### Issue: Git push fails

**Solution:** Ensure git is configured and you have push permissions:
```bash
git config --global user.email "your@email.com"
git config --global user.name "Your Name"
```

## Environment Variables

```bash
# GitHub API token for releases
export GITHUB_TOKEN=ghp_xxxxx

# Node version (should be 18+)
node --version

# npm version (should be 8+)
npm --version
```

## Performance Metrics

### Build Times
- zotero-metadata-plugin: ~2-3 seconds
- zotero-jisedigi-api: <1 second
- zotero-vercel-ocr: <1 second

### XPI Sizes
- zotero-metadata-plugin: 11.5 KB
- zotero-jisedigi-api: 5.5 KB
- zotero-vercel-ocr: 6.0 KB

### Total Pipeline Time
- Build only: ~5 seconds
- Build + Optimize: ~30 seconds
- Build + Optimize + Debug: ~60 seconds
- Full pipeline: ~90 seconds

## Security

### Vulnerability Scanning

The pipeline includes npm audit checks:

```bash
npm audit fix  # Automatically fix vulnerabilities
npm audit      # Report vulnerabilities
```

### Current Status

- zotero-metadata-plugin: 6 high severity vulnerabilities (in dev dependencies)
- zotero-jisedigi-api: No vulnerabilities
- zotero-vercel-ocr: No vulnerabilities

## Integration with MCP

The pipeline integrates with the Zotero MCP server for advanced debugging:

```bash
# Start MCP server
cd /home/zotero-plugins/mcp-server-zotero-dev
npm install
npm start

# Run debug pipeline
bash mcp-debug.sh
```

## GitHub Integration

### Publishing Releases

With GitHub API token:

```bash
python3 publish-releases.py YOUR_GITHUB_TOKEN
```

**Actions:**
1. Creates CHANGELOG.md for each plugin
2. Commits changes to git
3. Creates annotated git tags
4. Creates GitHub releases
5. Uploads XPI files as release assets

### Release Naming

- Tag format: `v{version}`
- Release name: `{plugin-name} v{version}`
- XPI filename: `{plugin-name}-{version}-{timestamp}.xpi`

## Best Practices

1. **Always run optimization before release**
   ```bash
   bash optimize-plugins.sh
   ```

2. **Test locally before publishing**
   ```bash
   python3 build-xpi.py
   ```

3. **Use the master orchestrator for complete pipeline**
   ```bash
   bash orchestrate.sh --all
   ```

4. **Keep git commits clean**
   ```bash
   git add -A
   git commit -m "Release: v1.0.0 - description"
   ```

5. **Verify XPI files before release**
   ```bash
   ls -lh /home/releases/*.xpi
   ```

## References

- **Zotero Plugin Template:** https://github.com/windingwind/zotero-plugin-template
- **Zotero Plugin Toolkit:** https://github.com/windingwind/zotero-plugin-toolkit
- **Zotero Plugin Scaffold:** https://github.com/zotero-plugin-dev/zotero-plugin-scaffold
- **MCP Server Zotero Dev:** https://github.com/introfini/mcp-server-zotero-dev

## Support

For issues or questions:
1. Check the logs in `/tmp/`
2. Review the troubleshooting section
3. Check individual plugin repositories
4. Consult the reference repositories

## License

All plugins are licensed under GPL-3.0. See individual repositories for details.

---

**Last Updated:** 2026-04-26  
**Pipeline Version:** 1.0.0  
**Status:** Production Ready
