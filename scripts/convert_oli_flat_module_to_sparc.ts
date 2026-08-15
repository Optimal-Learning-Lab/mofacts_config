import * as fs from 'node:fs';
import * as path from 'node:path';
import { execFileSync } from 'node:child_process';

type JsonRecord = Record<string, unknown>;

type ConversionContext = {
  sourceRoot: string;
  moduleId: string;
  moduleNumber?: number;
  outputRoot: string;
  auditRoot: string;
  lessonName: string;
  sparcPageId: string;
  stimulusFile: string;
  tdfFile: string;
  calculateProbability: string;
};

type CliOptions = {
  sourceRoot: string;
  moduleId: string;
  allModules: boolean;
  outputRoot: string;
  lessonPrefix: string;
  zip: boolean;
  calculateProbability: string;
};

type ConversionResult = {
  tdf: JsonRecord;
  stimuli: JsonRecord;
  conversionNotes: JsonRecord;
};

type MissingReference = {
  moduleId: string;
  moduleTitle: string;
  moduleNumber: number;
  pageId?: string;
  activityId?: string;
  kind: 'page' | 'activity';
};

type SparcModelTarget = {
  clusterIndex: number;
  clusterKC: string;
  stimulusKC: string;
  label: string;
  activityId: string;
  partId: string;
  inputId?: string;
  objectives: string[];
  pageId: string;
};

type SparcModelTargetRegistry = {
  targets: SparcModelTarget[];
  byKey: Map<string, SparcModelTarget>;
};

type ModelTargetParams = {
  activity: JsonRecord;
  activityId: string;
  part: JsonRecord;
  pageId: string;
  moduleSlug: string;
  label?: string;
  inputId?: string;
};

const DEFAULT_SPARC_CALCULATE_PROBABILITY = 'p.y = -0.77 + .665 * pFunc.logitdec( p.overallOutcomeHistory.slice( Math.max(p.overallOutcomeHistory.length-60, 0),  p.overallOutcomeHistory.length),  .966)+ .51* (p.stimSuccessCount) + 11.1 * pFunc.recency(p.stimSecsSinceLastShown, .443) ; p.probability = 1.0 / (1.0 + Math.exp(-p.y)); return p';

const COVERED_OLI_TYPES = new Set([
  'Activity',
  'Page',
  'TargetedCATA',
  'a',
  'activity-reference',
  'alternative',
  'alternatives',
  'break',
  'callout',
  'code',
  'content',
  'definition',
  'formula',
  'formula_inline',
  'group',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'iframe',
  'img',
  'img_inline',
  'input_ref',
  'li',
  'meaning',
  'ol',
  'p',
  'page_link',
  'popup',
  'table',
  'td',
  'text',
  'th',
  'title',
  'tr',
  'ul',
  'youtube',
]);

const COVERED_RICH_TEXT_MARKS = new Set([
  'code',
  'em',
  'strong',
  'sub',
  'subscript',
  'sup',
  'superscript',
  'underline',
]);

const NON_MARK_KEYS = new Set([
  'activity_id',
  'alt',
  'alternatives_id',
  'authoring',
  'bibrefs',
  'caption',
  'children',
  'choices',
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
  'trigger',
  'type',
  'unresolvedReferences',
  'url',
  'value',
  'version',
  'vertical-align',
  'width',
]);

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

function walkJsonFiles(root: string): string[] {
  const out: string[] = [];
  for (const entry of fs.readdirSync(root, { withFileTypes: true })) {
    const fullPath = path.join(root, entry.name);
    if (entry.isDirectory()) {
      out.push(...walkJsonFiles(fullPath));
    } else if (entry.isFile() && entry.name.endsWith('.json')) {
      out.push(fullPath);
    }
  }
  return out;
}

function buildJsonFileIndex(contentRoot: string): Map<string, string> {
  const index = new Map<string, string>();
  for (const file of walkJsonFiles(contentRoot)) {
    const baseName = path.basename(file, '.json');
    if (baseName.startsWith('_')) {
      continue;
    }
    index.set(baseName, file);
  }
  return index;
}

function hierarchyModules(sourceRoot: string): JsonRecord[] {
  const contentRoot = contentRootFor(sourceRoot);
  const hierarchy = readJson(path.join(contentRoot, '_hierarchy.json'));
  return asArray(hierarchy.children, '_hierarchy.children')
    .filter(isRecord)
    .filter((child) => child.type === 'container');
}

function allModuleIds(sourceRoot: string): string[] {
  return hierarchyModules(sourceRoot)
    .map((child) => nonBlank(child.id, 'module.id'));
}

function moduleTitle(sourceRoot: string, moduleId: string): string {
  const moduleNode = hierarchyModules(sourceRoot).find((child) => child.id === moduleId);
  if (!moduleNode) {
    throw new Error(`Module ${moduleId} not found`);
  }
  return nonBlank(moduleNode.title, 'module.title');
}

