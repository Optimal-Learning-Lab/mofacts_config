#!/usr/bin/env node
/**
 * Reverse stimulus and response in Delphic Maxims JSON file.
 * Changes from: show maxim text → type number
 * To: show number → type maxim text
 */

const fs = require('fs');
const path = require('path');

// Read the original file
const inputFile = path.join(__dirname, 'DelphicMaximsStims.json');
const outputFile = path.join(__dirname, 'DelphicMaximsStims_Reversed.json');

const data = JSON.parse(fs.readFileSync(inputFile, 'utf-8'));

// Reverse each stimulus
for (const cluster of data.setspec.clusters) {
    for (const stim of cluster.stims) {
        // Swap the correctResponse and clozeText values
        const oldResponse = stim.response.correctResponse;
        const oldDisplay = stim.display.clozeText;

        // Reverse them
        stim.response.correctResponse = oldDisplay;
        stim.display.clozeText = oldResponse;
    }
}

// Write to new file
fs.writeFileSync(outputFile, JSON.stringify(data, null, 4), 'utf-8');

console.log('✓ Created DelphicMaximsStims_Reversed.json');
console.log('  - Display (stimulus): Now shows the number (1-147)');
console.log('  - Response (expected): Now expects the maxim text');
