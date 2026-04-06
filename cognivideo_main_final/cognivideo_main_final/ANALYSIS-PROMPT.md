# GPT Prompt: CogniVideo TDF Compatibility Analysis

---

## Context

MoFaCTS is a research-grade adaptive learning system undergoing a full architecture migration from a Meteor/Blaze **legacy-app** to a **Svelte-app** (still Meteor on the server). Configuration is driven by **TDF files** — JSON documents that specify session structure, UI settings, adaptive logic, and video integration. The file under review is a German-language science experiment TDF: `CogniVideo_TDF_pretest+adaptive+correct_LH_main.json`.

---

## The TDF Under Analysis

```json
{
  "tutor": {
    "setspec": {
      "lessonname": "Experimentiervideos zu Keimung: Gruppe 2 main-CA",
      "userselect": "true",
      "stimulusfile": "CogniVideo_stim_allQuestions_main.json",
      "experimentTarget": "haupt-gruppe2",
      "lfparameter": ".85",
      "hintsEnabled": false,
      "tags": ["correct", "video", "adaptive"],
      "uiSettings": {
        "displayReviewTimeoutAsBarOrText": "false",
        "displayPerformanceDuringTrial": false,
        "displayReadyPromptTimeoutAsBarOrText": "false",
        "displayCardTimeoutAsBarOrText": false,
        "displayTimeOutDuringStudy": false,
        "displayUserAnswerAtTop": false,
        "displayPerformanceDuringStudy": false,
        "displayCorrectAnswerInCenter": false,
        "singleLineFeedback": false,
        "feedbackDisplayPosition": "bottom",
        "incorrectColor": "darkorange",
        "correctColor": "green",
        "stimuliPosition": "top",
        "inputPlaceholderText": "Antworte hier",
        "lastVideoModalText": "Das ist das letzte Video. Melde dich bei der Lehrperson, wenn du fertig bist.",
        "displayUserAnswerInFeedback": "false",
        "simplefeedbackOnCorrect": "false",
        "simplefeedbackOnIncorrect": "false",
        "suppressFeedbackDisplay": "true",
        "instructionsTitleDisplay": "Keimung von Samen in Brackwasser",
        "continueButtonText": "Weiter"
      },
      "unitTemplate": [
        {
          "buttonorder": "random",
          "unitname": "correct_cress_adaptive",
          "unitinstructions": "...",
          "continueButtonText": "Weiter",
          "videosession": {
            "videosource": "https://youtu.be/RJMLK5dIowM",
            "questions": [],
            "questiontimes": []
          },
          "deliveryparams": { "drill": 2000000, "correctprompt": 2000, "reviewstudy": 2000 }
        },
        {
          "buttonorder": "random",
          "unitname": "correct_wheat_adaptive",
          "unitinstructions": "...",
          "videosession": {
            "videosource": "https://youtu.be/sDuhU3eEa5o",
            "questions": [],
            "questiontimes": []
          },
          "deliveryparams": { "drill": 2000000, "correctprompt": 2000, "reviewstudy": 2000 }
        }
      ]
    },
    "unit": [
      {
        "buttonorder": "random",
        "unitname": "pretest",
        "unitinstructions": "...",
        "adaptive": ["2,t", "3,t"],
        "adaptiveUnitTemplate": [0, 1],
        "buttontrial": "false",
        "assessmentsession": {
          "randomizegroups": "false",
          "clusterlist": "0-24",
          "permutefinalresult": "0-0",
          "assignrandomclusters": "false",
          "conditiontemplatesbygroup": {
            "groupnames": "A",
            "clustersrepeated": "1",
            "templatesrepeated": "25",
            "group": ["0,b,t,0 0,b,t,0 ... 0,f,t,0"],
            "initialpositions": "A_1 A_2 ... A_25"
          }
        },
        "adaptiveLogic": {
          "2": [
            "IF TRUE THEN C25S0 AT 66",
            "IF NOT C1S0 OR NOT C5S0 OR NOT C9S0 OR NOT C13S0 OR NOT C17S0 OR NOT C21S0 THEN C26S0 AT 92",
            "IF NOT C1S0 OR NOT C5S0 OR NOT C9S0 OR NOT C13S0 OR NOT C17S0 OR NOT C21S0 THEN C27S0 AT 387",
            "IF NOT C2S0 OR NOT C6S0 OR NOT C10S0 OR NOT C14S0 OR NOT C18S0 OR NOT C22S0 THEN C28S0 AT 458",
            "IF NOT C2S0 OR NOT C6S0 OR NOT C10S0 OR NOT C14S0 OR NOT C18S0 OR NOT C22S0 THEN C29S0 AT 464",
            "IF NOT C3S0 OR NOT C7S0 OR NOT C11S0 OR NOT C15S0 OR NOT C19S0 OR NOT C23S0 THEN C30S0 AT 480",
            "IF NOT C3S0 OR NOT C7S0 OR NOT C11S0 OR NOT C15S0 OR NOT C19S0 OR NOT C23S0 THEN C31S0 AT 497"
          ],
          "3": [
            "IF TRUE THEN C32S0 AT 48",
            "IF NOT C1S0 OR NOT C5S0 OR NOT C9S0 OR NOT C13S0 OR NOT C17S0 OR NOT C21S0 THEN C33S0 AT 85",
            "IF NOT C1S0 OR NOT C5S0 OR NOT C9S0 OR NOT C13S0 OR NOT C17S0 OR NOT C21S0 THEN C34S0 AT 383",
            "IF NOT C2S0 OR NOT C6S0 OR NOT C10S0 OR NOT C14S0 OR NOT C18S0 OR NOT C22S0 THEN C35S0 AT 451",
            "IF NOT C2S0 OR NOT C6S0 OR NOT C10S0 OR NOT C14S0 OR NOT C18S0 OR NOT C22S0 THEN C36S0 AT 462",
            "IF NOT C3S0 OR NOT C7S0 OR NOT C11S0 OR NOT C15S0 OR NOT C19S0 OR NOT C23S0 THEN C37S0 AT 475",
            "IF NOT C3S0 OR NOT C7S0 OR NOT C11S0 OR NOT C15S0 OR NOT C19S0 OR NOT C23S0 THEN C38S0 AT 491"
          ]
        },
        "deliveryparams": { "drill": 2000000, "correctprompt": 2000, "reviewstudy": 2000 }
      },
      {
        "unitname": "Final",
        "unitinstructions": "<h3>Danke!</h3> ...",
        "countcompletion": true
      }
    ]
  }
}
```

