import * as fs from 'node:fs';
import * as path from 'node:path';

type JsonRecord = Record<string, unknown>;

type ScanOptions = {
  sourceRoot: string;
  moduleId?: string;
  allModules: boolean;
  json: boolean;
  allowIssues: boolean;
};

type ConversionStatus = 'converted' | 'unsupported-blocking' | 'needs-review';

type TypeExample = {
  file: string;
  path: string;
  keys: string[];
  text: string;
};

const missingPageWarnings: CoverageIssue[] = [];

type CoverageIssue = {
  severity: 'error' | 'warn';
  kind: 'missing-activity-file' | 'missing-page-file' | 'unclassified-type' | 'unhandled-type' | 'untraversed-content-field' | 'unknown-rich-text-mark' | 'unhandled-activity-shape';
  type?: string;
  file: string;
  path: string;
  detail: string;
  text: string;
};

type IssueSummary = {
  kind: CoverageIssue['kind'];
  count: number;
};

function contentRootFor(sourceRoot: string): string {
  const normalizedRoot = path.join(sourceRoot, 'raw');
  const normalizedHierarchy = path.join(normalizedRoot, '_hierarchy.json');
  const flatHierarchy = path.join(sourceRoot, '_hierarchy.json');
  if (fs.existsSync(normalizedHierarchy)) {
    return normalizedRoot;
  }
  if (fs.existsSync(flatHierarchy)) {
    return sourceRoot;
  }
  throw new Error(`No OLI hierarchy found. Expected ${normalizedHierarchy} or ${flatHierarchy}.`);
}

const DIRECT_CONVERTER_TYPES = new Set([
  'activity-reference',
  'group',
  'alternatives',
  'alternative',
  'img',
  'p',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'ul',
  'ol',
  'code',
  'table',
  'formula',
  'callout',
  'definition',
  'iframe',
  'img_inline',
  'page_link',
  'popup',
  'title',
  'TargetedCATA',
  'youtube',
]);

const RICH_HTML_TYPES = new Set([
  'a',
  'break',
  'code',
  'content',
  'formula',
  'formula_inline',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'img',
  'input_ref',
  'li',
  'meaning',
  'ol',
  'p',
  'table',
  'td',
  'text',
  'th',
  'tr',
  'ul',
]);

const CONTAINER_TYPES = new Set([
  'Activity',
  'Hierarchy',
  'Manifest',
  'MediaManifest',
  'Page',
  'container',
  'item',
]);

const CONVERTED_TYPES = new Set([
  ...DIRECT_CONVERTER_TYPES,
  ...RICH_HTML_TYPES,
  ...CONTAINER_TYPES,
]);

const REVIEW_REQUIRED_TYPES = new Set<string>();

const HANDLED_ACTIVITY_SHAPES = new Set([
  'multiple-choice',
  'multi-input-dropdown',
  'multi-input-text',
  'short-answer',
  'targeted-cata',
]);

const HANDLED_RICH_TEXT_MARKS = new Set([
  'code',
  'em',
  'strong',
  'sub',
  'subscript',
  'sup',
  'superscript',
  'underline',
]);

const STRUCTURAL_KEYS = new Set([
  'activity_id',
  'alt',
  'alternatives_id',
  'authoring',
  'bibrefs',
  'caption',
  'children',
  'choices',
  'code',
  'collabSpace',
  'content',
  'controls',
  'correct',
  'count',
  'editor',
  'explanation',
  'feedback',
  'height',
  'href',
  'id',
  'idref',
  'input',
  'inputType',
  'inputs',
  'internal',
  'isGraded',
  'language',
  'layout',
  'logic',
  'meanings',
  'model',
  'objectives',
  'originalFile',
  'partId',
  'purpose',
  'relatesTo',
  'responses',
  'rule',
  'scope',
  'score',
  'selection',
  'shuffle',
  'src',
  'strategy',
  'style',
  'subType',
  'subtype',
  'tags',
  'target',
  'targeted',
  'term',
  'text',
  'textDirection',
  'title',
  'transformations',
  'translations',
  'type',
  'unresolvedReferences',
  'url',
  'value',
  'version',
  'vertical-align',
  'width',
]);

