# Species and Speciation: live run-throughs

Date: October 14, 2026. Environment: the existing localhost MoFaCTS watcher at http://localhost:3200. Synthetic learner responses under the existing local test/admin account. Both packages were imported privately through the application's content upload UI.

## Current result after change-history repair

Both versions now save scored responses and reload the complete conversation and learner state successfully in the local application. The chapter-sized assessment persistence failure described below has been repaired in application source. This is local acceptance of the tested paths, not a complete 24-KC traversal or production release.

| Retest | Agent-selected | Student-selected |
| --- | --- | --- |
| Successfully scored responses | 2 multiple-choice answers | 3 answers: partial text, incorrect multiple choice, text repair |
| Reload after scoring | Exact conversation, selected options, next question, progress, and turn count restored | Exact conversation, selected answer, menu, progress, and turn count restored |
| Continue after reload | Second answer saved; feedback and next question generated | Subsequent instructional choice and answer saved; misconception repair continued |
| Durable KC coverage | S13 0.25; S15 0.7 then 0.75; S07 0.25 | Initial one-facet response earned S15 0.25; later broad repair earned additional partial coverage |
| Durable misconception evidence | No active misconception in these answers | M02 activated at 1, restored after reload, targeted for repair, then saved and restored at 0 |
| Final displayed progress | Expectations 1.25/24; misconceptions 0/20; 2 turns | Expectations 3.2/24; misconceptions 0/20; 3 turns |
| Score-change rows | 4 across 2 assessments | 10 across 3 assessments |
| Largest observed SPARC extension | 4,767 bytes | 5,924 bytes |

The displayed fractional expectation total is aggregate coverage, not a count of fully mastered KCs. In the final agent reload, the database retained exactly 67 history rows, including 2 assessment markers and 4 score-change rows. Reload created no extra records or model gains. The student history contained 30 rows, including 3 assessment markers and 10 score-change rows. Other dialogue, controller, and per-target model records remain necessary for full resume.

Application persistence now writes one row per changed KC coverage or misconception-support value, followed by a separate assessment marker containing the response and derived turn/controller facts. Unchanged values carry forward through replay; a return to zero is a saved change. All rows for an assessment are accepted in one Mongo transaction. Stable identities make identical retries idempotent; conflicts fail explicitly. Loading supports both the new change rows and existing bundled assessment histories, without rewriting prior records.

Verification: 214 focused checks passed using `node scripts/sparcAutoTutorRules.test.cjs --include-history-contracts`, including transaction rollback, identical and conflicting retries, bounded records, authorization/scope checks, interruption after accepted assessment, replay, and deep comparison of loaded learner/model state. Full application type checking and lint passed; lint retained 28 existing vendor warnings and passed the 318-surface security contract. Before commit, the two stale provider-prompt assertions were aligned with the implemented “Lesson context” wording. The combined client and history suite then passed all 241 checks using both --include-client-contracts and --include-history-contracts. Full application type checking and lint passed again. No new full Meteor/CI invocation was run for this repair.

## Initial result before repair (retained evidence)

Both versions start and generate instruction, but both fail while saving the first scored response. Neither has passed a complete learner run-through.

| Check | Agent-selected | Student-selected |
| --- | --- | --- |
| Application upload | Passed; lesson listed after import | Passed; lesson listed after import |
| Starting KC | S15, as authored | S15, as authored |
| Initial interaction | Automatically selected explanation + figure + multiple-choice question | Offered all six instructional choices and next-KC navigation |
| Generation exercised | Explanation, generated schematic, four-option question | Question-only text response |
| Content observed | Correct distinction among separation, divergence, partial isolation, and subspecies; one defensible correct option | Question addressed the same distinctions without supplying the answer |
| Resume exercised | Returned to the saved explanation, figure, and same MC question through the practice menu | Not tested after a successfully scored response |
| Response tested | Selected the correct MC explanation | Submitted only: “The differentiated forms are called subspecies.” |
| Saving the response | Failed: SPARC extension 18,566 bytes exceeds 16,384 | Failed: SPARC extension 20,125 bytes exceeds 16,384 |
| Scored continuation/completion | Blocked | Blocked |

The student answer intentionally demonstrated only one facet. Because persistence failed, this run does not establish whether partial knowledge receives an appropriate durable coverage score. No full-turn assessment, misconception repair, next-target transition after scoring, or graduation behavior is claimed as verified.

## Confirmed runtime boundary

The canonical history contract sets a 16 KiB budget per component extension in `C:\dev\MoFaCTS\learning-components\runtime\historyEnvelope.ts`. The instructional cycle assembles all expectation and misconception score facts plus derived controller facts and the learner utterance into a single `:assessment` state-transition record in `learning-components/units/sparcsession/sparcInstructionalCycle.ts`.

`createSparcLearnerResponseScoreFacts` supplies a score fact for every known KC and diagnostic misconception, carrying prior values for those not changed. With 24 KCs and 20 misconceptions, the observed assessment records exceed the enforced extension budget. The separate per-target model-update records already present in the cycle do not split this earlier assessment checkpoint.

The initial diagnosis called for a runtime persistence design that retains the complete assessment in bounded, replayable records, with an explicit completion/acceptance boundary. Retry must reuse the accepted assessment without a second provider evaluation or duplicated model gains. The implemented repair above follows that contract; the original record-size limit remains in force.

## Additional observed issue

In the current dark theme, parts of the generated agent teaching figure have dark labels against a dark background and are difficult to read at the displayed size. The right-side light panels remain readable. This is an observed rendering/generation-quality issue in this one figure, not an estimate of general figure reliability.

## Evidence and remaining work

Screenshots and UI-state observations are saved at:

`C:\Users\ppavl\OneDrive - The University of Memphis\SPARC\.working\species-speciation-2026-10-14\testing`

- `student-history-limit.png`: first free-text response failure.
- `agent-startup.png`: generated agent lesson and figure.
- `agent-history-limit.png`: first MC response failure.
- `run-events.json`: synthetic test observations, without credentials.
- `student-delta-resume.png`: restored partial score and student interaction.
- `student-repaired-resume.png`: restored misconception repair and three scored turns.
- `agent-delta-resume-final.png`: restored agent conversation, selected answers, next question, and two-turn progress.
- `change-history-summary.json`: minimized database counts, score changes, and record sizes for the two synthetic local lessons.
- `history-contracts.log`: 214 passing focused checks.
- `combined-contracts.log`: 241 passing combined client and history checks before commit.

The browser is left at the resumed agent lesson. Uploaded lessons and test attempts remain available locally; no production upload, public publication, deployment, or history deletion was performed. Git commit and push were subsequently authorized by the user. Existing application working-tree changes were preserved.

Partial answers, correct and incorrect multiple choice, misconception activation and repair, reload after scoring, and continuation after reload passed the retests above. Live testing has not exercised every student choice, next-KC navigation, all 24 KCs, or graduation. The generated figure's observed contrast issue also remains open. Automated completion coverage is separate from a complete live chapter run-through.