---

## Session Architecture

The session has three phases:

1. **Pretest** (unit[0]): An `assessmentsession` with 25 button-choice questions (clusters 0–24). All assigned to a single group `A` with one condition template `0,b,t,0` (button trial, scored) and a final free-recall item. This unit carries `adaptive` and `adaptiveLogic` — it determines what gets injected into units 2 and 3.

2. **Video units** (units 2 and 3, injected adaptively): Built from `setspec.unitTemplate[0]` and `setspec.unitTemplate[1]` respectively. Each is a `videosession` pointing to a YouTube video. The adaptive logic determines which stimulus clusters (question indices) and at what video timestamps (the `AT n` values, in seconds) questions appear.

3. **Final** (unit[1] in the static array, effectively last): `countcompletion: true`, no session content.

---

## What Is Known About the New System (Svelte-app)

The following is factual ground truth about how the svelte-app handles fields in this TDF. Use this to anchor your analysis — do not contradict or speculate beyond it.

### uiSettings field status (from `uiSettingsValidator.ts`)

| Field | Status in svelte-app |
|---|---|
| `displayReviewTimeoutAsBarOrText` | **DEPRECATED** — replaced by `displayTimeoutBar` (boolean) |
| `displayPerformanceDuringTrial` | **DEPRECATED** — replaced by `displayPerformance` |
| `displayReadyPromptTimeoutAsBarOrText` | **DEPRECATED** — replaced by `displayTimeoutBar` |
| `displayCardTimeoutAsBarOrText` | **DEPRECATED** — replaced by `displayTimeoutBar` |
| `displayTimeOutDuringStudy` | **DEPRECATED** — timeout now controlled by `deliveryParams` |
| `displayUserAnswerAtTop` | **SILENTLY DROPPED** — not in deprecated list, not in kept-fields; classified "unknown" |
| `displayPerformanceDuringStudy` | **DEPRECATED** — replaced by `displayPerformance` |
| `displayCorrectAnswerInCenter` | **DEPRECATED** — "not implemented in Svelte; feedback handles answer display" |
| `singleLineFeedback` | **KEPT** — validated boolean, passes through |
| `feedbackDisplayPosition` | **DEPRECATED** — "auto-computed based on layout" |
| `incorrectColor` | **KEPT** — validated as hex or CSS var token |
| `correctColor` | **KEPT** — same |
| `stimuliPosition` | **KEPT** — accepts `'top'` or `'left'` |
| `inputPlaceholderText` | **KEPT** — max 100 chars |
| `lastVideoModalText` | **DEPRECATED** — "video session uses default modal text" |
| `displayUserAnswerInFeedback` | **KEPT** — accepts boolean, `'onCorrect'`, `'onIncorrect'` |
| `simplefeedbackOnCorrect` | **DEPRECATED** — replaced by `onlyShowSimpleFeedback` |
| `simplefeedbackOnIncorrect` | **DEPRECATED** — same |
| `suppressFeedbackDisplay` | **DEPRECATED** — "set feedback timeout to 0ms in deliveryParams instead" |
| `instructionsTitleDisplay` | **DEPRECATED** — "not used in deployments; instructions simplified" |
| `continueButtonText` | **KEPT** — max 100 chars |

### Other field status