function isRecord(value: unknown): value is JsonRecord {
  return Boolean(value) && typeof value === 'object' && !Array.isArray(value);
}

function optionalText(value: unknown): string {
  if (typeof value === 'string') {
    return value.trim();
  }
  if (typeof value === 'number' && Number.isFinite(value)) {
    return String(value);
  }
  return '';
}

function readJson(filePath: string): JsonRecord {
  return JSON.parse(fs.readFileSync(filePath, 'utf8')) as JsonRecord;
}

function textOf(value: unknown): string {
  if (value === null || value === undefined) {
    return '';
  }
  if (typeof value === 'string') {
    return value;
  }
  if (Array.isArray(value)) {
    return value.map(textOf).join(' ');
  }
  if (!isRecord(value)) {
    return '';
  }
  const parts: string[] = [];
  if (typeof value.text === 'string') {
    parts.push(value.text);
  }
  if (optionalText(value.type) === 'code' && typeof value.code === 'string') {
    parts.push(value.code);
  }
  for (const key of ['content', 'children', 'caption', 'feedback', 'hints', 'explanation', 'meanings', 'term', 'translations']) {
    if (key in value) {
      parts.push(textOf(value[key]));
    }
  }
  return parts.join(' ').replace(/\s+/g, ' ').trim();
}

function walkFiles(root: string): string[] {
  const out: string[] = [];
  for (const entry of fs.readdirSync(root, { withFileTypes: true })) {
    const fullPath = path.join(root, entry.name);
    if (entry.isDirectory()) {
      out.push(...walkFiles(fullPath));
    } else if (entry.isFile() && entry.name.endsWith('.json')) {
      out.push(fullPath);
    }
  }
  return out;
}

function collectModuleFiles(sourceRoot: string, moduleId: string): string[] {
  const contentRoot = contentRootFor(sourceRoot);
  const hierarchy = readJson(path.join(contentRoot, '_hierarchy.json'));
  const modules = Array.isArray(hierarchy.children) ? hierarchy.children.filter(isRecord) : [];
  const moduleNode = modules.find((candidate) => candidate.id === moduleId);
  if (!moduleNode) {
    throw new Error(`Module ${moduleId} not found in ${sourceRoot}`);
  }
  const pageIds = (Array.isArray(moduleNode.children) ? moduleNode.children.filter(isRecord) : [])
    .filter((child) => child.type === 'item')
    .map((child) => optionalText(child.idref))
    .filter(Boolean);
  const rawJsonFiles = walkFiles(contentRoot);
  const pageFileById = new Map<string, string>();
  for (const file of rawJsonFiles) {
    if (file.includes(`${path.sep}referenced-activities${path.sep}`)) {
      continue;
    }
    if (file.endsWith(`${path.sep}_hierarchy.json`) || file.endsWith(`${path.sep}_project.json`) || file.endsWith(`${path.sep}_media-manifest.json`)) {
      continue;
    }
    pageFileById.set(path.basename(file, '.json'), file);
  }
  const files = pageIds.map((pageId) => {
    const file = pageFileById.get(pageId);
    if (!file) {
      missingPageWarnings.push({
        severity: 'warn',
        kind: 'missing-page-file',
        file: path.relative(sourceRoot, path.join(contentRoot, '_hierarchy.json')).replaceAll('\\', '/'),
        path: `$[module=${moduleId}][page=${pageId}]`,
        detail: `Page ${pageId} from module ${moduleId} is listed in the hierarchy but was not found in the extracted raw files.`,
        text: '',
      });
      return '';
    }
    return file;
  }).filter(Boolean);
  const activityPageIds = new Map<string, Set<string>>();
  for (const file of files) {
    const page = readJson(file);
    const activityIds = new Set<string>();
    collectActivityRefs(page, activityIds);
    const pageId = path.basename(file, '.json');
    for (const activityId of activityIds) {
      if (!activityPageIds.has(activityId)) {
        activityPageIds.set(activityId, new Set());
      }
      activityPageIds.get(activityId)?.add(pageId);
    }
  }
  for (const [activityId, referencingPageIds] of activityPageIds.entries()) {
    const nestedActivity = path.join(contentRoot, 'referenced-activities', `${activityId}.json`);
    const flatActivity = path.join(contentRoot, `${activityId}.json`);
    if (fs.existsSync(nestedActivity)) {
      files.push(nestedActivity);
    } else if (fs.existsSync(flatActivity)) {
      files.push(flatActivity);
    } else {
      missingPageWarnings.push({
        severity: 'error',
        kind: 'missing-activity-file',
        file: path.relative(sourceRoot, path.join(contentRoot, '_hierarchy.json')).replaceAll('\\', '/'),
        path: `$[module=${moduleId}][pages=${[...referencingPageIds].join(',')}][activity=${activityId}]`,
        detail: `Activity ${activityId} is referenced by module ${moduleId} page(s) ${[...referencingPageIds].join(', ')} but was not found in the extracted OLI files.`,
        text: '',
      });
    }
  }
  return files.filter((file) => fs.existsSync(file));
}

