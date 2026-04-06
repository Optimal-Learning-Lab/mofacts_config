# CogniVideo Migration Plan

## Scope

This plan covers the four CogniVideo lesson variants in this folder:

- `CogniVideo_TDF_pretest+adaptive+correct_LH_main.json`
- `CogniVideo_TDF_pretest+adaptive+erroneous_LH_main.json`
- `CogniVideo_TDF_pretest+static+correct_LH_main.json`
- `CogniVideo_TDF_pretest+static+erroneous_LH_main.json`

It also covers the Svelte MoFaCTS code paths that must be stable for these lessons to run correctly.

## Workstream Framing

This effort is really two related pieces of work:

- **TDF migration:** normalize the four lesson files so they use Svelte-safe configuration fields and values.
- **Svelte refactor / hardening:** repair and clean up the adaptive video path so the migrated lessons behave correctly.

So "migration plan" is the right label for the content side, but on the application side the work is better described as a targeted refactor plus bug-fix pass.

## Design Readout

The collection appears to implement a 2x2 between-subjects design:

- factor 1: `correct` vs `erroneous`
- factor 2: `static` vs `adaptive`

Within every condition, the lesson structure is fixed:

1. pretest
2. cress video
3. wheat video
4. final completion unit

The manipulation is not video order. The manipulation is:

- whether the videos are the correct or erroneous version
- whether all embedded questions are always shown (`static`) or selectively omitted based on pretest performance (`adaptive`)

## Key Migration Findings

### TDF collection

- There is no post-test in these four TDFs.
- The `static` files hardcode the full embedded-question schedule for both videos.
- The `adaptive` files use the same question pools and timestamps, but populate video questions after the pretest using `adaptive`, `adaptiveUnitTemplate`, and `adaptiveLogic`.
- The adaptive files do not change video order, video topic, or intervention type. They only change which embedded questions are included.

### Svelte compatibility

The main structural TDF features used by these lessons are present in Svelte. The `uiSettings` block contains several deprecated fields that should be migrated or removed. The adaptive insertion mechanism itself is not the risky part. This TDF uses the standard pattern that both systems understand: pretest first, adaptive rules evaluated, template units injected into runtime positions 2 and 3, final static unit last. The Svelte runtime handles that correctly. The silent risks are in the video-answer path after those checkpoints have already been created.

#### Per-bug risk assessment for this TDF

**Bug 1 — DynamicAssets video-source not resolved: NOT APPLICABLE.**
Both `videosource` values are HTTPS YouTube URLs. This TDF does not depend on DynamicAssets resolution for video playback.

**Bug 2 — First checkpoint rewind does not fire: APPLIES. High risk.**
Both video units begin with an unconditional first checkpoint (`IF TRUE THEN C25S0 AT 66` for cress, `IF TRUE THEN C32S0 AT 48` for wheat). The documented `isActive` timing bug means the rewind event for that first checkpoint is skipped if a learner answers incorrectly. This is a silent behavioral change, not a hard failure. Every learner in every adaptive condition is affected because the baseline question is always injected.

**Bug 3 — `rewindOnIncorrect` ignored: APPLIES. High risk.**
This TDF does not set a `rewindOnIncorrect` flag in either video template. The Svelte runtime ignores that field anyway, and always rewinds on incorrect answers regardless of config. Because the intended rewind policy is not encoded here, there is no way to detect the divergence from logs. This changes student experience, pacing, and likely time-on-task without any error message. In a study setting that is exactly the kind of silent divergence that matters for data interpretation.

**Bug 4 — Checkpoint index drift: NOT LIKELY TO FIRE AS WRITTEN.**
Each adaptive rule adds exactly one cluster reference and one `AT` timestamp together. Questions and questiontimes are generated in lockstep, so the length mismatch that triggers the drift fallback is not produced by this TDF. This remains a future-edit hazard: if someone later adds a cluster reference without a matching timestamp or vice versa, the fallback is silent.

## Migration Goal

Move this lesson family to a Svelte-compatible state while preserving:

- the 2x2 condition structure
- the fixed cress-then-wheat order
- the distinction between `static` and `adaptive`
- the distinction between `correct` and `erroneous`

## Recommended Rollout Strategy