| Field | Status |
|---|---|
| `lfparameter` | **SUPPORTED** — consumed by answer-assessment fuzzy match logic |
| `hintsEnabled` | **UPLOAD-TIME ONLY** — schema-known but not read at session runtime |
| `userselect` | **SUPPORTED** — server enforces TDF visibility |
| `experimentTarget` | **SUPPORTED** — used for experiment routing and Mongo indexing |
| `adaptive`, `adaptiveLogic`, `adaptiveUnitTemplate` | **SUPPORTED** — wired in `unitProgression.ts` |
| `buttontrial` | **SUPPORTED** |
| All `assessmentsession` sub-fields | **SUPPORTED** — consumed in `unitEngine.ts` |
| `videosession.videosource`, `questions`, `questiontimes` | **SUPPORTED** — consumed in `svelteInit.ts:initVideoSessionData()` |
| `deliveryparams.drill/correctprompt/reviewstudy` | **SUPPORTED** — consumed in `timeoutUtils.ts` |
| `countcompletion` | **SUPPORTED** — used in `unitProgression.ts` for load-balancing |

### Known bugs in svelte-app adaptive video path

1. **DynamicAssets video URLs not resolved** — `videosource` is passed raw; the legacy-app resolved non-HTTP sources via `DynamicAssets.findOne({name:...}).link()`. YouTube URLs work fine, but this gap is documented.
2. **First checkpoint rewind does not fire** — `videoSession.isActive` is not set until after the first checkpoint is reached.
3. **`rewindOnIncorrect` flag ignored** — Svelte always rewinds on incorrect regardless of config.
4. **Checkpoint index fallback silently drifts** — `VideoSessionMode` falls back to `nextCheckpointIndex` when `questionIndices` is short, with no warning.

### Legacy-app (legacy-app/mofacts) behavior
The legacy-app handles the same adaptive video logic in `adaptiveQuestionLogic.js` + `card.js`. DynamicAssets resolution is present. The same rule-evaluation engine is used. The legacy code is no longer actively maintained but runs correctly for this TDF pattern.

---

## Your Tasks

### 1. Full compatibility assessment

For each field and feature in this TDF, produce a compatibility table with columns:

- **Field / Feature** — exact path (e.g., `uiSettings.suppressFeedbackDisplay`, `unit[0].adaptiveLogic`)
- **Status in svelte-app** — one of: Fully supported / Supported with caveats / Deprecated (with replacement) / Silently dropped / Broken (known bug)
- **Behavioral impact** — what actually happens at runtime with this TDF in the new system
- **Recommended action** — keep as-is / update field / migrate to replacement / remove

Organize the table in sections: (a) setspec-level, (b) uiSettings, (c) unit-level / assessmentsession, (d) adaptive mechanism, (e) videosession.

### 2. Adaptive video logic: description and operational walkthrough

Provide a clear, detailed, human-readable explanation of how the `2,3` adaptive video system works in this TDF — suitable for a researcher who authored this TDF several years ago and wants to re-understand it. Cover:

- What the pretest outcome determines
- The meaning of `adaptive: ["2,t", "3,t"]` and `adaptiveUnitTemplate: [0, 1]` together
- How the `adaptiveLogic` keys `"2"` and `"3"` map to the two video units
- The IF-THEN rule syntax: `C<n>S<m>` notation, `OR`/`AND`/`NOT` operators, `AT <seconds>` semantics
- What each cluster group (C1/C5/C9/..., C2/C6/C10/..., C3/C7/C11/...) likely represents in terms of pretest knowledge dimensions (based on the cluster index groupings — do not invent content, but describe the structural pattern)
- The unconditional `IF TRUE THEN C<n>S0 AT <t>` rules and what they imply about baseline question delivery
- What the resulting video session would look like for a student who got all questions wrong vs. all questions right
- How checkpoints and `questiontimes` are populated from the `AT` values

### 3. Legacy vs. svelte-app risk assessment for this TDF

Given the known bugs in the svelte-app adaptive video path, assess:

- Which behaviors of this specific TDF are at risk of breaking silently (not erroring, just running incorrectly)
- Whether the four documented bugs affect this TDF's adaptive logic as structured
- Whether the legacy-app would handle this TDF correctly where the svelte-app does not
- A clear recommendation: can this TDF be run on svelte-app as-is for a study, or should it remain on legacy-app, or does it require specific fixes first? What is the minimum set of fixes needed for safe deployment?

### 4. uiSettings migration block

For each deprecated uiSettings field in this TDF, produce a ready-to-apply migration: the exact old field to remove and the exact new field(s) to add (with values appropriate to the intent inferred from the current field values). Use the replacement names documented above.

---

## Output Format

- Use structured Markdown with clear section headings.
- Compatibility table must be a proper Markdown table.
- The adaptive logic walkthrough (task 2) should read as clear prose — not a bullet list, not code — written for a researcher rather than a developer.
- The risk assessment (task 3) should end with a single clear "Recommendation" callout block.
- The migration block (task 4) should show before/after JSON snippets.

Do not speculate beyond the factual ground truth provided above. Where the behavior is uncertain or undocumented, say so explicitly.
