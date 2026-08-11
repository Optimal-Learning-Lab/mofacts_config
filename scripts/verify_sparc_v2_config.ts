import fs from 'node:fs';
import path from 'node:path';

type JsonRecord = Record<string, unknown>;

function isRecord(value: unknown): value is JsonRecord {
  return !!value && typeof value === 'object' && !Array.isArray(value);
}

function jsonFiles(root: string): string[] {
  const result: string[] = [];
  for (const entry of fs.readdirSync(root, { withFileTypes: true })) {
    if (['.git', 'node_modules', 'tmp'].includes(entry.name)) continue;
    const fullPath = path.join(root, entry.name);
    if (entry.isDirectory()) result.push(...jsonFiles(fullPath));
    else if (entry.isFile() && entry.name.endsWith('.json')) result.push(fullPath);
  }
  return result;
}

function sparcDisplays(document: unknown): JsonRecord[] {
  if (!isRecord(document) || !isRecord(document.setspec) || !Array.isArray(document.setspec.sparcPages)) return [];
  return document.setspec.sparcPages
    .filter(isRecord)
    .map((page) => page.display)
    .filter(isRecord)
    .filter((display) => String(display.unitType || '').startsWith('sparc-'));
}

function main(): void {
  const configRoot = path.resolve(process.argv[2] || path.join(import.meta.dirname, '..'));
  const expectedCounts: Record<string, number> = {
    'sparc-autotutor-dialogue': 10,
    'sparc-intro-stats-variables': 43,
    'sparc-fractions-addition': 1,
    'sparc-progressive-chapter': 1,
    'sparc-stoichiometry-dimensional-analysis': 1,
  };
  const counts: Record<string, number> = {};
  let displayCount = 0;
  for (const filePath of jsonFiles(configRoot)) {
    let document: unknown;
    try {
      document = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    } catch {
      continue;
    }
    for (const display of sparcDisplays(document)) {
      displayCount += 1;
      const unitType = String(display.unitType);
      counts[unitType] = (counts[unitType] ?? 0) + 1;
      if (display.schema !== 'tutorscript-sparc/2.0') {
        throw new Error(`${filePath} uses unsupported SPARC schema ${String(display.schema)}`);
      }
      if (unitType !== 'sparc-autotutor-dialogue') continue;
      const forbiddenTargetFields = new Set([
        'label', 'stimuliSetId', 'stimulusKC', 'KCId', 'KCDefault', 'KCCluster', 'response', 'stimulusRecordId',
      ]);
      if (!Array.isArray(display.clusterTargets)) {
        throw new Error(`${filePath} is missing AutoTutor clusterTargets`);
      }
      for (const [index, target] of display.clusterTargets.entries()) {
        if (!isRecord(target)) throw new Error(`${filePath} clusterTargets[${index}] must be an object`);
        for (const field of forbiddenTargetFields) {
          if (field in target) throw new Error(`${filePath} clusterTargets[${index}] contains redundant field ${field}`);
        }
      }
      if ('misconceptionTable' in display) {
        throw new Error(`${filePath} contains redundant misconceptionTable; use autoTutorTargets`);
      }
      const autoTutorTargets = isRecord(display.autoTutorTargets) ? display.autoTutorTargets : {};
      if (!Array.isArray(autoTutorTargets.expectations) || autoTutorTargets.expectations.length === 0) {
        throw new Error(`${filePath} is missing autoTutorTargets.expectations`);
      }
      if (!Array.isArray(autoTutorTargets.misconceptions)) {
        throw new Error(`${filePath} is missing autoTutorTargets.misconceptions`);
      }
      const controller = isRecord(display.instructionalController) ? display.instructionalController : {};
      if (
        controller.adapterId !== 'sparc-autotutor-v1'
        || controller.policyId !== 'progressive-scaffolding-v1'
        || controller.policyVersion !== 1
      ) {
        throw new Error(`${filePath} has an invalid AutoTutor instructionalController`);
      }
      const controllerParameters = isRecord(controller.parameters) ? controller.parameters : {};
      if ('postAssertionResponse' in controllerParameters) {
        throw new Error(`${filePath} contains obsolete postAssertionResponse metadata; assertion persistence belongs to the production rule`);
      }
      if ('productionRules' in display) {
        throw new Error(`${filePath} contains AutoTutor productionRules; progressive-scaffolding-v1 is runtime-owned`);
      }
      const workingMemoryFacts = Array.isArray(display.workingMemoryFacts)
        ? display.workingMemoryFacts.filter(isRecord)
        : [];
      const dialogueThresholds = workingMemoryFacts.find((fact) => fact.factType === 'dialogue.thresholds');
      const thresholdSlots = dialogueThresholds && isRecord(dialogueThresholds.slots) ? dialogueThresholds.slots : {};
      const misconceptionThreshold = Number(thresholdSlots.misconceptionThreshold);
      if (!Number.isFinite(misconceptionThreshold) || misconceptionThreshold < 0 || misconceptionThreshold > 1) {
        throw new Error(`${filePath} requires dialogue.thresholds.misconceptionThreshold from 0 to 1`);
      }
    }
  }
  if (displayCount !== 56) throw new Error(`Expected 56 SPARC displays, found ${displayCount}`);
  for (const [unitType, expectedCount] of Object.entries(expectedCounts)) {
    if (counts[unitType] !== expectedCount) {
      throw new Error(`Expected ${expectedCount} ${unitType} displays, found ${counts[unitType] ?? 0}`);
    }
  }
  if (Object.keys(counts).length !== Object.keys(expectedCounts).length) {
    throw new Error(`SPARC unit inventory contains an unexpected unit type: ${JSON.stringify(counts)}`);
  }
  console.log(JSON.stringify({ configRoot, displayCount, counts, autoTutorRules: 'runtime-owned' }, null, 2));
}

main();