function modulePageIds(sourceRoot: string, moduleId: string): string[] {
  const moduleNode = hierarchyModules(sourceRoot).find((child) => child.id === moduleId);
  if (!moduleNode) {
    throw new Error(`Module ${moduleId} not found`);
  }
  return asArray(moduleNode.children, 'module.children')
    .filter(isRecord)
    .filter((child) => child.type === 'item')
    .map((child) => nonBlank(child.idref, 'module child idref'));
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

function preflightModuleReferences(sourceRoot: string, moduleId: string, moduleNumber: number): MissingReference[] {
  const contentRoot = contentRootFor(sourceRoot);
  const fileIndex = buildJsonFileIndex(contentRoot);
  const title = moduleTitle(sourceRoot, moduleId);
  const missing: MissingReference[] = [];
  for (const pageId of modulePageIds(sourceRoot, moduleId)) {
    const pagePath = fileIndex.get(pageId);
    if (!pagePath) {
      missing.push({ moduleId, moduleTitle: title, moduleNumber, pageId, kind: 'page' });
      continue;
    }
    const page = readJson(pagePath);
    const activityIds = new Set<string>();
    collectActivityRefs(page, activityIds);
    for (const activityId of activityIds) {
      if (!fileIndex.has(activityId)) {
        missing.push({ moduleId, moduleTitle: title, moduleNumber, pageId, activityId, kind: 'activity' });
      }
    }
  }
  return missing;
}

function assertPreflightReferences(sourceRoot: string, moduleIds: string[]): void {
  const missing = moduleIds.flatMap((moduleId, index) => preflightModuleReferences(sourceRoot, moduleId, index + 1));
  const missingPages = missing.filter((entry) => entry.kind === 'page');
  const missingActivities = missing.filter((entry) => entry.kind === 'activity');
  for (const entry of missingActivities) {
    const moduleLabel = `Module ${String(entry.moduleNumber).padStart(2, '0')} ${entry.moduleTitle} (${entry.moduleId})`;
    console.warn(`Missing OLI activity will be rendered as diagnostic content: ${moduleLabel}, page ${entry.pageId}, activity ${entry.activityId}`);
  }
  if (missingPages.length === 0) {
    return;
  }
  const lines = missingPages.map((entry) => {
    const moduleLabel = `Module ${String(entry.moduleNumber).padStart(2, '0')} ${entry.moduleTitle} (${entry.moduleId})`;
    return `- ${moduleLabel}: missing page ${entry.pageId}`;
  });
  throw new Error(`Cannot convert OLI export because required page files are missing:\n${lines.join('\n')}`);
}

function isRecord(value: unknown): value is JsonRecord {
  return Boolean(value) && typeof value === 'object' && !Array.isArray(value);
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

function readJson(filePath: string): JsonRecord {
  return asRecord(JSON.parse(fs.readFileSync(filePath, 'utf8')), filePath);
}

function assertCoveredOliNodes(value: unknown, file: string, nodePath = '$'): void {
  if (Array.isArray(value)) {
    value.forEach((child, index) => assertCoveredOliNodes(child, file, `${nodePath}.${index}`));
    return;
  }
  if (!isRecord(value)) {
    return;
  }
  const type = optionalText(value.type);
  if (type && !COVERED_OLI_TYPES.has(type)) {
    throw new Error(`Unsupported OLI type "${type}" at ${file}${nodePath}. Add a converter representation or get explicit user approval.`);
  }
  if (typeof value.text === 'string') {
    for (const [key, child] of Object.entries(value)) {
      if (typeof child === 'boolean' && child === true && !NON_MARK_KEYS.has(key) && !COVERED_RICH_TEXT_MARKS.has(key)) {
        throw new Error(`Unsupported OLI rich-text mark "${key}" at ${file}${nodePath}.${key}. Add a converter representation or get explicit user approval.`);
      }
    }
  }
  for (const [key, child] of Object.entries(value)) {
    assertCoveredOliNodes(child, file, `${nodePath}.${key}`);
  }
}

function writeJson(filePath: string, value: unknown): void {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(`${filePath}.tmp`, `${JSON.stringify(value, null, 2)}\n`, 'utf8');
  fs.renameSync(`${filePath}.tmp`, filePath);
}

function slug(value: string): string {
  return value.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
}

function safeFileName(value: string): string {
  return value.replace(/[<>:"/\\|?*]+/g, ' ').replace(/\s+/g, ' ').trim();
}

function createModelTargetRegistry(): SparcModelTargetRegistry {
  return {
    targets: [],
    byKey: new Map<string, SparcModelTarget>(),
  };
}

function targetKey(params: ModelTargetParams): string {
  return [
    params.moduleSlug,
    params.activityId,
    nonBlank(params.part.id, 'part.id'),
    params.inputId || '',
  ].join('|');
}

function partObjectives(part: JsonRecord): string[] {
  return asArray(part.objectives ?? [], 'part.objectives')
    .map((value) => String(value).trim())
    .filter(Boolean);
}

function modelTargetKc(params: ModelTargetParams): string {
  const partId = slug(nonBlank(params.part.id, 'part.id'));
  const inputSuffix = params.inputId && slug(params.inputId) !== partId
    ? `.${slug(params.inputId)}`
    : '';
  return `intro-stats.${params.moduleSlug}.${slug(params.activityId)}.${partId}${inputSuffix}`;
}

function ensureModelTarget(
  registry: SparcModelTargetRegistry,
  params: ModelTargetParams,
): SparcModelTarget {
  const key = targetKey(params);
  const existing = registry.byKey.get(key);
  if (existing) {
    return existing;
  }
  const clusterKC = modelTargetKc(params);
  const target: SparcModelTarget = {
    clusterIndex: registry.targets.length,
    clusterKC,
    stimulusKC: clusterKC,
    label: params.label || optionalText(params.activity.title) || params.activityId,
    activityId: params.activityId,
    partId: nonBlank(params.part.id, 'part.id'),
    ...(params.inputId ? { inputId: params.inputId } : {}),
    objectives: partObjectives(params.part),
    pageId: params.pageId,
  };
  registry.targets.push(target);
  registry.byKey.set(key, target);
  return target;
}

function clusterListForTargets(targets: SparcModelTarget[]): string {
  if (targets.length === 0) {
    throw new Error('SPARC conversion produced no model targets.');
  }
  return targets.length === 1 ? '0' : `0-${targets.length - 1}`;
}

function ensureContentCompletionTarget(params: {
  registry: SparcModelTargetRegistry;
  moduleId: string;
  moduleSlug: string;
  moduleTitle: string;
  pageId: string;
}): SparcModelTarget {
  return ensureModelTarget(params.registry, {
    activity: {
      id: params.moduleId,
      title: params.moduleTitle,
    },
    activityId: params.moduleId,
    part: {
      id: 'content-completion',
      objectives: [],
    },
    pageId: params.pageId,
    moduleSlug: params.moduleSlug,
    label: `${params.moduleTitle} Content Completion`,
  });
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function normalizeYouTubeEmbedSrc(rawSrc: unknown): string {
  const src = optionalText(rawSrc);
  if (!src) {
    return '';
  }
  const videoIdPattern = /^[A-Za-z0-9_-]{11}$/;
  let videoId = src.trim().split(/[?&#/]/)[0] || '';
  try {
    const url = new URL(src);
    const host = url.hostname.toLowerCase().replace(/^www\./, '');
    if (host === 'youtu.be') {
      videoId = url.pathname.replace(/^\//, '').split(/[?&#/]/)[0] || '';
    } else if (host === 'youtube.com' || host === 'youtube-nocookie.com' || host.endsWith('.youtube.com')) {
      videoId = url.searchParams.get('v') || '';
      if (!videoId) {
        videoId = url.pathname.match(/^\/(?:embed|shorts|live)\/([^/?#]+)/)?.[1] || '';
      }
      videoId = videoId.split(/[?&#/]/)[0] || '';
    }
  } catch (_error) {
    // Bare OLI YouTube ids are expected and handled below.
  }
  if (!videoIdPattern.test(videoId)) {
    throw new Error(`OLI youtube node requires a valid YouTube video id or URL; received "${src}"`);
  }
  return `https://www.youtube-nocookie.com/embed/${videoId}`;
}

function richTextToPlainText(value: unknown): string {
  if (value === null || value === undefined) {
    return '';
  }
  if (typeof value === 'string') {
    return value;
  }
  if (Array.isArray(value)) {
    return value.map(richTextToPlainText).join('');
  }
  if (!isRecord(value)) {
    return '';
  }
  if (typeof value.text === 'string') {
    return value.text;
  }
  if (optionalText(value.type) === 'code' && typeof value.code === 'string') {
    return value.code;
  }
  const parts: string[] = [];
  for (const key of ['content', 'children', 'caption', 'meanings', 'term', 'trigger']) {
    if (Array.isArray(value[key])) {
      parts.push(richTextToPlainText(value[key]));
    } else if (typeof value[key] === 'string') {
      parts.push(String(value[key]));
    }
  }
  return parts.join('');
}

function inputReferenceIds(value: unknown): string[] {
  if (Array.isArray(value)) {
    return value.flatMap(inputReferenceIds);
  }
  if (!isRecord(value)) {
    return [];
  }
  if (optionalText(value.type) === 'input_ref') {
    return [nonBlank(value.input ?? value.id, 'input_ref input')];
  }
  return Object.values(value).flatMap((child) => (
    child && typeof child === 'object' ? inputReferenceIds(child) : []
  ));
}

function wrapInlineHtml(node: JsonRecord, content: string): string {
  let html = content;
  if (node.strong === true) {
    html = `<strong>${html}</strong>`;
  }
  if (node.em === true) {
    html = `<em>${html}</em>`;
  }
  if (node.underline === true) {
    html = `<u>${html}</u>`;
  }
  if (node.code === true) {
    html = `<code>${html}</code>`;
  }
  if (node.subscript === true || node.sub === true) {
    html = `<sub>${html}</sub>`;
  }
  if (node.superscript === true || node.sup === true) {
    html = `<sup>${html}</sup>`;
  }
  return html;
}

function richTextToHtml(value: unknown): string {
  if (value === null || value === undefined) {
    return '';
  }
  if (typeof value === 'string') {
    return escapeHtml(value);
  }
  if (Array.isArray(value)) {
    return value.map(richTextToHtml).join('');
  }
  if (!isRecord(value)) {
    return '';
  }
  if (typeof value.text === 'string') {
    return wrapInlineHtml(value, escapeHtml(value.text));
  }
  const type = optionalText(value.type);
  if (type === 'code' && typeof value.code === 'string') {
    const caption = richTextToHtml(value.caption).trim();
    return `<figure><pre><code>${escapeHtml(value.code)}</code></pre>${caption ? `<figcaption>${caption}</figcaption>` : ''}</figure>`;
  }
  const childHtml = Array.isArray(value.children) ? richTextToHtml(value.children) : '';
  if (type === 'p') {
    return `<p>${childHtml}</p>`;
  }
  if (['h1', 'h2', 'h3', 'h4', 'h5'].includes(type)) {
    return `<${type}>${childHtml}</${type}>`;
  }
  if (type === 'code') {
    const caption = richTextToHtml(value.caption).trim();
    return `<figure><pre><code>${childHtml}</code></pre>${caption ? `<figcaption>${caption}</figcaption>` : ''}</figure>`;
  }
  if (type === 'break') {
    return '<br>';
  }
  if (type === 'ul' || type === 'ol') {
    const items = Array.isArray(value.children) ? value.children.filter(isRecord) : [];
    return `<${type}>${items.map((item) => `<li>${richTextToHtml(item)}</li>`).join('')}</${type}>`;
  }
  if (type === 'table') {
    return `<table>${childHtml}</table>`;
  }
  if (type === 'tr') {
    return `<tr>${childHtml}</tr>`;
  }
  if (type === 'td' || type === 'th') {
    return `<${type}>${childHtml}</${type}>`;
  }
  if (type === 'formula' || type === 'formula_inline') {
    const src = optionalText(value.src);
    if (!src) {
      return childHtml;
    }
    const html = `<img src="${escapeHtml(src)}" alt="">`;
    return type === 'formula_inline' ? html : `<figure>${html}</figure>`;
  }
  if (type === 'a') {
    const href = optionalText(value.url ?? value.href);
    const safeHref = href ? ` href="${escapeHtml(href)}" target="_blank" rel="noopener noreferrer"` : '';
    return `<a${safeHref}>${childHtml}</a>`;
  }
  if (type === 'img' || type === 'img_inline') {
    const src = optionalText(value.src);
    const alt = optionalText(value.alt) || richTextToPlainText(value.caption).trim();
    if (!src) {
      return '';
    }
    const caption = richTextToHtml(value.caption).trim() || (alt ? escapeHtml(alt) : '');
    const image = `<img src="${escapeHtml(src)}" alt="${escapeHtml(alt)}" loading="lazy">`;
    return type === 'img_inline' ? image : `<figure>${image}${caption ? `<figcaption>${caption}</figcaption>` : ''}</figure>`;
  }
  if (type === 'definition') {
    const term = richTextToHtml(value.term).trim();
    const meanings = Array.isArray(value.meanings) ? value.meanings.map(richTextToHtml).filter(Boolean) : [];
    const body = meanings.length > 0 ? meanings.join('') : childHtml;
    return `<section class="oli-definition">${term ? `<h5>${term}</h5>` : ''}${body}</section>`;
  }
  if (type === 'meaning') {
    return childHtml || richTextToHtml(value.content);
  }
  if (type === 'title') {
    return `<h5>${childHtml}</h5>`;
  }
  if (type === 'callout') {
    return `<aside class="oli-callout">${childHtml}</aside>`;
  }
  if (type === 'page_link') {
    const label = childHtml || escapeHtml(optionalText(value.idref) || 'Linked page');
    const idref = optionalText(value.idref);
    return `<a data-oli-page-link="${escapeHtml(idref)}" href="#${escapeHtml(idref)}">${label}</a>`;
  }
  if (type === 'popup') {
    const trigger = richTextToHtml(value.trigger).trim() || 'More';
    const content = richTextToHtml(value.content).trim() || childHtml;
    return `<details class="oli-popup"><summary>${trigger}</summary>${content}</details>`;
  }
  if (type === 'youtube' || type === 'iframe') {
    const src = type === 'youtube' ? normalizeYouTubeEmbedSrc(value.src) : optionalText(value.src);
    const caption = richTextToHtml(value.caption).trim() || childHtml;
    if (!src) {
      return caption;
    }
    const width = optionalText(value.width) || '100%';
    const height = optionalText(value.height) || '360';
    const title = caption ? richTextToPlainText(value.caption).trim() : type;
    return `<figure class="oli-embed"><iframe src="${escapeHtml(src)}" title="${escapeHtml(title || type)}" width="${escapeHtml(width)}" height="${escapeHtml(height)}" loading="lazy" allowfullscreen></iframe>${caption ? `<figcaption>${caption}</figcaption>` : ''}</figure>`;
  }
  const parts: string[] = [];
  for (const key of ['content', 'children', 'caption', 'meanings', 'term', 'trigger']) {
    if (Array.isArray(value[key])) {
      parts.push(richTextToHtml(value[key]));
    } else if (typeof value[key] === 'string') {
      parts.push(escapeHtml(value[key]));
    }
  }
  return wrapInlineHtml(value, parts.join(''));
}

function listNodeToPlainText(node: JsonRecord): string {
  const items = Array.isArray(node.children) ? node.children.filter(isRecord) : [];
  return items.map((item, index) => {
    const text = richTextToPlainText(item).trim();
    if (!text) {
      return '';
    }
    return node.type === 'ol' ? `${index + 1}. ${text}` : `- ${text}`;
  }).filter(Boolean).join('\n');
}

function listNodeToHtml(node: JsonRecord): string {
  return richTextToHtml(node);
}

function nonBlank(value: unknown, label: string): string {
  const text = optionalText(value);
  if (!text) {
    throw new Error(`${label} is required`);
  }
  return text;
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

function firstBlockText(node: JsonRecord): string {
  if (['p', 'h1', 'h2', 'h3'].includes(optionalText(node.type))) {
    return richTextToPlainText(node).trim();
  }
  const children = Array.isArray(node.children) ? node.children.filter(isRecord) : [];
  for (const child of children) {
    const text = firstBlockText(child);
    if (text) {
      return text;
    }
  }
  return '';
}

function withoutLeadingTitleBlock(node: JsonRecord, title: string): JsonRecord {
  const children = Array.isArray(node.children) ? node.children.filter(isRecord) : [];
  if (children.length === 0) {
    return node;
  }
  const first = children[0];
  const firstType = optionalText(first.type);
  if (['p', 'h1', 'h2', 'h3'].includes(firstType) && richTextToPlainText(first).trim() === title) {
    return { ...node, children: children.slice(1) };
  }
  if (children.length === 1 && optionalText(first.type) === 'content') {
    return { ...node, children: [withoutLeadingTitleBlock(first, title)] };
  }
  return node;
}

function isMeaninglessTitleParagraph(node: JsonRecord): boolean {
  return optionalText(node.type) === 'p'
    && richTextToPlainText(node).trim().toLowerCase() === 'title';
}

function literal(value: unknown): JsonRecord {
  return { type: 'literal', value };
}

function variable(name: string): JsonRecord {
  return { type: 'variable', name };
}

function bind(variableName: string): JsonRecord {
  return { type: 'bind', variable: variableName };
}

function bound(variableName: string): JsonRecord {
  return { type: 'bound', variable: variableName };
}

function ruleForExactResponse(params: {
  id: string;
  module: string;
  selection: string;
  action: string;
  expected: unknown;
  nodeId: string;
  feedbackNodeId: string;
  outcome: 'correct' | 'incorrect';
  message: string;
  kc: string;
  clusterIndex: number;
}): JsonRecord {
  return {
    id: params.id,
    module: params.module,
    salience: params.outcome === 'correct' ? 30 : 20,
    when: [{
      factType: 'interface-event',
      slots: {
        pageKey: bind('pageKey'),
        selection: literal(params.selection),
        action: literal(params.action),
        input: bind('input'),
      },
    }],
    tests: [{
      op: 'eq',
      left: variable('input'),
      right: literal(params.expected),
    }],
    then: [
      { type: 'classify', outcome: params.outcome },
      {
        type: 'write-state',
        write: {
          target: { pageKey: variable('pageKey'), nodeId: literal(params.nodeId) },
          key: 'correctness',
          value: literal(params.outcome),
        },
      },
      {
        type: 'message',
        messageType: 'feedback',
        template: params.message,
        target: { pageKey: variable('pageKey'), nodeId: literal(params.feedbackNodeId) },
      },
      { type: 'credit', kc: params.kc },
      {
        type: 'model-practice',
        outcome: params.outcome,
        clusterIndex: params.clusterIndex,
        nodeId: params.nodeId,
        responseValue: variable('input'),
      },
    ],
  };
}

function feedbackForResponse(response: JsonRecord): string {
  return richTextToHtml(asRecord(response.feedback, 'response.feedback').content).trim();
}

function correctResponseForPart(part: JsonRecord): JsonRecord {
  const responses = asArray(part.responses, 'part.responses').filter(isRecord);
  const correct = responses.find((response) => Number(response.score) > 0);
  if (!correct) {
    throw new Error(`No positive-score response for part ${String(part.id)}`);
  }
  return correct;
}

function responseLegacyMatch(response: JsonRecord, label: string): string {
  return nonBlank(response.legacyMatch, label);
}

function responseScoreOutcome(response: JsonRecord): 'correct' | 'incorrect' {
  return Number(response.score) > 0 ? 'correct' : 'incorrect';
}

function responseKc(part: JsonRecord, moduleSlug: string): string {
  return optionalText(asArray(part.objectives ?? [], 'part.objectives')[0]) || moduleSlug;
}

function buildChoiceMap(activity: JsonRecord): Map<string, string> {
  const content = asRecord(activity.content, 'activity.content');
  const choices = asArray(content.choices, 'activity.content.choices').filter(isRecord);
  const map = new Map<string, string>();
  for (const choice of choices) {
    const id = nonBlank(choice.id, 'choice.id');
    map.set(id, richTextToPlainText(choice.content).trim());
  }
  return map;
}

function buildMultipleChoiceExercise(params: {
  activity: JsonRecord;
  index: number;
  pageId: string;
  moduleSlug: string;
  productionRules: JsonRecord[];
  behaviorSteps: JsonRecord[];
  responseIntent: JsonRecord[];
  modelTargets: SparcModelTargetRegistry;
}): JsonRecord {
  const activity = params.activity;
  const activityId = nonBlank(activity.id, 'activity.id');
  const content = asRecord(activity.content, 'activity.content');
  const stemContent = asRecord(content.stem, 'activity.content.stem').content;
  const stem = richTextToPlainText(stemContent).trim();
  const stemHtml = richTextToHtml(stemContent).trim();
  const choiceMap = buildChoiceMap(activity);
  const authoring = asRecord(content.authoring, 'activity.content.authoring');
  const part = asRecord(asArray(authoring.parts, 'activity.content.authoring.parts')[0], 'authoring.parts[0]');
  const modelTarget = ensureModelTarget(params.modelTargets, {
    activity,
    activityId,
    part,
    pageId: params.pageId,
    moduleSlug: params.moduleSlug,
    label: stem || optionalText(activity.title),
  });
  const correctResponse = correctResponseForPart(part);
  const correctChoiceId = responseLegacyMatch(correctResponse, `correct legacyMatch for ${activityId}`);
  const feedbackNodeId = `node-${activityId}-feedback`;
  const exerciseNodeId = `node-${activityId}`;
  const choices = [...choiceMap.entries()].map(([choiceId, label]) => {
    const nodeId = `node-${activityId}-choice-${choiceId}`;
    const correct = choiceId === correctChoiceId;
    const selection = `${activityId}:${choiceId}`;
    params.behaviorSteps.push({
      id: `behavior-${activityId}-${choiceId}`,
      responses: [{
        nodeRef: nodeId,
        selection,
        action: 'ButtonPressed',
        input: choiceId,
      }],
    });
    params.responseIntent.push({
      node: nodeId,
      expected: choiceId,
      type: correct ? 'correct-choice' : 'incorrect-choice',
    });
    const matchedResponse = asArray(part.responses, 'part.responses')
      .filter(isRecord)
      .find((response) => optionalText(response.legacyMatch) === choiceId);
    params.productionRules.push(ruleForExactResponse({
      id: `sparc-intro-stats.${activityId}.${choiceId}.correct`,
      module: params.moduleSlug,
      selection,
      action: 'ButtonPressed',
      expected: choiceId,
      nodeId,
      feedbackNodeId,
      outcome: correct ? 'correct' : 'incorrect',
      message: matchedResponse ? feedbackForResponse(matchedResponse) : (correct ? feedbackForResponse(correctResponse) : 'Incorrect.'),
      kc: optionalText(asArray(part.objectives ?? [], 'part.objectives')[0]) || params.moduleSlug,
      clusterIndex: modelTarget.clusterIndex,
    }));
    return {
      id: nodeId,
      nodeType: 'atomic',
      atomType: 'button',
      clusterIndex: modelTarget.clusterIndex,
      label,
      value: choiceId,
      expected: correctChoiceId,
    };
  });
  return {
    id: exerciseNodeId,
    nodeType: 'group',
    groupType: 'multiple-choice',
    label: stem,
    placement: { region: 'document', order: params.index },
    layout: { visualPreset: 'practice-panel', glue: { mode: 'multiple-choice', answerPlacement: 'below-prompt', feedbackPlacement: 'below-answers' } },
    children: [
      ...(stemHtml ? [{ id: `node-${activityId}-prompt`, nodeType: 'atomic', atomType: 'html-block', value: stemHtml }] : []),
      { id: `node-${activityId}-answers`, nodeType: 'group', groupType: 'answer-list', children: choices },
      { id: feedbackNodeId, nodeType: 'atomic', atomType: 'message-box', value: '' },
    ],
    source: { activityId, pageId: params.pageId, oliSubType: activity.subType ?? null },
  };
}

function buildTargetedCataExercise(params: {
  activity: JsonRecord;
  index: number;
  pageId: string;
  moduleSlug: string;
  productionRules: JsonRecord[];
  behaviorSteps: JsonRecord[];
  responseIntent: JsonRecord[];
  modelTargets: SparcModelTargetRegistry;
}): JsonRecord {
  const activity = params.activity;
  const activityId = nonBlank(activity.id, 'activity.id');
  const content = asRecord(activity.content, 'activity.content');
  if (content.type !== 'TargetedCATA') {
    throw new Error(`Activity ${activityId} is not TargetedCATA`);
  }
  const stemContent = asRecord(content.stem, 'activity.content.stem').content;
  const stem = richTextToPlainText(stemContent).trim();
  const authoring = asRecord(content.authoring, 'activity.content.authoring');
  const correctTuple = asArray(authoring.correct, 'TargetedCATA authoring.correct');
  const correctIds = new Set(asArray(correctTuple[0], 'TargetedCATA correct ids').map((value) => String(value)));
  const part = asRecord(asArray(authoring.parts, 'activity.content.authoring.parts')[0], 'authoring.parts[0]');
  const modelTarget = ensureModelTarget(params.modelTargets, {
    activity,
    activityId,
    part,
    pageId: params.pageId,
    moduleSlug: params.moduleSlug,
    label: stem || optionalText(activity.title),
  });
  const responses = asArray(part.responses, 'TargetedCATA part.responses').filter(isRecord);
  const feedbackNodeId = `node-${activityId}-feedback`;
  const choiceMap = buildChoiceMap(activity);
  const choiceEntries = [...choiceMap.entries()];
  const checkboxNodeIdByChoice = new Map<string, string>();
  const checkboxes = choiceEntries.map(([choiceId, label]) => {
    const rowNodeId = `node-${activityId}-choice-${choiceId}`;
    const nodeId = `${rowNodeId}-checkbox`;
    checkboxNodeIdByChoice.set(choiceId, nodeId);
    const expected = correctIds.has(choiceId);
    const selection = `${activityId}:${choiceId}`;
    params.behaviorSteps.push({
      id: `behavior-${activityId}-${choiceId}`,
      responses: [
        { nodeRef: nodeId, selection, action: 'UpdateCheckbox', input: true },
        { nodeRef: nodeId, selection, action: 'UpdateCheckbox', input: false },
      ],
    });
    params.responseIntent.push({ node: nodeId, expected, type: 'targeted-cata-choice' });
    return {
      id: rowNodeId,
      nodeType: 'group',
      groupType: 'checkbox-choice',
      layout: { glue: { mode: 'inline-control' } },
      children: [
        { id: nodeId, nodeType: 'atomic', atomType: 'checkbox', clusterIndex: modelTarget.clusterIndex, checked: false, expected },
        { id: `${rowNodeId}-label`, nodeType: 'atomic', atomType: 'html-block', value: escapeHtml(label) },
      ],
    };
  });
  const exactResponseMatches = new Set<string>();
  for (const response of responses) {
    const legacyMatch = optionalText(response.legacyMatch);
    if (!legacyMatch || legacyMatch === '.*') {
      continue;
    }
    exactResponseMatches.add(legacyMatch);
    const selectedIds = new Set(legacyMatch.split(',').map((value) => value.trim()).filter(Boolean));
    const outcome = responseScoreOutcome(response);
    const then: JsonRecord[] = [
      { type: 'classify', outcome },
      ...choiceEntries.map(([choiceId]) => {
        const nodeId = nonBlank(checkboxNodeIdByChoice.get(choiceId), `checkbox node for ${choiceId}`);
        const selected = selectedIds.has(choiceId);
        const expected = correctIds.has(choiceId);
        return {
          type: 'write-state',
          write: {
            target: { pageKey: variable('pageKey'), nodeId: literal(nodeId) },
            key: 'correctness',
            value: literal(selected === expected ? 'correct' : 'incorrect'),
          },
        };
      }),
      {
        type: 'message',
        messageType: 'feedback',
        template: feedbackForResponse(response),
        target: { pageKey: variable('pageKey'), nodeId: literal(feedbackNodeId) },
      },
      { type: 'credit', kc: responseKc(part, params.moduleSlug) },
      {
        type: 'model-practice',
        outcome,
        clusterIndex: modelTarget.clusterIndex,
        nodeId: `node-${activityId}-check`,
        responseValue: literal(legacyMatch),
      },
    ];
    params.productionRules.push({
      id: `sparc-intro-stats.${activityId}.${slug(legacyMatch)}.cata-combination`,
      module: params.moduleSlug,
      salience: outcome === 'correct' ? 40 : 30,
      when: choiceEntries.map(([choiceId]) => ({
        factType: 'interface-event',
        slots: {
          pageKey: bind('pageKey'),
          selection: literal(`${activityId}:${choiceId}`),
          action: literal('UpdateCheckbox'),
          input: literal(selectedIds.has(choiceId)),
        },
      })),
      tests: [],
      then,
    });
  }
  const defaultResponse = responses.find((response) => optionalText(response.legacyMatch) === '.*');
  if (defaultResponse && !exactResponseMatches.has('')) {
    const outcome = responseScoreOutcome(defaultResponse);
    params.productionRules.push({
      id: `sparc-intro-stats.${activityId}.none.cata-combination`,
      module: params.moduleSlug,
      salience: 10,
      when: choiceEntries.map(([choiceId]) => ({
        factType: 'interface-event',
        slots: {
          pageKey: bind('pageKey'),
          selection: literal(`${activityId}:${choiceId}`),
          action: literal('UpdateCheckbox'),
          input: literal(false),
        },
      })),
      tests: [],
      then: [
        { type: 'classify', outcome },
        ...choiceEntries.map(([choiceId]) => ({
          type: 'write-state',
          write: {
            target: { pageKey: variable('pageKey'), nodeId: literal(nonBlank(checkboxNodeIdByChoice.get(choiceId), `checkbox node for ${choiceId}`)) },
            key: 'correctness',
            value: literal(correctIds.has(choiceId) ? 'incorrect' : 'correct'),
          },
        })),
        {
          type: 'message',
          messageType: 'feedback',
          template: feedbackForResponse(defaultResponse),
          target: { pageKey: variable('pageKey'), nodeId: literal(feedbackNodeId) },
        },
        { type: 'credit', kc: responseKc(part, params.moduleSlug) },
        {
          type: 'model-practice',
          outcome,
          clusterIndex: modelTarget.clusterIndex,
          nodeId: `node-${activityId}-check`,
          responseValue: literal(''),
        },
      ],
    });
  }
  return {
    id: `node-${activityId}`,
    nodeType: 'group',
    groupType: 'targeted-cata',
    label: stem,
    placement: { region: 'document', order: params.index },
    layout: { visualPreset: 'practice-panel', glue: { mode: 'checkbox-list', orientation: 'vertical', feedbackPlacement: 'below-answers' } },
    children: [
      { id: `node-${activityId}-answers`, nodeType: 'group', groupType: 'answer-list', children: checkboxes },
      { id: `node-${activityId}-check`, nodeType: 'atomic', atomType: 'button', clusterIndex: modelTarget.clusterIndex, label: 'Check', value: 'check' },
      { id: feedbackNodeId, nodeType: 'atomic', atomType: 'message-box', value: '' },
    ],
    source: {
      activityId,
      pageId: params.pageId,
      oliSubType: activity.subType ?? null,
      conversionRule: 'content.type === TargetedCATA; authoring.correct[0] supplies selected choice ids; each choice becomes a checkbox node with expected boolean.',
    },
  };
}

function buildDropdownExercise(params: {
  activity: JsonRecord;
  index: number;
  pageId: string;
  moduleSlug: string;
  productionRules: JsonRecord[];
  behaviorSteps: JsonRecord[];
  responseIntent: JsonRecord[];
  modelTargets: SparcModelTargetRegistry;
}): JsonRecord {
  const activity = params.activity;
  const activityId = nonBlank(activity.id, 'activity.id');
  const content = asRecord(activity.content, 'activity.content');
  const stemContent = asArray(asRecord(content.stem, 'activity.content.stem').content, 'activity.content.stem.content');
  const inputs = asArray(content.inputs, 'activity.content.inputs').filter(isRecord);
  const choices = buildChoiceMap(activity);
  const parts = asArray(asRecord(content.authoring, 'activity.content.authoring').parts, 'authoring.parts').filter(isRecord);
  const partById = new Map(parts.map((part) => [nonBlank(part.id, 'part.id'), part]));
  const children: JsonRecord[] = [];
  const rowByInputId = new Map<string, JsonRecord>();
  const feedbackByInputId = new Map<string, JsonRecord>();
  const firstLine = richTextToPlainText(stemContent[0]).trim();
  const embeddedInputRefs = stemContent.flatMap(inputReferenceIds);
  const usesEmbeddedInputRefs = optionalText(activity.subType) === 'oli_multi_input';
  if (usesEmbeddedInputRefs) {
    const inputIds = new Set(inputs.map((input) => nonBlank(input.id, 'input.id')));
    for (const inputId of inputIds) {
      const referenceCount = embeddedInputRefs.filter((candidate) => candidate === inputId).length;
      if (referenceCount !== 1) {
        throw new Error(`Activity ${activityId} input ${inputId} must have exactly one authored input_ref; found ${referenceCount}`);
      }
    }
    for (const inputRef of embeddedInputRefs) {
      if (!inputIds.has(inputRef)) {
        throw new Error(`Activity ${activityId} stem references unknown input ${inputRef}`);
      }
    }
  }
  for (let i = 0; i < inputs.length; i += 1) {
    const input = inputs[i];
    const inputId = nonBlank(input.id, 'input.id');
    const partId = nonBlank(input.partId, 'input.partId');
    const part = partById.get(partId);
    if (!part) {
      throw new Error(`Input ${inputId} references missing part ${partId}`);
    }
    const modelTarget = ensureModelTarget(params.modelTargets, {
      activity,
      activityId,
      part,
      pageId: params.pageId,
      moduleSlug: params.moduleSlug,
      label: firstLine || optionalText(activity.title),
      inputId,
    });
    const correctResponse = correctResponseForPart(part);
    const correctLegacyMatch = responseLegacyMatch(correctResponse, `correct legacyMatch for ${activityId}:${partId}`);
    const optionIds = asArray(input.choiceIds, 'input.choiceIds').map((value) => String(value));
    const correctChoiceId = optionIds.includes(correctLegacyMatch)
      ? correctLegacyMatch
      : `${partId}_${correctLegacyMatch}`;
    const options = ['', ...optionIds.map((choiceId) => nonBlank(choices.get(choiceId), `choice label ${choiceId}`))];
    const expected = nonBlank(choices.get(correctChoiceId), `expected label ${correctChoiceId}`);
    const referencedStemBlock = usesEmbeddedInputRefs
      ? stemContent.find((block) => inputReferenceIds(block).includes(inputId))
      : stemContent[i + 1];
    const lineHtml = richTextToHtml(referencedStemBlock).trim();
    const nodeId = `node-${activityId}-input-${inputId}`;
    const feedbackNodeId = `node-${activityId}-feedback-${inputId}`;
    const selection = `${activityId}:${inputId}`;
    params.behaviorSteps.push({
      id: `behavior-${activityId}-${inputId}`,
      responses: optionIds.map((choiceId) => ({
        nodeRef: nodeId,
        selection,
        action: 'UpdateDropdown',
        input: nonBlank(choices.get(choiceId), `choice label ${choiceId}`),
      })),
    });
    params.responseIntent.push({ node: nodeId, expected, acceptedValues: [expected, correctChoiceId], type: 'dropdown' });
    for (const response of asArray(part.responses, 'part.responses').filter(isRecord)) {
      const legacyMatch = optionalText(response.legacyMatch);
      if (!legacyMatch || legacyMatch === '.*') {
        continue;
      }
      const responseChoiceId = optionIds.includes(legacyMatch)
        ? legacyMatch
        : `${partId}_${legacyMatch}`;
      if (!optionIds.includes(responseChoiceId)) {
        continue;
      }
      const responseLabel = nonBlank(choices.get(responseChoiceId), `response label ${responseChoiceId}`);
      const outcome = responseScoreOutcome(response);
      params.productionRules.push(ruleForExactResponse({
        id: `sparc-intro-stats.${activityId}.${inputId}.${slug(responseLabel)}.dropdown`,
        module: params.moduleSlug,
        selection,
        action: 'UpdateDropdown',
        expected: responseLabel,
        nodeId,
        feedbackNodeId,
        outcome,
        message: feedbackForResponse(response),
        kc: responseKc(part, params.moduleSlug),
        clusterIndex: modelTarget.clusterIndex,
      }));
    }
    rowByInputId.set(inputId, {
      id: `node-${activityId}-row-${inputId}`,
      nodeType: 'group',
      groupType: 'dropdown-row',
      layout: { glue: { mode: 'inline-control' } },
      children: [
        { id: `node-${activityId}-label-${inputId}`, nodeType: 'atomic', atomType: 'html-block', value: lineHtml },
        { id: nodeId, nodeType: 'atomic', atomType: 'dropdown', clusterIndex: modelTarget.clusterIndex, selected: '', options, expected },
      ],
    });
    feedbackByInputId.set(inputId, { id: feedbackNodeId, nodeType: 'atomic', atomType: 'message-box', value: '' });
  }
  if (usesEmbeddedInputRefs) {
    for (const [blockIndex, stemBlock] of stemContent.entries()) {
      const inputRefs = inputReferenceIds(stemBlock);
      if (inputRefs.length === 0) {
        const html = richTextToHtml(stemBlock).trim();
        if (html) {
          children.push({
            id: `node-${activityId}-context-${blockIndex + 1}`,
            nodeType: 'atomic',
            atomType: 'html-block',
            value: html,
          });
        }
        continue;
      }
      for (const [refIndex, inputRef] of inputRefs.entries()) {
        const row = asRecord(rowByInputId.get(inputRef), `dropdown row ${activityId}:${inputRef}`);
        if (refIndex > 0) {
          row.children = asArray(row.children, `dropdown row children ${activityId}:${inputRef}`)
            .filter((child) => !isRecord(child) || optionalText(child.atomType) !== 'html-block');
        }
        children.push(row);
        children.push(asRecord(feedbackByInputId.get(inputRef), `dropdown feedback ${activityId}:${inputRef}`));
      }
    }
  } else {
    for (const input of inputs) {
      const inputId = nonBlank(input.id, 'input.id');
      children.push(asRecord(rowByInputId.get(inputId), `dropdown row ${activityId}:${inputId}`));
      children.push(asRecord(feedbackByInputId.get(inputId), `dropdown feedback ${activityId}:${inputId}`));
    }
  }
  return {
    id: `node-${activityId}`,
    nodeType: 'group',
    groupType: 'dropdown-exercise',
    label: firstLine || optionalText(activity.title),
    placement: { region: 'document', order: params.index },
    layout: { visualPreset: 'practice-panel', glue: { mode: 'dropdown-list', orientation: 'vertical', feedbackPlacement: 'below-answers' } },
    children,
    source: { activityId, pageId: params.pageId, oliSubType: activity.subType ?? null },
  };
}

function buildTextInputExercise(params: {
  activity: JsonRecord;
  index: number;
  pageId: string;
  moduleSlug: string;
  productionRules: JsonRecord[];
  behaviorSteps: JsonRecord[];
  responseIntent: JsonRecord[];
  modelTargets: SparcModelTargetRegistry;
}): JsonRecord {
  const activity = params.activity;
  const activityId = nonBlank(activity.id, 'activity.id');
  const content = asRecord(activity.content, 'activity.content');
  const stemContent = asArray(asRecord(content.stem, 'activity.content.stem').content, 'activity.content.stem.content');
  const inputs = asArray(content.inputs, 'activity.content.inputs').filter(isRecord);
  const parts = asArray(asRecord(content.authoring, 'activity.content.authoring').parts, 'authoring.parts').filter(isRecord);
  const partById = new Map(parts.map((part) => [nonBlank(part.id, 'part.id'), part]));
  const feedbackNodeId = `node-${activityId}-feedback`;
  const stemHtml = richTextToHtml(stemContent).trim();
  const children: JsonRecord[] = [];
  for (const input of inputs) {
    const inputId = nonBlank(input.id, 'input.id');
    const partId = nonBlank(input.partId, 'input.partId');
    const part = partById.get(partId);
    if (!part) {
      throw new Error(`Input ${inputId} references missing part ${partId}`);
    }
    const modelTarget = ensureModelTarget(params.modelTargets, {
      activity,
      activityId,
      part,
      pageId: params.pageId,
      moduleSlug: params.moduleSlug,
      label: richTextToPlainText(stemContent).trim() || optionalText(activity.title),
      inputId,
    });
    const nodeId = `node-${activityId}-input-${inputId}`;
    const selection = `${activityId}:${inputId}`;
    const responses = asArray(part.responses, 'part.responses').filter(isRecord);
    const exactResponses = responses.filter((response) => {
      const legacyMatch = optionalText(response.legacyMatch);
      return legacyMatch && legacyMatch !== '.*';
    });
    const defaultResponse = responses.find((response) => optionalText(response.legacyMatch) === '.*');
    params.behaviorSteps.push({
      id: `behavior-${activityId}-${inputId}`,
      responses: [
        {
          nodeRef: nodeId,
          selection,
          action: 'UpdateTextField',
          input: '',
        },
      ],
    });
    const correctResponse = responses.find((response) => Number(response.score) > 0);
    params.responseIntent.push({
      node: nodeId,
      expected: correctResponse ? optionalText(correctResponse.legacyMatch) : '',
      type: optionalText(input.inputType) === 'numeric' ? 'numeric-input' : 'text-input',
    });
    for (const [responseIndex, response] of exactResponses.entries()) {
      const legacyMatch = nonBlank(response.legacyMatch, `legacyMatch for ${activityId}:${inputId}`);
      params.productionRules.push(ruleForExactResponse({
        id: `sparc-intro-stats.${activityId}.${inputId}.${slug(legacyMatch)}.${responseIndex}.text-input`,
        module: params.moduleSlug,
        selection,
        action: 'UpdateTextField',
        expected: legacyMatch,
        nodeId,
        feedbackNodeId,
        outcome: responseScoreOutcome(response),
        message: feedbackForResponse(response),
        kc: responseKc(part, params.moduleSlug),
        clusterIndex: modelTarget.clusterIndex,
      }));
    }
    if (defaultResponse) {
      const outcome = responseScoreOutcome(defaultResponse);
      params.productionRules.push({
        id: `sparc-intro-stats.${activityId}.${inputId}.default.text-input`,
        module: params.moduleSlug,
        salience: 5,
        when: [{
          factType: 'interface-event',
          slots: {
            pageKey: bind('pageKey'),
            selection: literal(selection),
            action: literal('UpdateTextField'),
            input: bind('input'),
          },
        }],
        tests: exactResponses.map((response) => ({
          op: 'neq',
          left: variable('input'),
          right: literal(optionalText(response.legacyMatch)),
        })),
        then: [
          { type: 'classify', outcome },
          {
            type: 'write-state',
            write: {
              target: { pageKey: variable('pageKey'), nodeId: literal(nodeId) },
              key: 'correctness',
              value: literal(outcome),
            },
          },
          {
            type: 'message',
            messageType: 'feedback',
            template: feedbackForResponse(defaultResponse),
            target: { pageKey: variable('pageKey'), nodeId: literal(feedbackNodeId) },
          },
          { type: 'credit', kc: responseKc(part, params.moduleSlug) },
          {
            type: 'model-practice',
            outcome,
            clusterIndex: modelTarget.clusterIndex,
            nodeId,
            responseValue: variable('input'),
          },
        ],
      });
    }
    children.push({
      id: `node-${activityId}-row-${inputId}`,
      nodeType: 'group',
      groupType: 'text-input-row',
      layout: { glue: { mode: 'inline-control' } },
      children: [
        { id: nodeId, nodeType: 'atomic', atomType: 'text-input', clusterIndex: modelTarget.clusterIndex, value: '', expected: correctResponse ? optionalText(correctResponse.legacyMatch) : '' },
      ],
    });
  }
  return {
    id: `node-${activityId}`,
    nodeType: 'group',
    groupType: 'text-input-exercise',
    label: richTextToPlainText(stemContent).trim() || optionalText(activity.title),
    placement: { region: 'document', order: params.index },
    layout: { visualPreset: 'practice-panel', glue: { mode: 'text-input-list', orientation: 'vertical', feedbackPlacement: 'below-answers' } },
    children: [
      { id: `node-${activityId}-stem`, nodeType: 'atomic', atomType: 'html-block', value: stemHtml },
      ...children,
      { id: feedbackNodeId, nodeType: 'atomic', atomType: 'message-box', value: '' },
    ],
    source: { activityId, pageId: params.pageId, oliSubType: activity.subType ?? null },
  };
}

function buildShortAnswerExercise(params: {
  activity: JsonRecord;
  index: number;
  pageId: string;
  moduleSlug: string;
  productionRules: JsonRecord[];
  behaviorSteps: JsonRecord[];
  responseIntent: JsonRecord[];
  modelTargets: SparcModelTargetRegistry;
}): JsonRecord {
  const activity = params.activity;
  const activityId = nonBlank(activity.id, 'activity.id');
  const content = asRecord(activity.content, 'activity.content');
  const stemContent = asRecord(content.stem, 'activity.content.stem').content;
  const stem = richTextToHtml(stemContent).trim();
  const authoring = asRecord(content.authoring, 'activity.content.authoring');
  const part = asRecord(asArray(authoring.parts, 'activity.content.authoring.parts')[0], 'authoring.parts[0]');
  const modelTarget = ensureModelTarget(params.modelTargets, {
    activity,
    activityId,
    part,
    pageId: params.pageId,
    moduleSlug: params.moduleSlug,
    label: richTextToPlainText(stemContent).trim() || optionalText(activity.title),
  });
  const responses = asArray(part.responses, 'part.responses').filter(isRecord);
  const response = responses.find((candidate) => Number(candidate.score) > 0) || responses[0];
  if (!response) {
    throw new Error(`No authored response for short-answer activity ${activityId}`);
  }
  const authoredRule = nonBlank(response.rule, `short-answer response rule ${activityId}`);
  if (authoredRule !== 'input like {.*}') {
    throw new Error(`Unsupported short-answer response rule for ${activityId}: ${authoredRule}`);
  }
  const inputNodeId = `node-${activityId}-input`;
  const submitNodeId = `node-${activityId}-submit`;
  const feedbackNodeId = `node-${activityId}-feedback`;
  const submitSelection = `${activityId}:submit`;
  params.behaviorSteps.push({
    id: `behavior-${activityId}-short-answer`,
    responses: [
      {
        nodeRef: inputNodeId,
        selection: `${activityId}:input`,
        action: 'UpdateTextField',
        input: '',
      },
      {
        nodeRef: submitNodeId,
        selection: submitSelection,
        action: 'ButtonPressed',
        input: 'submit',
      },
    ],
  });
  params.responseIntent.push({
    node: inputNodeId,
    expected: optionalText(response.rule) || 'authored-response',
    type: 'short-answer',
  });
  const outcome = responseScoreOutcome(response);
  params.productionRules.push({
    id: `sparc-intro-stats.${activityId}.short-answer-input`,
    module: params.moduleSlug,
    salience: outcome === 'correct' ? 30 : 20,
    when: [{
      factType: 'interface-event',
      slots: {
        pageKey: bind('pageKey'),
        selection: literal(`${activityId}:input`),
        action: literal('UpdateTextField'),
        input: bind('learnerInput'),
      },
    }],
    tests: [],
    then: [
      { type: 'classify', outcome },
    ],
  });
  params.productionRules.push({
    id: `sparc-intro-stats.${activityId}.short-answer-submit`,
    module: params.moduleSlug,
    salience: outcome === 'correct' ? 30 : 20,
    when: [{
      factType: 'interface-event',
      slots: {
        pageKey: bind('pageKey'),
        selection: literal(submitSelection),
        action: literal('ButtonPressed'),
        input: literal('submit'),
      },
    }, {
      factType: 'interface-state',
      slots: {
        pageKey: bound('pageKey'),
        node: literal(inputNodeId),
        key: literal('value'),
        value: bind('learnerInput'),
      },
    }],
    tests: [],
    then: [
      { type: 'classify', outcome },
      {
        type: 'write-state',
        write: {
          target: { pageKey: variable('pageKey'), nodeId: literal(inputNodeId) },
          key: 'correctness',
          value: literal(outcome),
        },
      },
      {
        type: 'message',
        messageType: 'feedback',
        template: feedbackForResponse(response),
        target: { pageKey: variable('pageKey'), nodeId: literal(feedbackNodeId) },
      },
      { type: 'credit', kc: responseKc(part, params.moduleSlug) },
      {
        type: 'model-practice',
        outcome,
        clusterIndex: modelTarget.clusterIndex,
        nodeId: inputNodeId,
        responseValue: variable('learnerInput'),
      },
    ],
  });
  return {
    id: `node-${activityId}`,
    nodeType: 'group',
    groupType: 'short-answer',
    label: richTextToPlainText(stemContent).trim() || optionalText(activity.title),
    placement: { region: 'document', order: params.index },
    layout: { visualPreset: 'practice-panel', glue: { mode: 'short-answer', feedbackPlacement: 'below-answers' } },
    children: [
      { id: `node-${activityId}-stem`, nodeType: 'atomic', atomType: 'html-block', value: stem },
      { id: inputNodeId, nodeType: 'atomic', atomType: 'text-input', clusterIndex: modelTarget.clusterIndex, value: '', expected: optionalText(response.rule) || '' },
      { id: submitNodeId, nodeType: 'atomic', atomType: 'button', clusterIndex: modelTarget.clusterIndex, label: 'Submit', value: 'submit' },
      { id: feedbackNodeId, nodeType: 'atomic', atomType: 'message-box', value: '' },
    ],
    source: { activityId, pageId: params.pageId, oliSubType: activity.subType ?? null },
  };
}

function buildMissingActivityDiagnostic(params: {
  activityId: string;
  index: number;
  pageId: string;
  moduleSlug: string;
}): JsonRecord {
  const html = [
    '<aside class="oli-missing-reference">',
    '<h5>Missing OLI activity file</h5>',
    `<p>The OLI page references activity <code>${escapeHtml(params.activityId)}</code>, but no matching JSON file was found in this export.</p>`,
    `<p>Module: <code>${escapeHtml(params.moduleSlug)}</code><br>Page: <code>${escapeHtml(params.pageId)}</code></p>`,
    '</aside>',
  ].join('');
  return {
    id: `node-missing-activity-${params.pageId}-${params.activityId}`,
    nodeType: 'atomic',
    atomType: 'html-block',
    value: html,
    placement: { region: 'document', order: params.index },
    source: {
      conversionIssue: 'missing-oli-activity-file',
      activityId: params.activityId,
      pageId: params.pageId,
      moduleSlug: params.moduleSlug,
    },
  };
}

function convertActivityReference(params: {
  activityId: string;
  index: number;
  pageId: string;
  moduleSlug: string;
  sourceRoot: string;
  productionRules: JsonRecord[];
  behaviorSteps: JsonRecord[];
  responseIntent: JsonRecord[];
  modelTargets: SparcModelTargetRegistry;
}): JsonRecord {
  const contentRoot = contentRootFor(params.sourceRoot);
  const fileIndex = buildJsonFileIndex(contentRoot);
  const activityPath = fileIndex.get(params.activityId);
  if (!activityPath) {
    return buildMissingActivityDiagnostic(params);
  }
  const activity = readJson(activityPath);
  assertCoveredOliNodes(activity, activityPath);
  const content = asRecord(activity.content, 'activity.content');
  if (content.type === 'TargetedCATA') {
    return buildTargetedCataExercise({ activity, ...params });
  }
  if (Array.isArray(content.inputs) && content.inputs.length > 0 && content.inputs.filter(isRecord).every((input) => Array.isArray(input.choiceIds))) {
    return buildDropdownExercise({ activity, ...params });
  }
  if (Array.isArray(content.inputs) && content.inputs.length > 0) {
    return buildTextInputExercise({ activity, ...params });
  }
  if (Array.isArray(content.choices)) {
    return buildMultipleChoiceExercise({ activity, ...params });
  }
  if (optionalText(content.inputType) === 'textarea' || optionalText(activity.subType) === 'oli_short_answer') {
    return buildShortAnswerExercise({ activity, ...params });
  }
  throw new Error(`Unsupported activity shape for ${params.activityId}`);
}

function convertSlateNode(params: {
  node: unknown;
  idPrefix: string;
  pageId: string;
  sourceRoot: string;
  moduleSlug: string;
  productionRules: JsonRecord[];
  behaviorSteps: JsonRecord[];
  responseIntent: JsonRecord[];
  modelTargets: SparcModelTargetRegistry;
  counter: { value: number };
}): JsonRecord[] {
  if (!isRecord(params.node)) {
    return [];
  }
  const type = optionalText(params.node.type);
  if (isMeaninglessTitleParagraph(params.node)) {
    return [];
  }
  if (type === 'activity-reference') {
    const activityId = String(params.node.activity_id ?? '').trim();
    if (!activityId) {
      throw new Error(`Missing activity_id in page ${params.pageId}`);
    }
    params.counter.value += 1;
    return [convertActivityReference({
      activityId,
      index: params.counter.value,
      pageId: params.pageId,
      moduleSlug: params.moduleSlug,
      sourceRoot: params.sourceRoot,
      productionRules: params.productionRules,
      behaviorSteps: params.behaviorSteps,
      responseIntent: params.responseIntent,
      modelTargets: params.modelTargets,
    })];
  }
  if (type === 'group') {
    const groupChildren = Array.isArray(params.node.children) ? params.node.children : [];
    params.counter.value += 1;
    const groupOrder = params.counter.value;
    if (groupChildren.length === 1 && isRecord(groupChildren[0]) && optionalText(groupChildren[0].type) === 'alternatives') {
      const alternatives = asArray(groupChildren[0].children, 'alternatives.children').filter(isRecord);
      const panels = alternatives.flatMap((alternative, alternativeIndex) => {
        const label = firstBlockText(alternative) || optionalText(alternative.id) || `Option ${alternativeIndex + 1}`;
        const normalizedAlternative = withoutLeadingTitleBlock(alternative, label);
        const children = convertSlateNode({ ...params, node: normalizedAlternative });
        if (children.length === 0) {
          return [];
        }
        return [{
          id: `${params.idPrefix}-panel-${groupOrder}-${slug(label) || alternativeIndex + 1}`,
          label,
          children,
          source: { oliType: 'alternative', alternativeId: optionalText(alternative.id) || null },
        }];
      });
      if (panels.length === 0) {
        return [];
      }
      return [{
        id: `${params.idPrefix}-alternatives-${groupOrder}`,
        nodeType: 'atomic',
        atomType: 'panel-selector',
        selectedPanelId: panels[0]?.id,
        panels,
        layout: { visualPreset: 'panel-selector', control: 'tabs' },
        placement: { region: 'document', order: groupOrder },
        source: { oliType: 'alternatives' },
      }];
    }
    const purpose = optionalText(params.node.purpose);
    const convertedChildren = groupChildren
      .flatMap((child) => convertSlateNode({ ...params, node: child }));
    if (convertedChildren.length === 0) {
      return [];
    }
    return [{
      id: `${params.idPrefix}-group-${groupOrder}`,
      nodeType: 'group',
      groupType: purpose ? `oli-${slug(purpose)}` : 'oli-group',
      layout: {
        visualPreset: purpose || 'oli-group',
        glue: { mode: purpose || 'oli-group' },
      },
      placement: { region: 'document', order: groupOrder },
      children: convertedChildren,
      source: { oliType: type, purpose: purpose || null },
    }];
  }
  if (type === 'img') {
    params.counter.value += 1;
    return [{
      id: `${params.idPrefix}-image-${params.counter.value}`,
      nodeType: 'atomic',
      atomType: 'html-block',
      value: richTextToHtml(params.node),
      placement: { region: 'document', order: params.counter.value },
    }];
  }
  if ([
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
    'definition',
    'callout',
    'title',
    'page_link',
    'popup',
    'youtube',
    'iframe',
  ].includes(type)) {
    const text = type === 'ul' || type === 'ol'
      ? listNodeToPlainText(params.node)
      : richTextToPlainText(params.node).trim();
    if (!text && !['formula', 'page_link', 'youtube', 'iframe'].includes(type)) {
      return [];
    }
    params.counter.value += 1;
    return [{
      id: `${params.idPrefix}-${slug(type)}-${params.counter.value}`,
      nodeType: 'atomic',
      atomType: 'html-block',
      value: type === 'ul' || type === 'ol' ? listNodeToHtml(params.node) : richTextToHtml(params.node).trim(),
      placement: { region: 'document', order: params.counter.value },
    }];
  }
  const children = Array.isArray(params.node.children) ? params.node.children : [];
  return children.flatMap((child) => convertSlateNode({ ...params, node: child }));
}

function convertPage(params: {
  page: JsonRecord;
  pageIndex: number;
  sourceRoot: string;
  moduleSlug: string;
  productionRules: JsonRecord[];
  behaviorSteps: JsonRecord[];
  responseIntent: JsonRecord[];
  modelTargets: SparcModelTargetRegistry;
}): JsonRecord {
  const pageId = nonBlank(params.page.id, 'page.id');
  const title = nonBlank(params.page.title, 'page.title');
  const content = asRecord(params.page.content, 'page.content');
  const model = asArray(content.model, 'page.content.model');
  const counter = { value: 0 };
  const children: JsonRecord[] = [];
  for (const block of model) {
    children.push(...convertSlateNode({
      node: block,
      idPrefix: `node-page-${pageId}`,
      pageId,
      sourceRoot: params.sourceRoot,
      moduleSlug: params.moduleSlug,
      productionRules: params.productionRules,
      behaviorSteps: params.behaviorSteps,
      responseIntent: params.responseIntent,
      modelTargets: params.modelTargets,
      counter,
    }));
  }
  return {
    id: `node-page-${pageId}`,
    nodeType: 'group',
    groupType: 'section',
    label: title,
    placement: { region: 'document', order: params.pageIndex },
    layout: { visualPreset: 'section', density: 'comfortable' },
    children,
  source: { pageId, purpose: params.page.purpose ?? null },
  };
}

function clusterTargetForModelTarget(target: SparcModelTarget): JsonRecord {
  return {
    clusterIndex: target.clusterIndex,
    label: target.label,
    stimuliSetId: `sparc:${target.clusterKC}`,
    stimulusKC: target.stimulusKC,
    clusterKC: target.clusterKC,
    KCId: target.stimulusKC,
    KCDefault: target.stimulusKC,
    KCCluster: target.clusterKC,
    source: {
      activityId: target.activityId,
      partId: target.partId,
      ...(target.inputId ? { inputId: target.inputId } : {}),
      pageId: target.pageId,
      objectives: target.objectives,
    },
  };
}

function stimulusClusterForModelTarget(target: SparcModelTarget): JsonRecord {
  return {
    clusterid: target.clusterIndex,
    clustername: target.label,
    clusterKC: target.clusterKC,
    stims: [{
      stimulusid: 0,
      stimulusKC: target.stimulusKC,
      clusterKC: target.clusterKC,
      textStimulus: target.label,
      response: { correctResponse: '__SPARC_COMPLETED__' },
      source: {
        activityId: target.activityId,
        partId: target.partId,
        ...(target.inputId ? { inputId: target.inputId } : {}),
        pageId: target.pageId,
        objectives: target.objectives,
      },
    }],
  };
}

function emptyModuleNode(params: {
  moduleTitle: string;
  moduleId: string;
  order: number;
}): JsonRecord {
  return {
    id: `node-module-${params.moduleId}-empty-content`,
    nodeType: 'atomic',
    atomType: 'html-block',
    value: `<p>${escapeHtml(params.moduleTitle)} has no convertible OLI page content in this export.</p>`,
    placement: { region: 'document', order: params.order },
    source: {
      conversionIssue: 'empty-oli-module-content',
      moduleId: params.moduleId,
    },
  };
}

function uniqueProductionRuleIds(rules: readonly JsonRecord[]): JsonRecord[] {
  const occurrences = new Map<string, number>();
  return rules.map((rule) => {
    const id = nonBlank(rule.id, 'production rule id');
    const occurrence = (occurrences.get(id) ?? 0) + 1;
    occurrences.set(id, occurrence);
    return occurrence === 1 ? rule : { ...rule, id: `${id}.variant-${occurrence}` };
  });
}

function convertModule(context: ConversionContext): ConversionResult {
  const contentRoot = contentRootFor(context.sourceRoot);
  const fileIndex = buildJsonFileIndex(contentRoot);
  const hierarchy = readJson(path.join(contentRoot, '_hierarchy.json'));
  const moduleNode = asArray(hierarchy.children, '_hierarchy.children')
    .filter(isRecord)
    .find((child) => child.id === context.moduleId);
  if (!moduleNode) {
    throw new Error(`Module ${context.moduleId} not found`);
  }
  const moduleTitle = nonBlank(moduleNode.title, 'module.title');
  const moduleSlug = slug(moduleTitle);
  const itemRefs = asArray(moduleNode.children, 'module.children')
    .filter(isRecord)
    .filter((child) => child.type === 'item')
    .map((child) => nonBlank(child.idref, 'module child idref'));
  const productionRules: JsonRecord[] = [];
  const behaviorSteps: JsonRecord[] = [];
  const responseIntent: JsonRecord[] = [];
  const modelTargets = createModelTargetRegistry();
  const pageNodes = itemRefs.map((pageId, index) => {
    const pagePath = fileIndex.get(pageId);
    if (!pagePath) {
      throw new Error(`Page ${pageId} not found under ${contentRoot}`);
    }
    const page = readJson(pagePath);
    assertCoveredOliNodes(page, pagePath);
    return convertPage({
      page,
      pageIndex: index + 1,
      sourceRoot: context.sourceRoot,
      moduleSlug,
      productionRules,
      behaviorSteps,
      responseIntent,
      modelTargets,
    });
  });
  if (pageNodes.length === 0) {
    pageNodes.push(emptyModuleNode({
      moduleTitle,
      moduleId: context.moduleId,
      order: 1,
    }));
  }
  if (modelTargets.targets.length === 0) {
    ensureContentCompletionTarget({
      registry: modelTargets,
      moduleId: context.moduleId,
      moduleSlug,
      moduleTitle,
      pageId: itemRefs[0] || context.sparcPageId,
    });
  }
  const clusterTargets = modelTargets.targets.map(clusterTargetForModelTarget);
  const display: JsonRecord = {
    type: 'sparc',
    schema: 'tutorscript-sparc/2.0',
    unitType: 'sparc-intro-stats-variables',
    layout: {
      orientation: 'document',
      zones: [{ id: 'document', role: 'contiguous-page', region: 'center', flow: 'vertical', accepts: ['group', 'atomic'], ordered: true }],
      regions: { document: { anchor: 'center', flow: 'vertical', width: '100%' } },
    },
    nodes: pageNodes,
    behavior: { steps: behaviorSteps },
    response: {
      gradingMode: 'production-rules',
      intentByNode: responseIntent,
    },
    productionRules: uniqueProductionRuleIds(productionRules),
    source: {
      conversion: 'OLI flat JSON export to SPARC document page',
      moduleId: context.moduleId,
      moduleTitle,
      pageIds: itemRefs,
    },
  };
  display.clusterTargets = clusterTargets;
  const stimuli = {
    setspec: {
      lessonname: context.lessonName,
      clusters: modelTargets.targets.map(stimulusClusterForModelTarget),
      sparcPages: [{
        pageId: context.sparcPageId,
        display,
      }],
    },
  };
  const tdf = {
    tutor: {
      setspec: {
        lessonname: context.lessonName,
        stimulusfile: context.stimulusFile,
        userselect: 'true',
        lfparameter: '0.85',
        shuffleclusters: '0',
      },
      unit: [
        {
          unitname: `${moduleTitle} SPARC Page`,
          sparcsession: {
            clusterlist: clusterListForTargets(modelTargets.targets),
            unitMode: 'distance',
            calculateProbability: context.calculateProbability,
            pageId: context.sparcPageId,
          },
        },
      ],
    },
  };
  const conversionNotes = {
    sourceRoot: context.sourceRoot,
    module: { id: context.moduleId, title: moduleTitle, pageIds: itemRefs },
    rules: {
      multipleChoice: 'Activity with content.choices and no inputs becomes a SPARC multiple-choice group. Positive-score response legacyMatch gives the correct choice id.',
      targetedCata: 'Activity with content.type TargetedCATA becomes a checkbox-list group. content.authoring.correct[0] gives the set of selected choice ids; every choice becomes a checkbox node with expected true/false.',
      dropdown: 'Activity with content.inputs becomes a dropdown-list group. Each input partId maps to authoring.parts; the positive-score response legacyMatch maps through content.choices to the expected dropdown label.',
    },
    counts: {
      pages: pageNodes.length,
      modelTargets: modelTargets.targets.length,
      contentCompletionTarget: productionRules.length === 0 && responseIntent.length === 0,
      behaviorSteps: behaviorSteps.length,
      responseIntent: responseIntent.length,
      productionRules: productionRules.length,
    },
  };
  return { tdf, stimuli, conversionNotes };
}

function parseArgs(argv: string[]): CliOptions {
  const scriptDir = path.dirname(path.resolve(process.argv[1] || ''));
  const repoRoot = path.resolve(scriptDir, '..');
  const options: CliOptions = {
    sourceRoot: path.join(repoRoot, 'extracted_intro_to_stats_first_three_modules_l71p6'),
    moduleId: '97146',
    allModules: false,
    outputRoot: path.join(repoRoot, 'SPARC Intro Stats Variables'),
    lessonPrefix: 'SPARC Intro Stats',
    zip: true,
    calculateProbability: DEFAULT_SPARC_CALCULATE_PROBABILITY,
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
    } else if (arg === '--output-root') {
      options.outputRoot = path.resolve(argv[++index] || '');
    } else if (arg === '--lesson-prefix') {
      options.lessonPrefix = argv[++index] || '';
    } else if (arg === '--calculate-probability') {
      options.calculateProbability = argv[++index] || '';
      if (!options.calculateProbability.trim()) {
        throw new Error('--calculate-probability requires a non-empty JavaScript function body');
      }
    } else if (arg === '--no-zip') {
      options.zip = false;
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
  node --experimental-strip-types scripts/convert_oli_flat_module_to_sparc.ts [options]

Options:
  --source-root <path>    Extracted OLI export root.
  --module-id <id>       Convert one hierarchy module/container. Default: 97146.
  --all-modules          Convert every hierarchy module/container to one flat upload package.
  --output-root <path>   Upload package folder.
  --lesson-prefix <name> Lesson name prefix for generated all-module outputs.
  --calculate-probability <source>
                         SPARC adaptive probability function body.
  --no-zip              Write package folders without creating zip files.
`);
}

function contextForModule(options: CliOptions, moduleId: string, moduleIndex: number): ConversionContext {
  const title = moduleTitle(options.sourceRoot, moduleId);
  if (!options.allModules && moduleId === '97146') {
    return {
      sourceRoot: options.sourceRoot,
      moduleId,
      moduleNumber: moduleIndex + 1,
      outputRoot: options.outputRoot,
      auditRoot: `${options.outputRoot} Conversion Audit`,
      lessonName: 'SPARC Intro Stats Variables',
      sparcPageId: 'sparc-intro-stats-variables',
      stimulusFile: 'SPARC_Intro_Stats_Variables_stims.json',
      tdfFile: 'SPARC Intro Stats Variables_TDF.json',
      calculateProbability: options.calculateProbability,
    };
  }
  const moduleNumber = moduleIndex + 1;
  const moduleLabel = `Module ${String(moduleNumber).padStart(2, '0')}`;
  const lessonName = `${options.lessonPrefix} - ${moduleLabel} - ${title}`;
  const fileStem = safeFileName(lessonName);
  return {
    sourceRoot: options.sourceRoot,
    moduleId,
    moduleNumber,
    outputRoot: options.outputRoot,
    auditRoot: `${options.outputRoot} Conversion Audit`,
    lessonName,
    sparcPageId: slug(lessonName),
    stimulusFile: `${fileStem}_stims.json`,
    tdfFile: `${fileStem}_TDF.json`,
    calculateProbability: options.calculateProbability,
  };
}

function writeConversionResult(context: ConversionContext, result: ConversionResult): void {
  writeJson(path.join(context.outputRoot, context.tdfFile), result.tdf);
  writeJson(path.join(context.outputRoot, context.stimulusFile), result.stimuli);
  const notesStem = path.basename(context.tdfFile, '_TDF.json');
  writeJson(path.join(context.auditRoot, `${notesStem}_conversion-notes.json`), result.conversionNotes);
}

function verifyConversionOutput(outputRoot: string): void {
  const scriptDir = path.dirname(path.resolve(process.argv[1] || ''));
  execFileSync(process.execPath, [
    '--experimental-strip-types',
    path.join(scriptDir, 'verify_oli_sparc_conversion_output.ts'),
    '--package-root',
    outputRoot,
  ], {
    stdio: 'inherit',
  });
}

function zipConversionOutput(context: ConversionContext): void {
  const zipPath = `${context.outputRoot}.zip`;
  execFileSync('powershell', [
    '-NoProfile',
    '-Command',
    'Get-ChildItem -LiteralPath $env:MOFACTS_ZIP_SOURCE | Compress-Archive -DestinationPath $env:MOFACTS_ZIP_DEST -Force',
  ], {
    stdio: 'inherit',
    env: {
      ...process.env,
      MOFACTS_ZIP_SOURCE: context.outputRoot,
      MOFACTS_ZIP_DEST: zipPath,
    },
  });
}

function main(): void {
  const options = parseArgs(process.argv.slice(2));
  const moduleIds = options.allModules ? allModuleIds(options.sourceRoot) : [options.moduleId];
  assertPreflightReferences(options.sourceRoot, moduleIds);
  let lastContext: ConversionContext | null = null;
  for (const [index, moduleId] of moduleIds.entries()) {
    const context = contextForModule(options, moduleId, index);
    lastContext = context;
    const result = convertModule(context);
    writeConversionResult(context, result);
    if (!options.allModules) {
      verifyConversionOutput(context.outputRoot);
    }
    if (options.zip && !options.allModules) {
      zipConversionOutput(context);
    }
  }
  if (options.allModules && lastContext) {
    verifyConversionOutput(lastContext.outputRoot);
  }
  if (options.zip && options.allModules && lastContext) {
    zipConversionOutput(lastContext);
  }
}

main();
