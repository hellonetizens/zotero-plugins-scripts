# Zotero Plugin Development Scripts

Comprehensive automation pipeline for building, optimizing, debugging, and releasing Zotero plugins.

## Overview

This repository contains production-ready scripts for managing three Zotero plugins:
- **zotero-metadata-plugin** - TypeScript-based metadata retrieval
- **zotero-jisedigi-api** - WebExtension JPS API integration  
- **zotero-vercel-ocr** - WebExtension Vercel OCR integration

## Quick Start

### 1. Clone the Plugin Repositories

```bash
mkdir -p ~/zotero-plugins
cd ~/zotero-plugins

# Clone your plugins
git clone https://github.com/hellonetizens/zotero-metadata-plugin.git
git clone https://github.com/hellonetizens/zotero-jisedigi-api.git
git clone https://github.com/hellonetizens/zotero-vercel-ocr.git

# Clone reference repositories
git clone https://github.com/windingwind/zotero-plugin-template.git
git clone https://github.com/windingwind/zotero-plugin-toolkit.git
git clone https://github.com/zotero-plugin-dev/zotero-plugin-scaffold.git
git clone https://github.com/introfini/mcp-server-zotero-dev.git
```

### 2. Copy Scripts

```bash
# Copy this repository's scripts
cp -r ~/zotero-plugins-scripts/* ~/zotero-plugins/
```

### 3. Build XPI Files

```bash
cd ~/zotero-plugins
python3 build-xpi.py
```

**Output:** XPI files in `~/zotero-plugins/releases/`

## Scripts

### Core Build Scripts

#### `build-xpi.py` ⭐ RECOMMENDED
Python-based XPI builder for all plugin types.

```bash
python3 build-xpi.py
```

**Features:**
- Handles TypeScript and WebExtension plugins
- Automatic version detection
- Generates release manifest
- ~5 seconds execution time

**Output:**
- XPI files: `{plugin}-{version}-{timestamp}.xpi`
- Manifest: `release-manifest-{timestamp}.json`
- File list: `xpi-files.txt`

#### `build-all-plugins.sh`
Comprehensive build pipeline with testing and analysis.

```bash
bash build-all-plugins.sh
```

**Features:**
- Installs dependencies
- Runs linting and tests
- Compiles code
- Creates XPI packages
- Analyzes plugins

### Optimization & Debugging

#### `optimize-plugins.sh`
Code optimization and quality checks.

```bash
bash optimize-plugins.sh
```

**Performs:**
- Dependency audit and fixes
- Code formatting (Prettier)
- Linting (ESLint)
- Bundle size analysis

#### `mcp-debug.sh`
MCP-based debugging and analysis.

```bash
bash mcp-debug.sh
```

**Provides:**
- Type checking
- Code complexity analysis
- Performance profiling
- Debug report generation

### Release Management

#### `release-plugins.sh`
Release pipeline with changelog and git management.

```bash
bash release-plugins.sh [GITHUB_TOKEN]
```

**Actions:**
- Generates changelogs
- Updates versions
- Commits changes
- Creates git tags
- Publishes to GitHub (with token)

#### `publish-releases.py`
GitHub release publisher.

```bash
python3 publish-releases.py [GITHUB_TOKEN]
```

**Features:**
- Creates GitHub releases
- Uploads XPI files
- Manages release notes
- API integration

### Master Orchestration

