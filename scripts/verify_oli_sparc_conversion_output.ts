import * as fs from 'node:fs';
import * as path from 'node:path';

type JsonRecord = Record<string, unknown>;

const ANSWERABLE_ATOM_TYPES = new Set([
  'button',
  'checkbox',
  'dropdown',
  'fraction-input',
  'select',
  'text-input',
]);

function isRecord(value: unknown): value is JsonRecord {
  return !!value && typeof value === 'object' && !Array.isArray(value);
}

function asRecord(value: unknown, label: string): JsonRecord {
  if (!isRecord(value)) {
    throw new Error(`${label} must be an object`);
  }
  return value;
}

function asArray(value: unknown, label: string): unknown[] {
  if (!Array.isArray(value)) {
    throw new Error(`${label} must be an array`);
  }
  return value;
}

function nonBlank(value: unknown, label: string): string {
  const text = typeof value === 'string' ? value.trim() : '';
  if (!text) {
    throw new Error(`${label} is required`);
  }
  return text;
}

function readJson(filePath: string): JsonRecord {
  return asRecord(JSON.parse(fs.readFileSync(filePath, 'utf8')), filePath);
}

function parseArgs(argv: string[]): { packageRoot: string } {
  let packageRoot = '';
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === '--package-root') {
      packageRoot = path.resolve(argv[++index] || '');
    } else if (arg === '--help' || arg === '-h') {
      printHelp();
      process.exit(0);
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }
  if (!packageRoot) {
    throw new Error('Missing --package-root');
  }
  return { packageRoot };
}

function printHelp(): void {
  console.log(`Usage:
  node --experimental-strip-types scripts/verify_oli_sparc_conversion_output.ts --package-root <path>
`);
}

function collectNodesById(nodes: unknown[], out = new Map<string, JsonRecord>()): Map<string, JsonRecord> {
  for (const node of nodes) {
    if (!isRecord(node)) {
      continue;
    }
    const id = typeof node.id === 'string' ? node.id.trim() : '';
    if (id) {
      if (out.has(id)) {
        throw new Error(`Duplicate SPARC node id "${id}"`);
      }
      out.set(id, node);
    }
    if (Array.isArray(node.children)) {
      collectNodesById(node.children, out);
    }
    if (Array.isArray(node.panels)) {
      for (const panel of node.panels) {
        if (isRecord(panel) && Array.isArray(panel.children)) {
          collectNodesById(panel.children, out);
        }
      }
    }
  }
  return out;
}

function nodeClusterIndices(node: JsonRecord): number[] {
  if (Array.isArray(node.clusterIndices)) {
    return node.clusterIndices.map((value, index) => {
      const numberValue = Number(value);
      if (!Number.isInteger(numberValue) || numberValue < 0) {
        throw new Error(`SPARC node "${String(node.id)}" clusterIndices[${index}] must be a non-negative integer`);
      }
      return numberValue;
    });
  }
  if (node.clusterIndex !== undefined) {
    const numberValue = Number(node.clusterIndex);
    if (!Number.isInteger(numberValue) || numberValue < 0) {
      throw new Error(`SPARC node "${String(node.id)}" clusterIndex must be a non-negative integer`);
    }
    return [numberValue];
  }
  return [];
}

function parseClusterList(value: unknown): Set<number> {
  const text = nonBlank(value, 'sparcsession.clusterlist');
  const out = new Set<number>();
  for (const token of text.split(/\s+/).filter(Boolean)) {
    const range = token.split('-');
    const start = Number(range[0]);
    const end = range.length === 1 ? start : Number(range[1]);
    if (!Number.isInteger(start) || !Number.isInteger(end) || start < 0 || end < start) {
      throw new Error(`Invalid sparcsession.clusterlist token "${token}"`);
    }
    for (let clusterIndex = start; clusterIndex <= end; clusterIndex += 1) {
      out.add(clusterIndex);
    }
  }
  return out;
}

