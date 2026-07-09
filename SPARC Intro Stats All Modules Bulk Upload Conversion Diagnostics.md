# SPARC Intro Stats Conversion Diagnostics

Generated package: `SPARC Intro Stats All Modules Bulk Upload`

This catalog lists the expected conversion diagnostics in the generated 43-module Intro Stats SPARC package. These are content-source problems or intentionally explicit diagnostic placeholders, not structural SPARC verifier failures.

## Failure Categories

| Category | English description | Expected handling | Structural verifier impact |
| --- | --- | --- | --- |
| `missing-oli-activity-file` | An OLI page references an activity ID, but the extracted OLI export does not contain a matching activity JSON file. The converter keeps the page structure and inserts a visible diagnostic HTML block where the activity would have appeared. | Recover the missing activity JSON from the source export or accept the diagnostic placeholder if the source really omits it. | Non-blocking. The generated SPARC package remains structurally valid. |
| `empty-oli-module-content` | The module exists in the OLI module list, but the export has no convertible OLI page content for that module. The converter emits one diagnostic document node so the generated SPARC package is explicit rather than silently empty. | Confirm whether these late modules are intentionally empty/placeholders, or provide source page content before regenerating. | Non-blocking. The generated SPARC package remains structurally valid. |

## Expected Diagnostic Occurrences

| # | Category | Module | Generated file | Line | Node ID | OLI page ID | OLI activity ID | Notes |
| --- | --- | --- | --- | ---: | --- | --- | --- | --- |
| 1 | `missing-oli-activity-file` | Module 04 - Relationships between Variables | `SPARC Intro Stats - Module 04 - Relationships between Variables_stims.json` | 2490 | `node-missing-activity-97070-95613` | `97070` | `95613` | Page references an activity file missing from the extracted source. |
| 2 | `missing-oli-activity-file` | Module 04 - Relationships between Variables | `SPARC Intro Stats - Module 04 - Relationships between Variables_stims.json` | 2527 | `node-missing-activity-97070-95510` | `97070` | `95510` | Page references an activity file missing from the extracted source. |
| 3 | `missing-oli-activity-file` | Module 04 - Relationships between Variables | `SPARC Intro Stats - Module 04 - Relationships between Variables_stims.json` | 2564 | `node-missing-activity-97070-95947` | `97070` | `95947` | Page references an activity file missing from the extracted source. |
| 4 | `empty-oli-module-content` | Module 35 - Cross-Validation | `SPARC Intro Stats - Module 35 - Cross-Validation_stims.json` | 61 | `node-module-97435-empty-content` | n/a | n/a | Module has no convertible OLI page content in the export. |
| 5 | `empty-oli-module-content` | Module 36 - Bootstrapping | `SPARC Intro Stats - Module 36 - Bootstrapping_stims.json` | 61 | `node-module-97434-empty-content` | n/a | n/a | Module has no convertible OLI page content in the export. |
| 6 | `empty-oli-module-content` | Module 37 - Spearman's Rank-Order Correlation | `SPARC Intro Stats - Module 37 - Spearman’s Rank-Order Correlation_stims.json` | 61 | `node-module-97430-empty-content` | n/a | n/a | Module has no convertible OLI page content in the export. |
| 7 | `empty-oli-module-content` | Module 38 - Mann-Whitney U Test | `SPARC Intro Stats - Module 38 - Mann-Whitney U Test_stims.json` | 61 | `node-module-97437-empty-content` | n/a | n/a | Module has no convertible OLI page content in the export. |
| 8 | `empty-oli-module-content` | Module 39 - Wilcoxon Signed-Rank Test | `SPARC Intro Stats - Module 39 - Wilcoxon Signed-Rank Test_stims.json` | 61 | `node-module-97438-empty-content` | n/a | n/a | Module has no convertible OLI page content in the export. |
| 9 | `empty-oli-module-content` | Module 40 - Kruskal-Wallis Test | `SPARC Intro Stats - Module 40 - Kruskal-Wallis Test_stims.json` | 61 | `node-module-97439-empty-content` | n/a | n/a | Module has no convertible OLI page content in the export. |
| 10 | `empty-oli-module-content` | Module 41 - Spearman's Rank-Order Correlation | `SPARC Intro Stats - Module 41 - Spearman’s Rank-Order Correlation_stims.json` | 61 | `node-module-97440-empty-content` | n/a | n/a | Module has no convertible OLI page content in the export. |
| 11 | `empty-oli-module-content` | Module 42 - Friedman Test | `SPARC Intro Stats - Module 42 - Friedman Test_stims.json` | 61 | `node-module-97441-empty-content` | n/a | n/a | Module has no convertible OLI page content in the export. |

## Converter Locations

| Converter behavior | Source location |
| --- | --- |
| Build missing-activity diagnostic node | `scripts/convert_oli_flat_module_to_sparc.ts`, `buildMissingActivityDiagnostic` |
| Build empty-module diagnostic node | `scripts/convert_oli_flat_module_to_sparc.ts`, `emptyModuleNode` |
| Verify generated package structure | `scripts/verify_oli_sparc_conversion_output.ts` |

## Current Verification Snapshot

The package verifier passes with:

```text
tdfFiles: 43
clusters: 619
modelPracticeEffects: 2042
modeledIntentNodes: 1472
```
