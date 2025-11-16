#!/bin/bash
# sync-config.sh - Safely commit and push mofacts_config without exposing API keys
# Usage: ./sync-config.sh "Optional commit message"

set -e  # Exit on error

COMMIT_MSG="${1:-Update configuration files}"
BACKUP_DIR=".key_backups_$(date +%s)"

echo "🔍 Finding JSON files with API keys..."
# Find all .json files in the repository
JSON_FILES=$(find . -name "*.json" -type f | grep -v "node_modules" | grep -v ".git")

if [ -z "$JSON_FILES" ]; then
    echo "❌ No JSON files found!"
    exit 1
fi

echo "📁 Found $(echo "$JSON_FILES" | wc -l) JSON file(s)"

echo "🔒 Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Backup all JSON files
echo "💾 Backing up files..."
for file in $JSON_FILES; do
    # Create subdirectories in backup if needed
    backup_path="$BACKUP_DIR/$file"
    mkdir -p "$(dirname "$backup_path")"
    cp "$file" "$backup_path"
    echo "  ✓ Backed up: $file"
done

# Strip keys from JSON files
echo "🔑 Stripping API keys..."
for file in $JSON_FILES; do
    # Replace actual API keys with placeholders
    # This preserves JSON structure
    sed -i.tmp 's/"speechAPIKey": "[^"]*"/"speechAPIKey": "YOUR_GOOGLE_SPEECH_API_KEY"/g' "$file"
    sed -i.tmp 's/"textToSpeechAPIKey": "[^"]*"/"textToSpeechAPIKey": "YOUR_GOOGLE_TTS_API_KEY"/g' "$file"
    rm -f "${file}.tmp"
    echo "  ✓ Stripped keys from: $file"
done

echo "📝 Staging all changes..."
git add -A

echo "💬 Committing changes..."
git commit -m "$COMMIT_MSG" || echo "⚠️  No changes to commit"

echo "⬆️  Pushing to remote..."
git push

echo "🔓 Restoring original files with keys..."
for file in $JSON_FILES; do
    backup_path="$BACKUP_DIR/$file"
    if [ -f "$backup_path" ]; then
        cp "$backup_path" "$file"
        echo "  ✓ Restored: $file"
    fi
done

echo "🧹 Cleaning up backup directory..."
rm -rf "$BACKUP_DIR"

echo ""
echo "✅ Done! Configuration pushed without keys, and keys restored locally."
echo "📊 Summary:"
echo "   - Files processed: $(echo "$JSON_FILES" | wc -l)"
echo "   - Commit message: $COMMIT_MSG"