function collectActivityRefs(value: unknown, activityIds: Set<string>): void {
  if (Array.isArray(value)) {
    value.forEach((item) => collectActivityRefs(item, activityIds));
    return;
  }
  if (!isRecord(value)) {
    return;
  }
  if (value.type === 'activity-reference') {
    const activityId = optionalText(value.activity_id);
    if (activityId) {
      activityIds.add(activityId);
    }
  }
  for (const child of Object.values(value)) {
    collectActivityRefs(child, activityIds);
  }
}

function allModuleIds(sourceRoot: string): string[] {
  const contentRoot = contentRootFor(sourceRoot);
  const hierarchy = readJson(path.join(contentRoot, '_hierarchy.json'));
  return (Array.isArray(hierarchy.children) ? hierarchy.children.filter(isRecord) : [])
    .filter((candidate) => candidate.type === 'container')
    .map((candidate) => optionalText(candidate.id))
    .filter(Boolean);
}

function parseArgs(argv: string[]): ScanOptions {
  const scriptDir = path.dirname(path.resolve(process.argv[1] || ''));
  const repoRoot = path.resolve(scriptDir, '..');
  const options: ScanOptions = {
    sourceRoot: path.join(repoRoot, 'extracted_intro_to_stats_first_three_modules_l71p6'),
    moduleId: '97146',
    allModules: false,
    json: false,
    allowIssues: false,
  };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === '--source-root') {
      options.sourceRoot = path.resolve(argv[++index] || '');
    } else if (arg === '--module-id') {
      options.moduleId = argv[++index] || '';
      options.allModules = false;
    } else if (arg === '--all-modules') {
      options.allModules = true;
      options.moduleId = undefined;
    } else if (arg === '--json') {
      options.json = true;
    } else if (arg === '--allow-issues') {
      options.allowIssues = true;
    } else if (arg === '--help' || arg === '-h') {
      printHelp();
      process.exit(0);
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }
  return options;
}

function printHelp(): void {
  console.log(`Usage:
  node --experimental-strip-types scripts/scan_oli_converter_coverage.ts [options]

Options:
  --source-root <path>   Extracted OLI export root.
  --module-id <id>      Scan one hierarchy module/container. Default: 97146.
  --all-modules         Scan all hierarchy modules in the extracted export.
  --json                Print full JSON report.
  --allow-issues        Exit 0 even when coverage/source issues are found.
`);
}

function activityShape(activity: JsonRecord): string {
  const content = isRecord(activity.content) ? activity.content : {};
  if (content.type === 'TargetedCATA') {
    return 'targeted-cata';
  }
  if (Array.isArray(content.inputs) && content.inputs.length > 0 && content.inputs.filter(isRecord).every((input) => Array.isArray(input.choiceIds))) {
    return 'multi-input-dropdown';
  }
  if (Array.isArray(content.inputs) && content.inputs.length > 0) {
    return 'multi-input-text';
  }
  if (Array.isArray(content.choices)) {
    return 'multiple-choice';
  }
  if (optionalText(content.inputType) === 'textarea' || optionalText(activity.subType) === 'oli_short_answer') {
    return 'short-answer';
  }
  return `unknown:${optionalText(content.type) || optionalText(activity.subType) || 'activity'}`;
}

function hasContent(value: unknown): boolean {
  return Boolean(textOf(value));
}

