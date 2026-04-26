#!/usr/bin/env python3
"""
Comprehensive Zotero Plugin XPI Builder
Handles all three plugins with proper packaging and release management
"""

import os
import sys
import json
import shutil
import zipfile
import subprocess
from pathlib import Path
from datetime import datetime

class ZoteroPluginBuilder:
    def __init__(self):
        self.plugins_dir = Path("/home/zotero-plugins")
        self.release_dir = Path("/home/releases")
        self.timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.log_file = Path(f"/tmp/zotero-xpi-builder-{self.timestamp}.log")
        self.release_dir.mkdir(parents=True, exist_ok=True)
        
        self.plugins = {
            "zotero-metadata-plugin": {
                "type": "typescript",
                "has_dist": True,
                "manifest": "manifest.json"
            },
            "zotero-jisedigi-api": {
                "type": "webext",
                "has_dist": False,
                "manifest": "src/manifest.json"
            },
            "zotero-vercel-ocr": {
                "type": "webext",
                "has_dist": False,
                "manifest": "src/manifest.json"
            }
        }
    
    def log(self, message, level="INFO"):
        """Log message to file and stdout"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_message = f"[{timestamp}] [{level}] {message}"
        print(log_message)
        with open(self.log_file, "a") as f:
            f.write(log_message + "\n")
    
    def get_plugin_version(self, plugin_name):
        """Extract version from package.json"""
        try:
            package_json = self.plugins_dir / plugin_name / "package.json"
            with open(package_json) as f:
                data = json.load(f)
                return data.get("version", "1.0.0")
        except Exception as e:
            self.log(f"Error reading version for {plugin_name}: {e}", "WARNING")
            return "1.0.0"
    
    def get_manifest_version(self, plugin_name):
        """Extract version from manifest.json"""
        try:
            manifest_path = self.plugins_dir / plugin_name / self.plugins[plugin_name]["manifest"]
            with open(manifest_path) as f:
                data = json.load(f)
                return data.get("version", "1.0.0")
        except Exception as e:
            self.log(f"Error reading manifest version for {plugin_name}: {e}", "WARNING")
            return "1.0.0"
    
    def create_xpi_typescript(self, plugin_name):
        """Create XPI for TypeScript-based plugins"""
        plugin_path = self.plugins_dir / plugin_name
        dist_path = plugin_path / "dist"
        manifest_path = plugin_path / "manifest.json"
        
        if not dist_path.exists():
            self.log(f"No dist directory found for {plugin_name}", "ERROR")
            return None
        
        version = self.get_plugin_version(plugin_name)
        xpi_name = f"{plugin_name}-{version}-{self.timestamp}.xpi"
        xpi_path = self.release_dir / xpi_name
        
        try:
            with zipfile.ZipFile(xpi_path, 'w', zipfile.ZIP_DEFLATED) as zf:
                # Add dist files
                for file_path in dist_path.rglob("*"):
                    if file_path.is_file():
                        arcname = file_path.relative_to(dist_path)
                        zf.write(file_path, arcname)
                
                # Add manifest
                if manifest_path.exists():
                    zf.write(manifest_path, "manifest.json")
            
            size = xpi_path.stat().st_size / 1024  # KB
            self.log(f"Created XPI for {plugin_name}: {xpi_name} ({size:.1f} KB)", "SUCCESS")
            return str(xpi_path)
        except Exception as e:
            self.log(f"Error creating XPI for {plugin_name}: {e}", "ERROR")
            return None
    
    def create_xpi_webext(self, plugin_name):
        """Create XPI for WebExtension-based plugins"""
        plugin_path = self.plugins_dir / plugin_name
        src_path = plugin_path / "src"
        
        if not src_path.exists():
            self.log(f"No src directory found for {plugin_name}", "ERROR")
            return None
        
        version = self.get_manifest_version(plugin_name)
        xpi_name = f"{plugin_name}-{version}-{self.timestamp}.xpi"
        xpi_path = self.release_dir / xpi_name
        
        try:
            with zipfile.ZipFile(xpi_path, 'w', zipfile.ZIP_DEFLATED) as zf:
                # Add all files from src
                for file_path in src_path.rglob("*"):
                    if file_path.is_file():
                        # Skip git and node_modules
                        if ".git" in file_path.parts or "node_modules" in file_path.parts:
                            continue
                        arcname = file_path.relative_to(src_path)
                        zf.write(file_path, arcname)
            
            size = xpi_path.stat().st_size / 1024  # KB
            self.log(f"Created XPI for {plugin_name}: {xpi_name} ({size:.1f} KB)", "SUCCESS")
            return str(xpi_path)
        except Exception as e:
            self.log(f"Error creating XPI for {plugin_name}: {e}", "ERROR")
            return None
    
    def build_plugin(self, plugin_name):
        """Build a single plugin"""
        self.log(f"Building {plugin_name}...", "INFO")
        
        plugin_path = self.plugins_dir / plugin_name
        if not plugin_path.exists():
            self.log(f"Plugin directory not found: {plugin_path}", "ERROR")
            return False
        
        plugin_type = self.plugins[plugin_name]["type"]
        
        try:
            if plugin_type == "typescript":
                # Run npm build
                result = subprocess.run(
                    ["npm", "run", "build"],
                    cwd=plugin_path,
                    capture_output=True,
                    text=True,
                    timeout=60
                )
                if result.returncode != 0:
                    self.log(f"Build failed for {plugin_name}: {result.stderr}", "ERROR")
                    return False
            elif plugin_type == "webext":
                # Run Python build if available
                build_script = plugin_path / "build.py"
                if build_script.exists():
                    result = subprocess.run(
                        ["python3", str(build_script)],
                        cwd=plugin_path,
                        capture_output=True,
                        text=True,
                        timeout=60
                    )
                    if result.returncode != 0:
                        self.log(f"Python build failed for {plugin_name}: {result.stderr}", "WARNING")
            
            self.log(f"Build completed for {plugin_name}", "SUCCESS")
            return True
        except subprocess.TimeoutExpired:
            self.log(f"Build timeout for {plugin_name}", "ERROR")
            return False
        except Exception as e:
            self.log(f"Build error for {plugin_name}: {e}", "ERROR")
            return False
    
    def create_all_xpis(self):
        """Create XPI files for all plugins"""
        self.log("=== Creating XPI Packages ===", "INFO")
        
        xpi_files = []
        for plugin_name, config in self.plugins.items():
            if config["type"] == "typescript":
                xpi_path = self.create_xpi_typescript(plugin_name)
            else:
                xpi_path = self.create_xpi_webext(plugin_name)
            
            if xpi_path:
                xpi_files.append(xpi_path)
        
        # Save list of XPI files
        xpi_list_file = self.release_dir / "xpi-files.txt"
        with open(xpi_list_file, "w") as f:
            for xpi_path in xpi_files:
                f.write(xpi_path + "\n")
        
        self.log(f"Created {len(xpi_files)} XPI files", "SUCCESS")
        return xpi_files
    
    def generate_release_manifest(self, xpi_files):
        """Generate release manifest JSON"""
        manifest = {
            "timestamp": self.timestamp,
            "date": datetime.now().isoformat(),
            "plugins": {}
        }
        
        for plugin_name in self.plugins.keys():
            version = self.get_plugin_version(plugin_name)
            xpi_file = next((f for f in xpi_files if plugin_name in f), None)
            
            manifest["plugins"][plugin_name] = {
                "version": version,
                "xpi_file": xpi_file,
                "type": self.plugins[plugin_name]["type"]
            }
        
        manifest_file = self.release_dir / f"release-manifest-{self.timestamp}.json"
        with open(manifest_file, "w") as f:
            json.dump(manifest, f, indent=2)
        
        self.log(f"Generated release manifest: {manifest_file}", "SUCCESS")
        return manifest_file
    
    def run(self):
        """Run the complete build pipeline"""
        self.log("=== Zotero Plugin XPI Builder ===", "INFO")
        self.log(f"Timestamp: {self.timestamp}", "INFO")
        self.log(f"Log file: {self.log_file}", "INFO")
        self.log("")
        
        # Build all plugins
        self.log("=== Building Plugins ===", "INFO")
        for plugin_name in self.plugins.keys():
            self.build_plugin(plugin_name)
        
        self.log("")
        
        # Create XPI files
        xpi_files = self.create_all_xpis()
        
        self.log("")
        
        # Generate manifest
        if xpi_files:
            self.generate_release_manifest(xpi_files)
        
        self.log("")
        self.log("=== Build Complete ===", "SUCCESS")
        self.log(f"Release directory: {self.release_dir}", "INFO")
        self.log(f"XPI files created: {len(xpi_files)}", "INFO")
        
        return len(xpi_files) > 0

if __name__ == "__main__":
    builder = ZoteroPluginBuilder()
    success = builder.run()
    sys.exit(0 if success else 1)