function assertClusterTargets(params: {
  display: JsonRecord;
  clusters: unknown[];
  label: string;
}): Set<number> {
  const targets = asArray(params.display.clusterTargets, `${params.label} display.clusterTargets`);
  if (targets.length !== params.clusters.length) {
    throw new Error(`${params.label} clusterTargets length ${targets.length} does not match clusters length ${params.clusters.length}`);
  }
  const seenIndices = new Set<number>();
  const seenKcs = new Set<string>();
  for (const [index, targetValue] of targets.entries()) {
    const target = asRecord(targetValue, `${params.label} display.clusterTargets[${index}]`);
    const clusterIndex = Number(target.clusterIndex);
    if (!Number.isInteger(clusterIndex) || clusterIndex < 0) {
      throw new Error(`${params.label} display.clusterTargets[${index}].clusterIndex must be a non-negative integer`);
    }
    if (seenIndices.has(clusterIndex)) {
      throw new Error(`${params.label} duplicate clusterTarget clusterIndex ${clusterIndex}`);
    }
    seenIndices.add(clusterIndex);
    const clusterKC = nonBlank(target.clusterKC, `${params.label} display.clusterTargets[${index}].clusterKC`);
    const stimulusKC = nonBlank(target.stimulusKC, `${params.label} display.clusterTargets[${index}].stimulusKC`);
    nonBlank(target.KCId, `${params.label} display.clusterTargets[${index}].KCId`);
    nonBlank(target.KCDefault, `${params.label} display.clusterTargets[${index}].KCDefault`);
    nonBlank(target.KCCluster, `${params.label} display.clusterTargets[${index}].KCCluster`);
    if (seenKcs.has(clusterKC)) {
      throw new Error(`${params.label} duplicate clusterTarget clusterKC ${clusterKC}`);
    }
    seenKcs.add(clusterKC);
    const cluster = asRecord(params.clusters[clusterIndex], `${params.label} setspec.clusters[${clusterIndex}]`);
    if (cluster.clusterKC !== clusterKC) {
      throw new Error(`${params.label} clusterTarget ${clusterIndex} clusterKC does not match setspec.clusters[${clusterIndex}].clusterKC`);
    }
    const firstStim = asRecord(asArray(cluster.stims, `${params.label} cluster ${clusterIndex} stims`)[0], `${params.label} cluster ${clusterIndex} stims[0]`);
    if (firstStim.clusterKC !== clusterKC || firstStim.stimulusKC !== stimulusKC) {
      throw new Error(`${params.label} cluster ${clusterIndex} first stim identity does not match display.clusterTargets`);
    }
  }
  return seenIndices;
}

function collectModelPracticeEffects(rules: unknown[], label: string): JsonRecord[] {
  const effects: JsonRecord[] = [];
  for (const [ruleIndex, ruleValue] of rules.entries()) {
    const rule = asRecord(ruleValue, `${label} productionRules[${ruleIndex}]`);
    for (const [effectIndex, effectValue] of asArray(rule.then, `${label} productionRules[${ruleIndex}].then`).entries()) {
      const effect = asRecord(effectValue, `${label} productionRules[${ruleIndex}].then[${effectIndex}]`);
      if (effect.type === 'model-practice') {
        effects.push(effect);
      }
    }
  }
  return effects;
}