function conversionStatusForType(type: string): ConversionStatus {
  if (CONVERTED_TYPES.has(type)) {
    return 'converted';
  }
  if (REVIEW_REQUIRED_TYPES.has(type)) {
    return 'needs-review';
  }
  return 'unsupported-blocking';
}

function converterTraversedKeys(type: string): Set<string> {
  if (type === 'Activity') {
    return new Set(['content']);
  }
  if (type === 'Page') {
    return new Set(['content']);
  }
  if (type === 'content') {
    return new Set(['children']);
  }
  if (type === 'definition') {
    return new Set(['children', 'meanings', 'term']);
  }
  if (type === 'meaning') {
    return new Set(['children', 'content']);
  }
  if (type === 'code') {
    return new Set(['children', 'code', 'caption']);
  }
  if (type === 'iframe' || type === 'youtube') {
    return new Set(['children', 'caption', 'src']);
  }
  if (type === 'page_link') {
    return new Set(['children', 'idref']);
  }
  if (type === 'popup') {
    return new Set(['children', 'content', 'trigger']);
  }
  if (type === 'text') {
    return new Set(['text']);
  }
  if (type === 'img') {
    return new Set(['caption']);
  }
  if (RICH_HTML_TYPES.has(type) || DIRECT_CONVERTER_TYPES.has(type)) {
    return new Set(['content', 'children', 'caption', 'code']);
  }
  return new Set(['children']);
}

function scanNode(params: {
  value: unknown;
  file: string;
  nodePath: string;
  typeCounts: Map<string, number>;
  examples: Map<string, TypeExample>;
  issues: CoverageIssue[];
  richMarks: Map<string, number>;
}): void {
  const { value, file, nodePath, typeCounts, examples, issues, richMarks } = params;
  if (Array.isArray(value)) {
    value.forEach((child, index) => scanNode({ ...params, value: child, nodePath: `${nodePath}.${index}` }));
    return;
  }
  if (!isRecord(value)) {
    return;
  }

  const type = optionalText(value.type);
  if (type) {
    typeCounts.set(type, (typeCounts.get(type) || 0) + 1);
    if (!examples.has(type)) {
      examples.set(type, {
        file,
        path: nodePath,
        keys: Object.keys(value).sort(),
        text: textOf(value).slice(0, 220),
      });
    }
    const status = conversionStatusForType(type);
    if (status !== 'converted') {
      issues.push({
        severity: status === 'unsupported-blocking' ? 'error' : 'warn',
        kind: status === 'unsupported-blocking' ? 'unclassified-type' : 'unhandled-type',
        type,
        file,
        path: nodePath,
        detail: status === 'unsupported-blocking'
          ? `OLI type "${type}" is not classified by the converter coverage standard.`
          : `OLI type "${type}" requires an explicit converter representation or user approval.`,
        text: textOf(value).slice(0, 220),
      });
    }
  }

  if (type === 'Activity') {
    const shape = activityShape(value);
    if (!HANDLED_ACTIVITY_SHAPES.has(shape)) {
      issues.push({
        severity: 'error',
        kind: 'unhandled-activity-shape',
        type,
        file,
        path: nodePath,
        detail: `Converter does not handle activity shape "${shape}".`,
        text: textOf(value).slice(0, 220),
      });
    }
  }

  for (const [key, child] of Object.entries(value)) {
    if (typeof value.text === 'string' && typeof child === 'boolean' && child === true && !STRUCTURAL_KEYS.has(key)) {
      richMarks.set(key, (richMarks.get(key) || 0) + 1);
      if (!HANDLED_RICH_TEXT_MARKS.has(key)) {
        issues.push({
          severity: 'warn',
          kind: 'unknown-rich-text-mark',
          type,
          file,
          path: `${nodePath}.${key}`,
          detail: `Rich text mark "${key}" is not in the converter mark allow-list.`,
          text: textOf(value).slice(0, 220),
        });
      }
    }
  }

  if (type) {
    const traversed = converterTraversedKeys(type);
    for (const [key, child] of Object.entries(value)) {
      if (STRUCTURAL_KEYS.has(key) && !traversed.has(key) && hasContent(child) && ['children', 'content', 'caption', 'code', 'meanings', 'term', 'translations'].includes(key)) {
        issues.push({
          severity: key === 'meanings' || key === 'term' ? 'warn' : 'error',
          kind: 'untraversed-content-field',
          type,
          file,
          path: `${nodePath}.${key}`,
          detail: `Content-bearing field "${key}" on type "${type}" is not traversed by the converter's current type handling.`,
          text: textOf(child).slice(0, 220),
        });
      }
    }
  }

  for (const [key, child] of Object.entries(value)) {
    scanNode({ ...params, value: child, nodePath: `${nodePath}.${key}` });
  }
}

