#!/usr/bin/env node
/**
 * sync-config.js - Safely commit and push mofacts_config without exposing API keys
 * Usage: node sync-config.js "Optional commit message"
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const KEYS_TO_STRIP = [
  { key: 'speechAPIKey', placeholder: 'YOUR_GOOGLE_SPEECH_API_KEY' },
  { key: 'textToSpeechAPIKey', placeholder: 'YOUR_GOOGLE_TTS_API_KEY' }
];

const SCRIPT_DIR = __dirname;
const COMMIT_MSG = process.argv[2] || 'Update configuration files';
const BACKUP_DIR = `.key_backups_${Date.now()}`;

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

function findJsonFiles(dir, fileList = []) {
  const files = fs.readdirSync(dir);

  files.forEach(file => {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);

    if (stat.isDirectory()) {
      if (!['node_modules', '.git'].includes(file) && !file.startsWith('.key_backups')) {
        findJsonFiles(filePath, fileList);
      }
    } else if (file.endsWith('.json')) {
      fileList.push(filePath);
    }
  });

  return fileList;
}

function backupFile(filePath) {
  const relativePath = path.relative(process.cwd(), filePath);
  const backupPath = path.join(BACKUP_DIR, relativePath);
  fs.mkdirSync(path.dirname(backupPath), { recursive: true });
  fs.copyFileSync(filePath, backupPath);
}

function stripKeys(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const data = JSON.parse(content);
    let modified = false;

    function stripFromObject(obj) {
      for (const [key, value] of Object.entries(obj)) {
        if (value && typeof value === 'object') {
          stripFromObject(value);
          continue;
        }

        const keyConfig = KEYS_TO_STRIP.find(k => k.key === key);
        if (keyConfig && value !== keyConfig.placeholder) {
          obj[key] = keyConfig.placeholder;
          modified = true;
        }
      }
    }

    stripFromObject(data);

    if (!modified) return false;

    fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
    return true;
  } catch (error) {
    log(`  ! Error processing ${filePath}: ${error.message}`, 'yellow');
    return false;
  }
}

function restoreFile(filePath) {
  const relativePath = path.relative(process.cwd(), filePath);
  const backupPath = path.join(BACKUP_DIR, relativePath);

  if (!fs.existsSync(backupPath)) return false;

  fs.copyFileSync(backupPath, filePath);
  return true;
}

function gitStrict(command) {
  return execSync(`git ${command}`, { encoding: 'utf8', stdio: 'pipe' });
}

function gitCommitAllowNoChanges(message) {
  try {
    gitStrict(`commit -m "${message.replace(/"/g, '\\"')}"`);
    return { committed: true };
  } catch (error) {
    const out = `${error.stdout || ''}${error.stderr || ''}`;
    if (out.toLowerCase().includes('nothing to commit')) {
      return { committed: false };
    }
    throw error;
  }
}

function ensureRepoRoot() {
  if (fs.existsSync(path.join(process.cwd(), '.git'))) {
    return;
  }

  const parentDir = path.resolve(SCRIPT_DIR, '..');
  if (fs.existsSync(path.join(parentDir, '.git'))) {
    process.chdir(parentDir);
    return;
  }

  throw new Error('Run this script from the mofacts_config repository root or scripts directory (missing .git).');
}

function restoreAll(jsonFiles) {
  jsonFiles.forEach(file => {
    if (restoreFile(file)) {
      log(`  + Restored: ${path.relative(process.cwd(), file)}`, 'green');
    }
  });
}

function cleanupBackupDir() {
  if (fs.existsSync(BACKUP_DIR)) {
    fs.rmSync(BACKUP_DIR, { recursive: true, force: true });
  }
}

async function main() {
  let jsonFiles = [];

  try {
    ensureRepoRoot();

    log('\nStarting safe config sync...\n', 'bright');

    log('Finding JSON files...', 'cyan');
    jsonFiles = findJsonFiles(process.cwd());

    if (jsonFiles.length === 0) {
      throw new Error('No JSON files found.');
    }

    log(`Found ${jsonFiles.length} JSON file(s)\n`, 'green');

    log(`Creating backup directory: ${BACKUP_DIR}`, 'cyan');
    fs.mkdirSync(BACKUP_DIR, { recursive: true });

    log('Backing up files...', 'cyan');
    jsonFiles.forEach(file => {
      backupFile(file);
      log(`  + Backed up: ${path.relative(process.cwd(), file)}`, 'green');
    });

    log('\nStripping API keys...', 'cyan');
    let strippedCount = 0;
    jsonFiles.forEach(file => {
      if (stripKeys(file)) {
        strippedCount += 1;
        log(`  + Stripped keys from: ${path.relative(process.cwd(), file)}`, 'yellow');
      }
    });

    log('\nStaging all changes...', 'cyan');
    gitStrict('add -A');

    log('Committing changes...', 'cyan');
    const commitResult = gitCommitAllowNoChanges(COMMIT_MSG);
    if (commitResult.committed) {
      log(`  + Committed: ${COMMIT_MSG}`, 'green');
    } else {
      log('  ! No changes to commit', 'yellow');
    }

    log('Pushing to remote...', 'cyan');
    gitStrict('push');
    log('  + Push completed', 'green');

    log('\nRestoring original files with local keys...', 'cyan');
    restoreAll(jsonFiles);

    log('\nCleaning up backup directory...', 'cyan');
    cleanupBackupDir();

    log('\nDone. Configuration pushed with placeholders, local files restored.\n', 'bright');
    log('Summary:', 'cyan');
    log(`   - Files processed: ${jsonFiles.length}`, 'blue');
    log(`   - Files with keys stripped: ${strippedCount}`, 'blue');
    log(`   - Commit message: "${COMMIT_MSG}"`, 'blue');
    log('');
  } catch (error) {
    log(`\nError: ${error.message}\n`, 'yellow');

    if (fs.existsSync(BACKUP_DIR)) {
      log('Attempting restore from backup...', 'yellow');
      if (jsonFiles.length > 0) {
        restoreAll(jsonFiles);
      } else {
        const backupJsonFiles = findJsonFiles(BACKUP_DIR);
        backupJsonFiles.forEach(file => {
          const relativePath = path.relative(BACKUP_DIR, file);
          const originalPath = path.join(process.cwd(), relativePath);
          fs.mkdirSync(path.dirname(originalPath), { recursive: true });
          fs.copyFileSync(file, originalPath);
        });
      }
      cleanupBackupDir();
      log('Restore completed.\n', 'green');
    }

    process.exit(1);
  }
}

main();
