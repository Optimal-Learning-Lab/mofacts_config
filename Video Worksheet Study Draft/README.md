# Video Worksheet Study Draft

This mock package now uses the locally implemented worksheet schema and runtime. **It is not ready for study delivery:** `mock-lecture.mp4` is a generated test-only placeholder, and saved-history integration and browser interaction checks remain outstanding. No learner history was migrated.

## Confirmed worksheet behavior

- TutorScript multiple-choice questions remain active during work. Each answer or changed answer produces a normal, model-eligible answer-history record through the existing question/stimulus/model path, without updating the adaptive model during the worksheet. Earlier changes remain in history. **No answer means no answer record.**
- Correctness feedback is withheld during work. Ending work with **Submit and Continue** or the work deadline opens feedback; it does not batch-grade answers, write another set of answer records, or save a separate final-answer snapshot.
- Feedback reconstructs the latest recorded selection for each question in the relevant worksheet attempt on a read-only replica, preserving that attempt's realized question order. The correct-answer template overlays those learner responses. Unanswered questions remain blank on the learner replica, display the correct answer and an incorrect visual indication, and generate no fabricated answer or model record.
- Every actual appearance of the feedback page, including after a reload, produces a non-answer exposure record. Ordinary redraws and retries of the same write do not create additional exposures. This is an appearance event, unlike the current instruction history event written on Continue.
- Work and review durations are maximums. Participants may finish work early and may leave review early with **Continue**. Either deadline advances automatically. Persist phase, deadlines, attempt identity and realized question order for resume; reconstruct answers from normal history, not a second answer store.

## Authored examples and unchanged settings

The root refers to four condition TDFs: blocked pre/post and interspersed pre/post. Each uses the included short `mock-lecture.mp4`: four original colored cards labeled TEST VIDEO ONLY and Mock concept 1–4, with quiet tones at concept boundaries. It is 640×360 with approximately 20 seconds of playback (container duration 20.0333 seconds), about 1.1 MB, and contains no external footage or learner data. Blocked pre/post use one 20-question worksheet at 0/20 seconds respectively. Interspersed pre uses five-question worksheets at 0/5/10/15 seconds; interspersed post uses them at 5/10/15/20 seconds. These shortened mock-video checkpoints replace the former ten-minute schedule for quick testing. Actual lecture media and its matching checkpoint times must replace these placeholders before study delivery.

Work limits remain **600 seconds for 20 questions** and **150 seconds for five questions**; the current review setting remains **300 seconds**. Questions are randomized within each worksheet; lecture/concept order and answer-choice order are unchanged. Both early-continuation actions are intended for participants, not only testing. Video restrictions and the two-day same-link/same-ID return instructions are unchanged. The root uses `not-max` assignment: a server-owned shuffled block of conditions below the highest count, with all conditions eligible when tied. Returning participants retain their assignment.

`Video_Worksheet_Study_stims.json` uses existing TutorScript semantic multiple-choice definitions, `clusterIndex` and `kc` references, and normal stimulus answers. The compiler supplies response intents and normal model-practice effects. `worksheet-contract.json` is explanatory review material, not an additional authoring format or runtime input. Its obsolete final-grading answer table has been removed; it owns no question answers.

## Configuration and implementation

`videosession.checkpointBehavior = "worksheet"` selects the shared worksheet lifecycle. `videosession.worksheet.pageIds` contains only page IDs, one per `questiontimes` entry. Times must be nonnegative and strictly increasing. Each referenced TutorScript page owns `display.worksheet`: `workDurationSeconds`, `reviewDurationSeconds`, and `randomizeQuestions`. Early continuation is always available, so there is no separate early-continue flag. The same page can be used by a standalone `sparcsession` unit.

Normal `display.text` and `response.correctResponse` stimulus authoring replaces the draft's internal runtime fields. Runtime code derives stimulus identities through the normal loader. The condition-routing root has no `unit` array, as required by the existing schema. Its four condition references and other study settings are preserved; assignment now uses `not-max`.

The shared controller owns work/review deadlines, persisted order, history reconstruction and completion. Answer records use the normal SPARC model-practice bridge; it deliberately does not apply the live model-update request. Non-answer start/review/exposure/complete records retain lifecycle metadata in the existing SPARC history extension. No final-answer snapshot or second question table exists. The server deduplicates retries by worksheet scope/sequence and rejects conflicting writes. Reopening the same learner/lesson/unit/page/checkpoint scope resumes it, including completed state; it does not automatically create another attempt.

## Verification scope

The five TDFs and stimulus file pass the generated JSON schemas. All seven JSON files parse. Four conditions, five pages, 20 stimuli, 40 question placements and checkpoint/page references resolve. The canonical page resolver, semantic compiler and worksheet controller produce 40 normal model-eligible answer records using synthetic test writes; this is not verification of persisted Meteor history. Focused lifecycle and retry tests, full-app typecheck, lint and component compilation pass.

Still required before study delivery: replace the synthetic test video with actual lecture media and matching timestamps; verify actual HTML5/YouTube delivery, mouse/keyboard/fullscreen transitions, deadlines and reloads through the supported local workflow; run saved-history integration coverage with fresh explicit authorization for each `npm run test:ci` invocation. The local app starts and its landing page renders, but worksheet browser delivery has not been verified. No production deployment, commit or push was performed.
