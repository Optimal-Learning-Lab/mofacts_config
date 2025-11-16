#!/usr/bin/env node
/**
 * sync-config.js - Safely commit and push mofacts_config without exposing API keys
 * Usage: node sync-config.js "Optional commit message"
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Configuration
const KEYS_TO_STRIP = [
  { key: 'speechAPIKey', placeholder: 'YOUR_GOOGLE_SPEECH_API_KEY' },
  { key: 'textToSpeechAPIKey', placeholder: 'YOUR_GOOGLE_TTS_API_KEY' }
];

const COMMIT_MSG = process.argv[2] || 'Update configuration files';
const BACKUP_DIR = `.key_backups_${Date.now()}`;

// Colors for terminal output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

// Recursively find all JSON files
function findJsonFiles(dir, fileList = []) {
  const files = fs.readdirSync(dir);

  files.forEach(file => {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);

    if (stat.isDirectory()) {
      // Skip node_modules, .git, and backup directories
      if (!['node_modules', '.git'].includes(file) && !file.startsWith('.key_backups')) {
        findJsonFiles(filePath, fileList);
      }
    } else if (file.endsWith('.json')) {
      fileList.push(filePath);
    }
  });

  return fileList;
}

// Create backup of a file
function backupFile(filePath) {
  const relativePath = path.relative(process.cwd(), filePath);
  const backupPath = path.join(BACKUP_DIR, relativePath);
  const backupDirPath = path.dirname(backupPath);

  // Create directory structure in backup
  fs.mkdirSync(backupDirPath, { recursive: true });
  fs.copyFileSync(filePath, backupPath);

  return backupPath;
}

// Strip keys from JSON file
function stripKeys(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const data = JSON.parse(content);

    let modified = false;

    // Recursively strip keys from nested objects
    function stripFromObject(obj) {
      for (const [key, value] of Object.entries(obj)) {
        if (typeof value === 'object' && value !== null) {
          stripFromObject(value);
        } else {
          // Check if this key should be stripped
          const keyConfig = KEYS_TO_STRIP.find(k => k.key === key);
          if (keyConfig && value !== keyConfig.placeholder) {
            obj[key] = keyConfig.placeholder;
            modified = true;
          }
        }
      }
    }

    stripFromObject(data);

    if (modified) {
      // Write back with proper formatting (2-space indent)
      fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
      return true;
    }

    return false;
  } catch (error) {
    log(`  ⚠️  Error processing ${filePath}: ${error.message}`, 'yellow');
    return false;
  }
}

// Restore file from backup
function restoreFile(filePath) {
  const relativePath = path.relative(process.cwd(), filePath);
  const backupPath = path.join(BACKUP_DIR, relativePath);

  if (fs.existsSync(backupPath)) {
    fs.copyFileSync(backupPath, filePath);
    return true;
  }

  return false;
}

// Execute git command
function git(command) {
  try {
    return execSync(`git ${command}`, { encoding: 'utf8', stdio: 'pipe' });
  } catch (error) {
    return error.stdout || '';
  }
}

// Main execution
async function main() {
  try {
    log('\n🚀 Starting safe config sync...\n', 'bright');

    // Find all JSON files
    log('🔍 Finding JSON files...', 'cyan');
    const jsonFiles = findJsonFiles(process.cwd());

    if (jsonFiles.length === 0) {
      log('❌ No JSON files found!', 'yellow');
      process.exit(1);
    }

    log(`📁 Found ${jsonFiles.length} JSON file(s)\n`, 'green');

    // Create backup directory
    log(`🔒 Creating backup directory: ${BACKUP_DIR}`, 'cyan');
    fs.mkdirSync(BACKUP_DIR, { recursive: true });

    // Backup all files
    log('💾 Backing up files...', 'cyan');
    jsonFiles.forEach(file => {
      backupFile(file);
      log(`  ✓ Backed up: ${path.relative(process.cwd(), file)}`, 'green');
    });

    // Strip keys
    log('\n🔑 Stripping API keys...', 'cyan');
    let strippedCount = 0;
    jsonFiles.forEach(file => {
      if (stripKeys(file)) {
        strippedCount++;
        log(`  ✓ Stripped keys from: ${path.relative(process.cwd(), file)}`, 'yellow');
      } else {
        log(`  - No keys to strip: ${path.relative(process.cwd(), file)}`, 'blue');
      }
    });

    // Git operations
    log('\n📝 Staging all changes...', 'cyan');
    git('add -A');

    log('💬 Committing changes...', 'cyan');
    const commitResult = git(`commit -m "${COMMIT_MSG}"`);
    if (commitResult.includes('nothing to commit')) {
      log('  ⚠️  No changes to commit', 'yellow');
    } else {
      log(`  ✓ Committed: ${COMMIT_MSG}`, 'green');
    }

    log('⬆️  Pushing to remote...', 'cyan');
    git('push');
    log('  ✓ Pushed to remote', 'green');

    // Restore original files
    log('\n🔓 Restoring original files with keys...', 'cyan');
    jsonFiles.forEach(file => {
      if (restoreFile(file)) {
        log(`  ✓ Restored: ${path.relative(process.cwd(), file)}`, 'green');
      }
    });

    // Cleanup
    log('\n🧹 Cleaning up backup directory...', 'cyan');
    fs.rmSync(BACKUP_DIR, { recursive: true, force: true });

    // Summary
    log('\n✅ Done! Configuration pushed without keys, and keys restored locally.\n', 'bright');
    log('📊 Summary:', 'cyan');
    log(`   - Files processed: ${jsonFiles.length}`, 'blue');
    log(`   - Files with keys stripped: ${strippedCount}`, 'blue');
    log(`   - Commit message: "${COMMIT_MSG}"`, 'blue');
    log('');

  } catch (error) {
    log(`\n❌ Error: ${error.message}\n`, 'yellow');

    // Try to restore from backup if it exists
    if (fs.existsSync(BACKUP_DIR)) {
      log('🔄 Attempting to restore from backup...', 'yellow');
      const jsonFiles = findJsonFiles(BACKUP_DIR);
      jsonFiles.forEach(file => {
        const relativePath = path.relative(BACKUP_DIR, file);
        const originalPath = path.join(process.cwd(), relativePath);
        fs.copyFileSync(file, originalPath);
      });
      fs.rmSync(BACKUP_DIR, { recursive: true, force: true });
      log('✓ Restored from backup\n', 'green');
    }

    process.exit(1);
  }
}

main();