#### `orchestrate.sh`
Master orchestrator for complete pipeline.

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
bash orchestrate.sh --release --token YOUR_GITHUB_TOKEN
```

## Output Structure

```
~/zotero-plugins/
├── releases/
│   ├── zotero-metadata-plugin-1.0.0-*.xpi
│   ├── zotero-jisedigi-api-1.0.0-*.xpi
│   ├── zotero-vercel-ocr-1.0.0-*.xpi
│   ├── release-manifest-*.json
│   ├── xpi-files.txt
│   ├── PIPELINE_GUIDE.md
│   └── EXECUTION_SUMMARY.md
├── [plugin directories]
└── [script files]
```

## Documentation

- **README.md** - This file
- **PIPELINE_GUIDE.md** - Complete usage guide with examples
- **EXECUTION_SUMMARY.md** - Execution results and status
- **release-manifest-*.json** - Release metadata

## Requirements

### System
- Linux/macOS/WSL
- Python 3.6+
- Node.js 18+
- npm 8+
- git

### Optional
- GitHub API token (for publishing releases)
- MCP server (for advanced debugging)

## Installation

### 1. Install Dependencies

```bash
# Node.js and npm (if not installed)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Python (usually pre-installed)
python3 --version
```

### 2. Verify Installation

```bash
node --version    # Should be v18+
npm --version     # Should be 8+
python3 --version # Should be 3.6+
git --version     # Should be 2.0+
```

## Usage Examples

### Build All Plugins

```bash
cd ~/zotero-plugins
python3 build-xpi.py
```

### Build, Optimize, and Release

```bash
bash orchestrate.sh --build --optimize --release
```

### Build with GitHub Release

```bash
bash orchestrate.sh --all --token YOUR_GITHUB_TOKEN
```

### Optimize Code Only

```bash
bash optimize-plugins.sh
```

### Debug with MCP

```bash
bash mcp-debug.sh
```

## Performance

### Build Times
- Total: ~5 seconds
- Per plugin: ~1.7 seconds
- XPI creation: <1 second

### File Sizes
- Total XPI: ~23 KB
- Average per plugin: ~7.7 KB
- Largest: zotero-metadata-plugin (11.5 KB)

## Troubleshooting

### Issue: "Command not found"
**Solution:** Ensure scripts are executable:
```bash
chmod +x *.sh
```

### Issue: "package.json not found"
**Solution:** Scripts automatically create package.json for WebExtension plugins.

### Issue: Build timeout
**Solution:** Run scripts individually instead of using orchestrator.

### Issue: Git push fails
**Solution:** Configure git and ensure push permissions:
```bash
git config --global user.email "your@email.com"
git config --global user.name "Your Name"
```

### Issue: GitHub API errors
**Solution:** Verify API token is valid and has necessary permissions.

## Logs

All scripts generate timestamped logs:

```
/tmp/zotero-build-*.log              # Build logs
/tmp/zotero-optimize-*.log           # Optimization logs
/tmp/mcp-server-*.log                # MCP server logs
/tmp/zotero-xpi-builder-*.log        # XPI builder logs
/tmp/github-release-*.log            # Release logs
/tmp/zotero-master-*.log             # Master orchestrator logs
```

View logs:
```bash
tail -f /tmp/zotero-xpi-builder-*.log
```

## Environment Variables

```bash
# GitHub API token
export GITHUB_TOKEN=YOUR_GITHUB_TOKEN

# Node version
export NODE_VERSION=18

# npm registry (optional)
export NPM_REGISTRY=https://registry.npmjs.org/
```

## Security

### Vulnerability Scanning

```bash
npm audit fix  # Fix vulnerabilities
npm audit      # Report vulnerabilities
```

### API Token Safety

- Never commit tokens to git
- Use environment variables
- Rotate tokens regularly
- Use GitHub's token expiration feature

## Integration

### GitHub Integration
- Automatic git commits
- Tag creation
- Release publishing
- XPI file uploads

### MCP Integration
- Type checking
- Code analysis
- Performance profiling
- Debug reporting

### Reference Repositories
- zotero-plugin-template
- zotero-plugin-toolkit
- zotero-plugin-scaffold
- mcp-server-zotero-dev

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
   ls -lh releases/*.xpi
   ```

## Support

### Documentation
- See PIPELINE_GUIDE.md for detailed documentation
- See EXECUTION_SUMMARY.md for execution results

### Troubleshooting
1. Check logs in `/tmp/`
2. Review the troubleshooting section
3. Check individual plugin repositories
4. Consult reference repositories

### References
- [Zotero Plugin Template](https://github.com/windingwind/zotero-plugin-template)
- [Zotero Plugin Toolkit](https://github.com/windingwind/zotero-plugin-toolkit)
- [Zotero Plugin Scaffold](https://github.com/zotero-plugin-dev/zotero-plugin-scaffold)
- [MCP Server Zotero Dev](https://github.com/introfini/mcp-server-zotero-dev)

## License

All scripts are provided as-is for use with Zotero plugins. See individual plugin repositories for license information.

## Contributing

To contribute improvements:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Changelog

### v1.0.0 (2026-04-26)
- Initial release
- Build pipeline for TypeScript and WebExtension plugins
- Optimization and debugging tools
- Release management and GitHub integration
- Comprehensive documentation

---

**Status:** ✅ Production Ready  
**Last Updated:** 2026-04-26  
**Maintainer:** Zotero Plugin Development Team
