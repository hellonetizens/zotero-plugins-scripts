#!/usr/bin/env python3
"""
GitHub Release Publisher for Zotero Plugins
Publishes releases to GitHub with XPI files and changelogs
"""

import os
import sys
import json
import subprocess
from pathlib import Path
from datetime import datetime

class GitHubReleasePublisher:
    def __init__(self, api_token=None):
        self.plugins_dir = Path("/home/zotero-plugins")
        self.release_dir = Path("/home/releases")
        self.api_token = api_token or os.environ.get("GITHUB_TOKEN")
        self.timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.log_file = Path(f"/tmp/github-release-{self.timestamp}.log")
        
        self.plugins = [
            "zotero-metadata-plugin",
            "zotero-jisedigi-api",
            "zotero-vercel-ocr"
        ]
    
    def log(self, message, level="INFO"):
        """Log message"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_message = f"[{timestamp}] [{level}] {message}"
        print(log_message)
        with open(self.log_file, "a") as f:
            f.write(log_message + "\n")
    
    def get_version(self, plugin_name):
        """Get plugin version"""
        try:
            package_json = self.plugins_dir / plugin_name / "package.json"
            with open(package_json) as f:
                return json.load(f).get("version", "1.0.0")
        except:
            return "1.0.0"
    
    def commit_changes(self, plugin_name):
        """Commit changes to git"""
        plugin_path = self.plugins_dir / plugin_name
        
        try:
            # Check for changes
            result = subprocess.run(
                ["git", "status", "--porcelain"],
                cwd=plugin_path,
                capture_output=True,
                text=True
            )
            
            if not result.stdout.strip():
                self.log(f"No changes to commit for {plugin_name}", "INFO")
                return True
            
            # Stage changes
            subprocess.run(["git", "add", "-A"], cwd=plugin_path, check=True)
            
            # Commit
            version = self.get_version(plugin_name)
            subprocess.run(
                ["git", "commit", "-m", f"Release: v{version} - {self.timestamp}"],
                cwd=plugin_path,
                check=True
            )
            
            # Push
            subprocess.run(["git", "push"], cwd=plugin_path, check=True)
            
            self.log(f"Committed and pushed changes for {plugin_name}", "SUCCESS")
            return True
        except subprocess.CalledProcessError as e:
            self.log(f"Git error for {plugin_name}: {e}", "WARNING")
            return False
    
    def create_git_tag(self, plugin_name):
        """Create git tag for release"""
        plugin_path = self.plugins_dir / plugin_name
        version = self.get_version(plugin_name)
        tag = f"v{version}"
        
        try:
            # Create tag
            subprocess.run(
                ["git", "tag", "-a", tag, "-m", f"Release: {plugin_name} v{version}"],
                cwd=plugin_path,
                check=True
            )
            
            # Push tag
            subprocess.run(
                ["git", "push", "origin", tag],
                cwd=plugin_path,
                check=True
            )
            
            self.log(f"Created and pushed tag {tag} for {plugin_name}", "SUCCESS")
            return True
        except subprocess.CalledProcessError as e:
            self.log(f"Tag error for {plugin_name}: {e}", "WARNING")
            return False
    
    def create_changelog(self, plugin_name):
        """Create changelog for plugin"""
        plugin_path = self.plugins_dir / plugin_name
        changelog_file = plugin_path / "CHANGELOG.md"
        version = self.get_version(plugin_name)
        
        try:
            # Get recent commits
            result = subprocess.run(
                ["git", "log", "--oneline", "-10"],
                cwd=plugin_path,
                capture_output=True,
                text=True
            )
            
            commits = result.stdout.strip().split("\n") if result.stdout else []
            
            # Create changelog entry
            changelog_entry = f"""## [{version}] - {datetime.now().strftime('%Y-%m-%d')}

