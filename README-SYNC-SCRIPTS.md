# Safe Config Sync Scripts

These scripts allow you to safely commit and push configuration files to the repository **without exposing your API keys**.

## 🔑 What Gets Stripped

The scripts automatically replace these keys with placeholders:
- `speechAPIKey` → `"YOUR_GOOGLE_SPEECH_API_KEY"`
- `textToSpeechAPIKey` → `"YOUR_GOOGLE_TTS_API_KEY"`

Your local files are automatically restored after pushing, so you never lose your actual keys!

## 📝 Available Scripts

### 1. **sync-config.js** (Recommended - Node.js)
**Best for:** Most reliable, properly parses JSON, cross-platform

**Requirements:** Node.js installed

**Usage:**
```bash
node sync-config.js "Your commit message"
```

**Example:**
```bash
node sync-config.js "Update Countries Tutor configuration"
```

### 2. **sync-config.sh** (Bash)
**Best for:** Git Bash on Windows, Linux, macOS

**Usage:**
```bash
./sync-config.sh "Your commit message"
```

**First time setup:**
```bash
chmod +x sync-config.sh
```

### 3. **sync-config.bat** (Windows Batch)
**Best for:** Windows Command Prompt

**Usage:**
```cmd
sync-config.bat "Your commit message"
```

**Double-click:** You can also double-click the file in Explorer (uses default commit message)

## 🚀 Quick Start

**Option 1: Node.js (Recommended)**
```bash
cd "C:\Users\ppavl\OneDrive\Active projects\mofacts_config"
node sync-config.js "Update configs"
```

**Option 2: Git Bash**
```bash
cd "C:\Users\ppavl\OneDrive\Active projects\mofacts_config"
./sync-config.sh "Update configs"
```

**Option 3: Windows CMD**
```cmd
cd "C:\Users\ppavl\OneDrive\Active projects\mofacts_config"
sync-config.bat "Update configs"
```

## 🔒 How It Works

1. **Backup** - Creates timestamped backup of all JSON files
2. **Strip Keys** - Replaces API keys with placeholders
3. **Commit** - Stages and commits all changes
4. **Push** - Pushes to remote repository
5. **Restore** - Restores your original files with real keys
6. **Cleanup** - Removes backup directory

**Your local files always keep the real keys!** Only the committed version has placeholders.

## 🛡️ Safety Features

- ✅ Automatic backup before any changes
- ✅ Automatic restoration after push
- ✅ Error handling with auto-restore on failure
- ✅ Backup directories excluded from git (via .gitignore)
- ✅ Works with nested directory structures
- ✅ Preserves JSON formatting

## 📋 What Files Are Processed

All `.json` files in the repository, including subdirectories, except:
- `node_modules/`
- `.git/`
- Backup directories (`.key_backups_*`)

## ⚠️ Important Notes

1. **Always commit from the root directory** of mofacts_config
2. **Don't interrupt the script** - let it complete to ensure keys are restored
3. **Verify the push succeeded** before closing the terminal
4. If something goes wrong, backup files are in `.key_backups_[timestamp]`

## 🔧 Adding More Keys

To strip additional keys, edit the script:

**In sync-config.js:**
```javascript
const KEYS_TO_STRIP = [
  { key: 'speechAPIKey', placeholder: 'YOUR_GOOGLE_SPEECH_API_KEY' },
  { key: 'textToSpeechAPIKey', placeholder: 'YOUR_GOOGLE_TTS_API_KEY' },
  { key: 'newKey', placeholder: 'YOUR_NEW_KEY_HERE' }  // Add new keys here
];
```

**In sync-config.sh:**
```bash
sed -i.tmp 's/"newKey": "[^"]*"/"newKey": "YOUR_NEW_KEY_HERE"/g' "$file"
```

**In sync-config.bat:**
```batch
powershell -Command "... -replace '\"newKey\": \"[^\"]*\"', '\"newKey\": \"YOUR_NEW_KEY_HERE\"' ..."
```

## 🆘 Troubleshooting

**Problem: "No JSON files found"**
- Make sure you're in the mofacts_config directory
- Check that JSON files exist in subdirectories

**Problem: "git: command not found"**
- Install Git or use Git Bash
- Make sure Git is in your PATH

**Problem: Keys not restored**
- Check for `.key_backups_*` directory
- Manually copy files from backup if needed

**Problem: Permission denied (sync-config.sh)**
```bash
chmod +x sync-config.sh
```

## 📚 Examples

**Daily workflow:**
```bash
# Make changes to config files
# ...edit Worldtest.json, etc...

# When ready to commit and push:
node sync-config.js "Add new countries to tutorial"

# Keys are stripped, committed, pushed, then restored!
# Your local files still have the real keys
```

**Quick commit:**
```bash
node sync-config.js
# Uses default message: "Update configuration files"
```

**Batch multiple changes:**
```bash
# Edit multiple JSON files
# ...make changes to multiple configs...

# Single command to sync all:
node sync-config.js "Batch update: new API settings and countries"
```

## ✅ Verification

After running the script, you can verify:

1. **Local files have real keys:**
   ```bash
   grep "speechAPIKey" "Countries Tutor/Countries Tutor/Worldtest.json"
   # Should show: "speechAPIKey": "AIzaSyCDfGq40cf6H1N_KepDtjPNfWEf4dZ_fSE"
   ```

2. **Remote has placeholders:**
   - Check GitHub/remote repository
   - Should show: `"speechAPIKey": "YOUR_GOOGLE_SPEECH_API_KEY"`

3. **Git status is clean:**
   ```bash
   git status
   # Should show: nothing to commit, working tree clean
   ```

---

**Created:** 2025-01-16
**Version:** 1.0