### Phase 1: Refactor and stabilize the Svelte runtime before moving adaptive lessons

Do not treat TDF cleanup alone as sufficient for the adaptive lessons. The adaptive video route should be fixed first in Svelte.

Target files to review and patch:

- [uiSettingsValidator.ts](/c:/dev/mofacts/svelte-app/mofacts/client/views/experiment/svelte/utils/uiSettingsValidator.ts)
- [unitProgression.ts](/c:/dev/mofacts/svelte-app/mofacts/client/views/experiment/svelte/services/unitProgression.ts)
- [svelteInit.ts](/c:/dev/mofacts/svelte-app/mofacts/client/views/experiment/svelte/services/svelteInit.ts)
- [adaptiveQuestionLogic.ts](/c:/dev/mofacts/svelte-app/mofacts/client/views/experiment/adaptiveQuestionLogic.ts)
- [VideoSessionMode.svelte](/c:/dev/mofacts/svelte-app/mofacts/client/views/experiment/svelte/components/VideoSessionMode.svelte)
- [CardScreen.svelte](/c:/dev/mofacts/svelte-app/mofacts/client/views/experiment/svelte/components/CardScreen.svelte)
- [actions.ts](/c:/dev/mofacts/svelte-app/mofacts/client/views/experiment/svelte/machine/actions.ts)
- [cardMachine.ts](/c:/dev/mofacts/svelte-app/mofacts/client/views/experiment/svelte/machine/cardMachine.ts)

Required refactor outcomes:

1. First checkpoint answers in video mode must participate in the rewind flow.
2. `rewindOnIncorrect` must behave according to config rather than a hardwired fallback.
3. Video checkpoint/question index mismatches should surface a warning or fail loudly instead of drifting silently.
4. `uiSettings` deprecations should remain non-breaking during transition, but migration warnings should stay visible.

### Phase 2: Migrate and normalize the TDF collection

Apply the same cleanup pattern to all four CogniVideo TDFs.

#### 1. Migrate deprecated `uiSettings`

Remove:

- `displayReviewTimeoutAsBarOrText`
- `displayReadyPromptTimeoutAsBarOrText`
- `displayCardTimeoutAsBarOrText`
- `displayPerformanceDuringTrial`
- `displayPerformanceDuringStudy`
- `displayTimeOutDuringStudy`
- `displayCorrectAnswerInCenter`
- `feedbackDisplayPosition`
- `lastVideoModalText`
- `simplefeedbackOnCorrect`
- `simplefeedbackOnIncorrect`
- `suppressFeedbackDisplay`
- `instructionsTitleDisplay`

Also remove the silently dropped field:

- `displayUserAnswerAtTop`

Add or replace with:

- `displayTimeoutBar: false`
- `displayPerformance: false`
- `onlyShowSimpleFeedback: false`

`suppressFeedbackDisplay: "true"` is active in all four TDFs. The current delivery params have `correctprompt: 2000` and `reviewstudy: 2000`, which would produce 2-second feedback displays once the suppression field is removed. To preserve existing behavior, set these unit `deliveryparams` fields to zero:

- `correctprompt: 0`
- `reviewstudy: 0`

This is required, not optional. Apply consistently to:

- the pretest unit
- both video units or both adaptive video templates

#### 2. Normalize kept `uiSettings` values that currently fail validation

Update:

- `correctColor: "green"`
- `incorrectColor: "darkorange"`

to accepted Svelte formats such as:

- hex colors, or
- CSS variable tokens like `var(--success-color)`

Without this change, Svelte will fall back to defaults.

#### 3. Consolidate redundant per-unit fields

The adaptive templates currently include unit-level `continueButtonText` in some places. This field is supported in Svelte (validated, KEPT), but having it in both `setspec.uiSettings` and individual unit templates risks inconsistency. Verify whether unit-level values override the setspec value at runtime before removing them; if override behavior is not needed, prefer one source of truth:

- keep `setspec.uiSettings.continueButtonText`
- remove unit-level `continueButtonText` only after confirming the setspec value is applied

### Phase 3: Preserve the experimental logic exactly

Do not alter the following during migration:

- pretest cluster coverage
- adaptive trigger families
- video order
- video URLs
- question timestamps
- condition naming and routing tags