### Changes
"""
            for commit in commits:
                changelog_entry += f"- {commit}\n"
            
            # Prepend to existing changelog or create new
            if changelog_file.exists():
                with open(changelog_file) as f:
                    existing = f.read()
                with open(changelog_file, "w") as f:
                    f.write(changelog_entry + "\n" + existing)
            else:
                with open(changelog_file, "w") as f:
                    f.write("# Changelog\n\n" + changelog_entry)
            
            self.log(f"Created changelog for {plugin_name}", "SUCCESS")
            return True
        except Exception as e:
            self.log(f"Changelog error for {plugin_name}: {e}", "WARNING")
            return False
    
    def publish_release(self, plugin_name):
        """Publish release to GitHub"""
        version = self.get_version(plugin_name)
        tag = f"v{version}"
        
        # Find XPI file
        xpi_files = list(self.release_dir.glob(f"{plugin_name}*.xpi"))
        if not xpi_files:
            self.log(f"No XPI file found for {plugin_name}", "WARNING")
            return False
        
        xpi_file = xpi_files[0]
        
        self.log(f"Publishing {plugin_name} v{version} to GitHub", "INFO")
        self.log(f"XPI file: {xpi_file.name}", "INFO")
        
        # If API token available, create release via API
        if self.api_token:
            return self._create_release_via_api(plugin_name, tag, xpi_file)
        else:
            self.log("GitHub API token not available, skipping API release", "WARNING")
            return True
    
    def _create_release_via_api(self, plugin_name, tag, xpi_file):
        """Create release via GitHub API"""
        try:
            import requests
        except ImportError:
            self.log("requests library not available, skipping API release", "WARNING")
            return False
        
        try:
            # Get repo info
            plugin_path = self.plugins_dir / plugin_name
            result = subprocess.run(
                ["git", "config", "--get", "remote.origin.url"],
                cwd=plugin_path,
                capture_output=True,
                text=True
            )
            
            repo_url = result.stdout.strip()
            # Extract owner/repo from URL
            if "github.com" in repo_url:
                repo = repo_url.split("github.com")[1].strip("/").replace(".git", "")
            else:
                self.log(f"Could not parse repo URL: {repo_url}", "WARNING")
                return False
            
            # Create release
            headers = {
                "Authorization": f"token {self.api_token}",
                "Accept": "application/vnd.github.v3+json"
            }
            
            release_data = {
                "tag_name": tag,
                "name": f"{plugin_name} {tag}",
                "body": f"Automated release - {self.timestamp}",
                "draft": False,
                "prerelease": False
            }
            
            response = requests.post(
                f"https://api.github.com/repos/{repo}/releases",
                headers=headers,
                json=release_data
            )
            
            if response.status_code == 201:
                release_id = response.json()["id"]
                
                # Upload XPI file
                with open(xpi_file, "rb") as f:
                    upload_headers = {
                        "Authorization": f"token {self.api_token}",
                        "Content-Type": "application/octet-stream"
                    }
                    
                    upload_response = requests.post(
                        f"https://uploads.github.com/repos/{repo}/releases/{release_id}/assets?name={xpi_file.name}",
                        headers=upload_headers,
                        data=f
                    )
                    
                    if upload_response.status_code == 201:
                        self.log(f"Uploaded XPI file for {plugin_name}", "SUCCESS")
                    else:
                        self.log(f"Failed to upload XPI: {upload_response.status_code}", "ERROR")
                        return False
                
                self.log(f"Published release for {plugin_name} v{tag}", "SUCCESS")
                return True
            else:
                self.log(f"Failed to create release: {response.status_code} - {response.text}", "ERROR")
                return False
        except Exception as e:
            self.log(f"API error for {plugin_name}: {e}", "ERROR")
            return False
    
    def run(self):
        """Run the complete release pipeline"""
        self.log("=== GitHub Release Publisher ===", "INFO")
        self.log(f"Timestamp: {self.timestamp}", "INFO")
        self.log(f"Log file: {self.log_file}", "INFO")
        self.log("")
        
        for plugin_name in self.plugins:
            self.log(f"Processing {plugin_name}...", "INFO")
            
            # Create changelog
            self.create_changelog(plugin_name)
            
            # Commit changes
            self.commit_changes(plugin_name)
            
            # Create tag
            self.create_git_tag(plugin_name)
            
            # Publish release
            self.publish_release(plugin_name)
            
            self.log("")
        
        self.log("=== Release Pipeline Complete ===", "SUCCESS")

if __name__ == "__main__":
    api_token = sys.argv[1] if len(sys.argv) > 1 else None
    publisher = GitHubReleasePublisher(api_token)
    publisher.run()
