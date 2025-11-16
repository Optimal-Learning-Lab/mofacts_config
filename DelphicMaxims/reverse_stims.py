#!/usr/bin/env python3
"""
Reverse stimulus and response in Delphic Maxims JSON file.
Changes from: show maxim text → type number
To: show number → type maxim text
"""

import json

# Read the original file
with open('DelphicMaximsStims.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Reverse each stimulus
for cluster in data['setspec']['clusters']:
    for stim in cluster['stims']:
        # Swap the correctResponse and clozeText values
        old_response = stim['response']['correctResponse']
        old_display = stim['display']['clozeText']

        # Reverse them
        stim['response']['correctResponse'] = old_display
        stim['display']['clozeText'] = old_response

# Write to new file
with open('DelphicMaximsStims_Reversed.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=4, ensure_ascii=False)

print("✓ Created DelphicMaximsStims_Reversed.json")
print("  - Display (stimulus): Now shows the number (1-147)")
print("  - Response (expected): Now expects the maxim text")