function summarizeIssues(issues: CoverageIssue[]): IssueSummary[] {
  const counts = new Map<CoverageIssue['kind'], number>();
  for (const issue of issues) {
    counts.set(issue.kind, (counts.get(issue.kind) || 0) + 1);
  }
  return [...counts.entries()]
    .sort((left, right) => left[0].localeCompare(right[0]))
    .map(([kind, count]) => ({ kind, count }));
}

function main(): void {
  const options = parseArgs(process.argv.slice(2));
  const sourceRoot = path.resolve(options.sourceRoot);
  const moduleIds = options.allModules ? allModuleIds(sourceRoot) : [options.moduleId || '97146'];
  const files = [...new Set(moduleIds.flatMap((moduleId) => collectModuleFiles(sourceRoot, moduleId)))];
  const typeCounts = new Map<string, number>();
  const examples = new Map<string, TypeExample>();
  const issues: CoverageIssue[] = [];
  const richMarks = new Map<string, number>();

  for (const file of files) {
    const json = readJson(file);
    scanNode({
      value: json,
      file: path.relative(sourceRoot, file).replaceAll('\\', '/'),
      nodePath: '$',
      typeCounts,
      examples,
      issues,
      richMarks,
    });
  }

  const report = {
    sourceRoot,
    moduleIds,
    filesScanned: files.length,
      typeInventory: [...typeCounts.entries()].sort((left, right) => left[0].localeCompare(right[0])).map(([type, count]) => ({
      type,
      count,
      handled: conversionStatusForType(type) === 'converted',
      status: conversionStatusForType(type),
      example: examples.get(type),
    })),
    richTextMarks: [...richMarks.entries()].sort((left, right) => left[0].localeCompare(right[0])).map(([mark, count]) => ({
      mark,
      count,
      handled: HANDLED_RICH_TEXT_MARKS.has(mark),
    })),
    issues: [...missingPageWarnings, ...issues],
  };
  const issueSummary = summarizeIssues(report.issues);
  const converterIssues = report.issues.filter((issue) => issue.kind !== 'missing-page-file');
  const missingPageIssues = report.issues.filter((issue) => issue.kind === 'missing-page-file');

  if (options.json) {
    console.log(JSON.stringify({ ...report, issueSummary }, null, 2));
    if (report.issues.length > 0 && !options.allowIssues) {
      process.exitCode = 1;
    }
    return;
  }

  console.log(`OLI converter coverage scan`);
  console.log(`Source: ${sourceRoot}`);
  console.log(`Modules: ${moduleIds.join(', ')}`);
  console.log(`Files scanned: ${files.length}`);
  console.log(`Types found: ${report.typeInventory.length}`);
  console.log(`Issues: ${report.issues.length}`);
  if (issueSummary.length > 0) {
    console.log(`Issue summary: ${issueSummary.map((entry) => `${entry.kind}=${entry.count}`).join(', ')}`);
  }
  const primaryIssues = [...converterIssues, ...missingPageIssues.slice(0, 5)];
  for (const issue of primaryIssues.slice(0, 80)) {
    console.log(`- [${issue.severity}] ${issue.kind}: ${issue.detail}`);
    console.log(`  ${issue.file}${issue.path} ${issue.text ? `=> ${issue.text}` : ''}`);
  }
  if (missingPageIssues.length > 5) {
    console.log(`... ${missingPageIssues.length - 5} more missing page warnings from the hierarchy. Use --json for the full report.`);
  }
  if (converterIssues.length > 80) {
    console.log(`... ${converterIssues.length - 80} more converter coverage issues. Use --json for the full report.`);
  }
  if (report.issues.length > 0 && !options.allowIssues) {
    process.exitCode = 1;
  }
}

main();