For the adaptive files specifically, preserve the current relationship:

- `static` = full question schedule always present
- `adaptive` = baseline question always present, conditional pairs inserted by pretest-family misses

This means the following adaptive structures should remain semantically unchanged:

- `adaptive: ["2,t", "3,t"]`
- `adaptiveUnitTemplate: [0, 1]`
- `adaptiveLogic` rule sets for keys `"2"` and `"3"`

### Phase 4: Validate each condition as an experiment, not just as JSON

Each lesson variant should be run through a scripted acceptance pass.

#### Static variants

Verify that:

- pretest loads
- cress video loads second
- wheat video loads third
- all authored question timestamps fire
- the final unit completes normally

Static conditions to validate:

- `pretest+static+correct`
- `pretest+static+erroneous`

#### Adaptive variants

Verify at least these learner profiles:

1. all relevant pretest item families answered correctly
2. first trigger family missed
3. second trigger family missed
4. third trigger family missed
5. all trigger families missed

For each profile, confirm:

- expected adaptive questions are inserted
- omitted questions do not appear
- timestamps match authored `AT` values
- first checkpoint incorrect answer follows the intended rewind behavior
- later incorrect answers follow the intended rewind behavior

Adaptive conditions to validate:

- `pretest+adaptive+correct`
- `pretest+adaptive+erroneous`

## Condition-Specific Notes

### Correct conditions

- Cress uses clusters `25-31`
- Wheat uses clusters `32-38`

### Erroneous conditions

- Cress uses clusters `25-29,39,40`
- Wheat uses clusters `32-36,41,42`

Interpretation for migration purposes:

- `correct` and `erroneous` are distinct content conditions and should remain separate TDFs
- `erroneous` should not be collapsed into `correct` with altered scoring

## Minimum Safe Deployment Rule

### Safe to migrate now

Static conditions (`pretest+static+correct`, `pretest+static+erroneous`) do not involve adaptive insertion and do not have embedded checkpoint questions, so bugs 2 and 3 do not apply to them. These can be migrated as soon as the TDF `uiSettings` cleanup is complete and basic video playback is validated.

### Not safe to migrate as-is

Adaptive conditions (`pretest+adaptive+correct`, `pretest+adaptive+erroneous`) are blocked by bugs 2 and 3:

- **Bug 2** must be fixed: the `isActive` flag must be set before the first checkpoint so that a first-checkpoint incorrect answer enters the rewind flow correctly.
- **Bug 3** must be resolved: either fix Svelte to honor the `rewindOnIncorrect` config flag, or make an explicit authoring decision — add `rewindOnIncorrect` to the two video templates with the intended value, and verify Svelte applies it. Deploying without resolving this means rewind behavior in the study is uncontrolled.

Neither of these is a hard crash. Both are silent divergences from the intended design. In a non-study context they might be acceptable. For research data collection they are not.

## Concrete Work Plan

1. Refactor and patch the Svelte adaptive video checkpoint/rewind behavior.
2. Add or keep warning visibility for deprecated and invalid `uiSettings`.
3. Migrate all four TDF `uiSettings` blocks to Svelte-safe fields.
4. Normalize kept color values to Svelte-valid formats.
5. Run a four-condition validation matrix.
6. Pilot the two static conditions first if a phased release is needed.
7. Move the two adaptive conditions only after the Svelte refactor verifies cleanly.
8. Update wiki documentation if deployment guidance changes for adaptive video units.

## Suggested Deliverables

- cleaned TDF copies for all four conditions
- Svelte fixes for adaptive video rewind behavior
- a short validation checklist with pass/fail results per condition
- optional wiki update in [videosession-(video-units-and-adaptive-logic).md](/c:/Users/ppavl/OneDrive/Active%20projects/mofacts.wiki/videosession-(video-units-and-adaptive-logic).md) if migration behavior or authoring guidance changes

## Open Questions To Resolve During Execution

- Whether feedback suppression is truly desired in these lessons, or whether the existing deprecated field is leftover legacy noise.
- Whether the unit-level `continueButtonText` is still relied on anywhere outside the current Svelte runtime.
- Whether the erroneous adaptive second template should be renamed for clarity, since it currently uses the name `correct_wheat_adaptive` while pointing to the erroneous wheat video.
