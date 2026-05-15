# MoFaCTS Wiki Release Audit Plan

**Date:** 2026-04-24  
**Release target:** `v0.1.0-alpha.1`  
**Scope:** GitHub wiki readiness before the first public pre-1.0 release.

## Baseline

MoFaCTS, the Mobile Fact and Concept Training System, should be described publicly as a web-based adaptive learning system. Public documentation should align with the release-facing repository docs in `C:\dev\MoFaCTS` and the application source tree in `C:\dev\MoFaCTS\mofacts`.

The wiki should preserve useful existing content and avoid unnecessary expansion. Prefer corrections, consolidation, and navigation cleanup over creating new pages.

## Release Readiness Judgment

The wiki is not ready for `v0.1.0-alpha.1` until the blocking documentation drift below is corrected.

Blocking issues:

1. `License-Guidance.md` says MIT, but the current repo `LICENSE`, `CITATION.cff`, and `mofacts/package.json` identify `BUSL-1.1`.
2. Multiple pages still reference old `svelte-app/...` paths instead of `mofacts/...`.
3. `Local-Install.md` still presents `meteor run` as an optional workflow and omits the required full TypeScript check.
4. Public-facing pages should not make "smart flashcards" the primary product description, but student- and teacher-facing pages may use plain-language AI wording when it helps explain the experience. Deeper teacher, researcher, administrator, and developer pages should connect that language to adaptive learning, cognitive modeling, logistic-regression-style scheduling models, and the testing effect.
5. `_Sidebar.md`, `Home.md`, and `Remote-Install.md` link to missing `Production-Upgrade-Checklist`.

## Minimal Pre-Release Fixes

### License

Update `License-Guidance.md`:

- Replace MIT references with Business Source License 1.1.
- State that root `LICENSE` is canonical.
- Note that `CITATION.cff` and `mofacts/package.json` also identify `BUSL-1.1`.
- Preserve the `.deploy/LICENSE` provenance clarification for upstream deployment tooling.

Priority: release-blocking.

### Paths and Repository Layout

Update stale references:

- Replace `svelte-app/mofacts` with `mofacts`.
- Replace `C:\dev\mofacts\svelte-app\mofacts\...` with `C:\dev\MoFaCTS\mofacts\...`.
- Replace GitHub links under `blob/.../svelte-app/...` with repo-root paths such as:
  - `blob/main/CITATION.cff`
  - `blob/main/SECURITY.md`
  - `blob/main/mofacts/public/stimSchema.json`

Affected pages include:

- `Deployment-Guide.md`
- `Local-Install.md`
- `Settings-json-Reference.md`
- `Remote-Install.md`
- `Developer-Reference-Guide.md`
- `Data-Output.md`
- `Researcher-Guide.md`
- `Stimulus-files-(content).md`
- `Data-Privacy-IRB-FERPA-Notes.md`
- `AGENTS.md`
- `README.md`

Priority: release-blocking for deployment/local install/settings pages; important elsewhere.

### Deployment Guidance

Update `Deployment-Guide.md`:

- State that the canonical deployment workflow is Docker Compose under `mofacts/.deploy/`.
- Change commands to start from `mofacts/.deploy`.
- Link the repo-root `SECURITY.md`.
- Keep Docker Compose as the release-confidence deployment workflow.

Update `Remote-Install.md`:

- Treat it as a production-host example or subordinate runbook, not the canonical repo workflow.
- Update core asset paths to `mofacts/.deploy/...`.
- Remove or restore the missing `Production-Upgrade-Checklist` link.
- Keep warnings not to commit `.env`, settings files, secrets, API keys, SAML keys, Mongo credentials, or private deployment files.

Priority: release-blocking for canonical path wording; important for host-specific cleanup.

### Development Guidance

Update `Local-Install.md`:

- Use `mofacts/` as the app working directory.
- Include Node.js `22.x`, npm `10.x`, and Meteor `3.4`.
- Include baseline checks:

```bash
cd mofacts
npm ci
npm run lint
npm run typecheck
```

- Remove `meteor run` or clearly label it as manual Meteor framework debugging only, not release validation.
- Do not present local Meteor CLI workflows as release-confidence substitutes for Docker Compose under `mofacts/.deploy/`.

Update `Developer-Reference-Guide.md`:

- Replace `svelte-app/mofacts` with `mofacts`.
- Mention `npm run typecheck` alongside `npm run lint`.
- Align with current `docs/development.md`.

Priority: release-blocking for `Local-Install.md`; important for developer reference.

### Public Terminology

Use:

- `MoFaCTS`
- `Mobile Fact and Concept Training System` on first mention
- `web-based adaptive learning system`
- `Tutor Definition Files (TDFs)` on first mention
- `flashcard-like adaptive practice` or `smart flashcards` only when informal comparison is useful, especially on student-facing pages

Avoid:

- `intelligent tutoring system`
- `ITS` except inside bibliographic citations
- `Mobile Factual Cognition Training System`
- `MoFacts`
- `smart flashcards` as the primary product description
- `AI picks the optimal question` as a primary technical claim on developer/research/admin pages unless it is tied to configurable cognitive memory models or logistic-regression-style scheduling

Specific edits:

- `Home.md`: replace intro with the release-baseline description from `README.md`.
- `Student-Overview.md`: keep student-friendly "smart flashcards" and AI wording, but make the first sentence identify MoFaCTS as a web-based adaptive learning system and link the AI description to adaptive practice.
- `learningsession-(learning-units).md`: keep AI wording if useful, but connect it to configurable scheduling logic, cognitive memory models, and the testing effect for teacher/developer readers.
- `Admin-Reference.md`: replace `MoFacts` with `MoFaCTS` and `Tutor Description Format` with `Tutor Definition Files (TDFs)`.
- `Glossary.md`: define TDF as `Tutor Definition File`.
- `Trial-Types-Reference.md`: update first TDF expansion.
- Optional science links may be added later for the LKT paper or the LKT CRAN package, but do not add speculative new citations during this blocking cleanup unless they are verified and clearly useful.

Priority: important; release-blocking where the wording appears in first-screen/public overview pages.

### Navigation

Update `_Sidebar.md`, `Home.md`, and `Remote-Install.md`:

- Remove `Production-Upgrade-Checklist` links unless that page is intentionally restored.
- Keep current role-based organization.
- Do not create new pages unless a missing page is deliberately reinstated.

Priority: release-blocking for broken public navigation.

## Page Actions

| Page | Action |
|---|---|
| `Home.md` | Minor edit: release-baseline description, remove missing checklist link. |
| `_Sidebar.md` | Minor edit: remove missing checklist link. |
| `README.md` | Minor edit: update local path to `C:\dev\MoFaCTS`. |
| `AGENTS.md` | Minor edit: update local path and remove stale `svelte-app` framing. |
| `Student-Overview.md` | Important edit: make web-based adaptive learning system primary while preserving student-friendly smart flashcards/AI explanation. |
| `FAQ.md` | Minor edit: reduce deployment duplication if touched. |
| `Teacher-First-Hour.md` | Keep or minor terminology edit. |
| `Class-Setup-and-Assignment-Workflow.md` | Keep. |
| `Quick-Start-Content-Creation.md` | Keep or minor TDF terminology edit. |
| `Content-Creation-Reference-Tables.md` | Important edit: TDF terminology and tooltip/code references. |
| `TDF-Field-Reference.md` | Keep as discoverability alias. |
| `Stimulus-files-(content).md` | Minor edit: update schema link. |
| `Trial-Types-Reference.md` | Minor edit: TDF first mention. |
| `Audio-and-Speech-Settings.md` | Minor edit: keep config repo boundaries clear. |
| `Anki-Import-Guide.md` | Keep or minor edit. |
| `learningsession-(learning-units).md` | Important edit: terminology and stale `.js` reference. |
| `assessmentsession-(assessment-units).md` | Keep. |
| `videosession-(video-units-and-adaptive-logic).md` | Keep; optional post-release trimming. |
| `Learning-Algorithms-Reference.md` | Minor edit: update `.js` references where stale; keep `ITS 2006` citation title. |
| `Data-Output.md` | Important edit: update absolute code paths. |
| `Researcher-Guide.md` | Minor edit: update `CITATION.cff` link. |
| `Data-Privacy-IRB-FERPA-Notes.md` | Minor edit: remove stale source path and update `.ts` refs. |
| `Admin-Reference.md` | Important edit: MoFaCTS/TDF wording and stale generated prose. |
| `Settings-json-Reference.md` | Important edit: update source/deploy paths. |
| `Deployment-Guide.md` | Release-blocking edit: canonical `mofacts/.deploy` workflow. |
| `Remote-Install.md` | Important edit: make subordinate/host-specific and remove broken link. |
| `Local-Install.md` | Release-blocking edit: path, checks, and Meteor workflow wording. |
| `Developer-Reference-Guide.md` | Important edit: path and verification guidance. |
| `Troubleshooting.md` | Keep or minor link cleanup. |
| `Custom-Help-Page-Setup.md` | Keep. |
| `Experiment-Routes.md` | Keep. |
| `Glossary.md` | Important edit: TDF definition. |
| `License-Guidance.md` | Release-blocking edit: BUSL-1.1. |
| `MoFaCTS-Implementation-Cost-analysis.md` | Archive or clearly mark historical. |

## Recommended Structure

Keep the existing role-based wiki structure:

- Start: `Home`, `FAQ`, `Glossary`
- Students: `Student-Overview`
- Teachers/authors: `Teacher-First-Hour`, `Quick-Start-Content-Creation`, `Class-Setup-and-Assignment-Workflow`, `Anki-Import-Guide`
- Authoring reference: `Content-Creation-Reference-Tables`, `Stimulus-files-(content)`, `Trial-Types-Reference`, session pages, audio/speech
- Admin/deploy: `Deployment-Guide`, `Settings-json-Reference`, `Admin-Reference`, `Troubleshooting`
- Developers: `Local-Install`, `Developer-Reference-Guide`
- Researchers: `Researcher-Guide`, `Data-Output`, privacy notes

No new wiki pages are needed for release readiness.

## Optional Post-Release Cleanup

- Consolidate repeated deployment content between `Deployment-Guide.md`, `Local-Install.md`, and `Remote-Install.md`.
- Trim or split `videosession-(video-units-and-adaptive-logic).md` only if maintainers find it hard to navigate.
- Mark `MoFaCTS-Implementation-Cost-analysis.md` as historical or move it out of primary navigation.

## Implementation Pass Started

On 2026-04-24, the first blocking-cleanup pass began in the wiki repository:

- `License-Guidance.md` was updated to `BUSL-1.1`.
- Stale `svelte-app` and old local path references identified in the blocking audit were replaced.
- `Local-Install.md` was updated to remove the `meteor run` workflow and include `npm run typecheck`.
- Missing `Production-Upgrade-Checklist` links were removed.
- Student-facing AI/smart-flashcard language was preserved where useful, while the first product description was aligned to the web-based adaptive learning system framing.
