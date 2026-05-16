# Safe Config Sync Scripts

These scripts let you commit and push configuration updates without committing live API keys.

## What gets stripped

The Node script replaces these keys with placeholders before commit/push:
- `speechAPIKey` -> `"YOUR_GOOGLE_SPEECH_API_KEY"`
- `textToSpeechAPIKey` -> `"YOUR_GOOGLE_TTS_API_KEY"`

After push, local files are restored from backup.

## Scripts

1. `sync-config.js` (authoritative implementation)
- Best for: reliable behavior and JSON-safe key replacement
- Requirements: Node.js + Git
- Usage:
```bash
node scripts/sync-config.js "Your commit message"
```

2. `sync-config.sh` (bash wrapper)
- Runs `sync-config.js`
- Usage:
```bash
./scripts/sync-config.sh "Your commit message"
```

3. `sync-config.bat` (cmd wrapper)
- Runs `sync-config.js`
- Usage:
```cmd
scripts\sync-config.bat "Your commit message"
```

4. `sync.bat` (short Windows alias)
- Runs `sync-config.js`
- Usage:
```cmd
scripts\sync.bat "Your commit message"
```

## How it works

1. Finds `.json` files recursively (excluding `.git`, `node_modules`, and `.key_backups_*`).
2. Creates `.key_backups_[timestamp]` backups.
3. Replaces configured key fields with placeholders.
4. Runs `git add -A`, commit, and push.
5. Restores original local files from backup.
6. Deletes backup directory.

## Important notes

- Recommended: run from repo root: `C:\Users\ppavl\OneDrive\Active projects\mofacts_config`.
- The scripts also work when launched from the `scripts` directory.
- Do not interrupt the script until it exits.
- Verify push success from command output.
- If a failure occurs, the script attempts restore automatically.

## Adding more keys

Edit `KEYS_TO_STRIP` in `sync-config.js`:
```javascript
const KEYS_TO_STRIP = [
  { key: 'speechAPIKey', placeholder: 'YOUR_GOOGLE_SPEECH_API_KEY' },
  { key: 'textToSpeechAPIKey', placeholder: 'YOUR_GOOGLE_TTS_API_KEY' },
  { key: 'newKey', placeholder: 'YOUR_NEW_KEY_HERE' }
];
```

## Verification

1. Local files should contain real local key values after completion.
2. Committed content should contain placeholders for stripped keys.
3. `git status` may show local modifications for files whose real key values were restored after commit.
4. To verify committed content, inspect `HEAD`, for example:
```bash
git grep -n -E '"(speechAPIKey|textToSpeechAPIKey)"' HEAD -- '*.json'
```