function verifyPackageFile(packageRoot: string, tdfFile: string): {
  tdfFile: string;
  stimFile: string;
  clusters: number;
  modelPracticeEffects: number;
  modeledIntentNodes: number;
} {
  const tdfPath = path.join(packageRoot, tdfFile);
  const tdf = readJson(tdfPath);
  const stimFile = nonBlank(
    asRecord(asRecord(tdf.tutor, `${tdfFile} tutor`).setspec, `${tdfFile} tutor.setspec`).stimulusfile,
    `${tdfFile} tutor.setspec.stimulusfile`,
  );
  const stimPath = path.join(packageRoot, stimFile);
  if (!fs.existsSync(stimPath)) {
    throw new Error(`${tdfFile} references missing stimulus file ${stimFile}`);
  }
  const stim = readJson(stimPath);
  const setspec = asRecord(stim.setspec, `${stimFile} setspec`);
  const clusters = asArray(setspec.clusters, `${stimFile} setspec.clusters`);
  const pages = asArray(setspec.sparcPages, `${stimFile} setspec.sparcPages`);
  if (pages.length !== 1) {
    throw new Error(`${stimFile} must contain exactly one setspec.sparcPages entry`);
  }
  const page = asRecord(pages[0], `${stimFile} setspec.sparcPages[0]`);
  const display = asRecord(page.display, `${stimFile} sparcPages[0].display`);
  if (display.type !== 'sparc') {
    throw new Error(`${stimFile} display.type must be "sparc"`);
  }
  if (display.schema !== 'tutorscript-sparc/1.0') {
    throw new Error(`${stimFile} display.schema must be "tutorscript-sparc/1.0"`);
  }
  const nodes = asArray(display.nodes, `${stimFile} display.nodes`);
  if (nodes.length === 0) {
    throw new Error(`${stimFile} display.nodes must not be empty`);
  }
  const clusterIndices = assertClusterTargets({ display, clusters, label: stimFile });
  const nodesById = collectNodesById(nodes);
  const rules = asArray(display.productionRules, `${stimFile} display.productionRules`);
  const modelPracticeEffects = collectModelPracticeEffects(rules, stimFile);
  for (const [index, effect] of modelPracticeEffects.entries()) {
    const clusterIndex = Number(effect.clusterIndex);
    if (!Number.isInteger(clusterIndex) || !clusterIndices.has(clusterIndex)) {
      throw new Error(`${stimFile} model-practice effect ${index} references unresolved clusterIndex ${String(effect.clusterIndex)}`);
    }
    const nodeId = typeof effect.nodeId === 'string' ? effect.nodeId.trim() : '';
    if (nodeId && !nodesById.has(nodeId)) {
      throw new Error(`${stimFile} model-practice effect ${index} references missing nodeId ${nodeId}`);
    }
  }
  const intentEntries = asArray(asRecord(display.response, `${stimFile} display.response`).intentByNode, `${stimFile} display.response.intentByNode`);
  if (intentEntries.length > 0 && modelPracticeEffects.length === 0) {
    throw new Error(`${stimFile} has scored intent nodes but no model-practice production-rule effects`);
  }
  let modeledIntentNodes = 0;
  for (const [index, intentValue] of intentEntries.entries()) {
    const intent = asRecord(intentValue, `${stimFile} response.intentByNode[${index}]`);
    const nodeId = nonBlank(intent.node, `${stimFile} response.intentByNode[${index}].node`);
    const node = nodesById.get(nodeId);
    if (!node) {
      throw new Error(`${stimFile} response.intentByNode[${index}] references missing node ${nodeId}`);
    }
    if (ANSWERABLE_ATOM_TYPES.has(String(node.atomType))) {
      const attachedIndices = nodeClusterIndices(node);
      if (attachedIndices.length === 0) {
        throw new Error(`${stimFile} answerable intent node ${nodeId} is missing clusterIndex/clusterIndices`);
      }
      for (const clusterIndex of attachedIndices) {
        if (!clusterIndices.has(clusterIndex)) {
          throw new Error(`${stimFile} answerable intent node ${nodeId} references unresolved clusterIndex ${clusterIndex}`);
        }
      }
      modeledIntentNodes += 1;
    }
  }
  const unit = asRecord(asArray(asRecord(tdf.tutor, `${tdfFile} tutor`).unit, `${tdfFile} tutor.unit`)[0], `${tdfFile} tutor.unit[0]`);
  const sparcsession = asRecord(unit.sparcsession, `${tdfFile} tutor.unit[0].sparcsession`);
  const listedClusters = parseClusterList(sparcsession.clusterlist);
  for (const clusterIndex of clusterIndices) {
    if (!listedClusters.has(clusterIndex)) {
      throw new Error(`${tdfFile} sparcsession.clusterlist does not include cluster ${clusterIndex}`);
    }
  }
  if (nonBlank(sparcsession.pageId, `${tdfFile} sparcsession.pageId`) !== page.pageId) {
    throw new Error(`${tdfFile} sparcsession.pageId does not match setspec.sparcPages[0].pageId`);
  }
  nonBlank(sparcsession.calculateProbability, `${tdfFile} sparcsession.calculateProbability`);
  return {
    tdfFile,
    stimFile,
    clusters: clusters.length,
    modelPracticeEffects: modelPracticeEffects.length,
    modeledIntentNodes,
  };
}

function main(): void {
  const { packageRoot } = parseArgs(process.argv.slice(2));
  const files = fs.readdirSync(packageRoot);
  const tdfFiles = files.filter((file) => file.endsWith('_TDF.json')).sort();
  if (tdfFiles.length === 0) {
    throw new Error(`No *_TDF.json files found in ${packageRoot}`);
  }
  const reports = tdfFiles.map((tdfFile) => verifyPackageFile(packageRoot, tdfFile));
  const totals = reports.reduce((acc, report) => ({
    tdfFiles: acc.tdfFiles + 1,
    clusters: acc.clusters + report.clusters,
    modelPracticeEffects: acc.modelPracticeEffects + report.modelPracticeEffects,
    modeledIntentNodes: acc.modeledIntentNodes + report.modeledIntentNodes,
  }), {
    tdfFiles: 0,
    clusters: 0,
    modelPracticeEffects: 0,
    modeledIntentNodes: 0,
  });
  console.log(JSON.stringify({
    packageRoot,
    ...totals,
  }, null, 2));
}

main();
