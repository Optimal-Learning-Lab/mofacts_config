# Statistics Priority Flashcards: upload and progressive setup

Prepared September 8, 2026. The upload file is `Statistics Priority Flashcards Units 01-34.zip` in this folder. It contains 34 independent TDF lessons and 34 matching stimulus JSON files, all at the ZIP root, covering 421 cards. Upload the ZIP intact; it is not a ZIP of smaller ZIPs.

## Upload

1. Open the MoFaCTS content uploader and select this single ZIP. This submits all 34 lessons together. The current uploader also allows selecting multiple ZIPs, which it processes sequentially, but that is unnecessary here.
2. If prompted, complete your public content-creator display name in your profile and return to the uploader.
3. Check that the upload results show all 34 lessons successfully imported. Lesson names start with `Statistics Priority Flashcards - Unit 01` through `Unit 34`.
4. Download and retain the current packages after import. These initial TDFs intentionally omit lesson IDs; MoFaCTS assigns them on import. Use the downloaded packages, with their assigned identities, for later updates. Re-uploading the original ID-less ZIP is not an identity-preserving update.

## Progressive course assignment

In Course Assignments, create the progressive assignment and add the 34 imported lessons in numeric order, Unit 01 through Unit 34. Configure your desired assignment release and completion requirements there. Each TDF contains only the cards first assigned to that course unit; the progressive system composes the authorized sequence of units. Do not duplicate prerequisite cards into later stimulus files.

Each lesson has the required instruction unit followed by one standard learning session. A course unit is a separate TDF lesson; the two internal TDF units are the instruction and practice screens. All lessons have a stable practice-unit name and distinct semantic cluster identities. Positive lesson time limits and trial caps are absent, as required by the current progressive eligibility rules. Public self-selection is disabled; access is through assignments.

## Card content and practice settings

The source is `Priority Flashcards 421.xlsx`, checked against the saved 421-card selection. The workbook's term and definition columns are reversed for practice: the definition is the displayed prompt and the term is the expected response. Unit assignments come from the first-occurrence glossary state. All 421 source pairs are preserved. HTML-sensitive characters are escaped solely to preserve their displayed text.

Each cluster contains one card. Cards have no hints, distractors, figures, source captions, or supplementary explanations. The only instruction is “Read the definition. Type the matching term.” Speech input and prompt audio are disabled.

The standard A&P Openstax Chapter 1 Terms configuration supplies the adaptive scheduling formula, distance mode, 0.85 fuzzy-match threshold, and study/drill/review timing: 10 seconds for initial study and drill, 5 seconds for review, and 0.5 seconds for correct confirmation. Its positive practice time limit was changed to zero for progressive compatibility. Standard answer feedback remains enabled.

## Sources and verification

Editable configurations, `Unit Manifest.csv`, and `Card Sources.csv` are in `C:\dev\mofacts_config\Statistics Priority Flashcards Units 01-34`. The source textbook is Enhanced Intro Stats; reading order and textbook mapping remain documented in `Glossary Progress.md` and the glossary Sources sheet. No new terminology or definitions were added for this package.

The completed ZIP was read by the current application's actual ZIP parser, which identified exactly 34 TDFs and 34 stimulus files. All 68 files passed the current public JSON schemas. All 34 lessons passed the current progressive eligibility function with an import-shaped canonical stimulus identity; actual canonical identities will be assigned during import. All 421 knowledge-component identities are distinct.

These are local package and compatibility checks. No live upload, course-assignment creation, or learner-session test was performed.

Runtime references inspected: `mofacts/client/views/experimentSetup/contentUpload.ts`, `mofacts/server/lib/packageParser.ts`, `mofacts/server/lib/packageTdfIdentity.ts`, `mofacts/server/lib/packageUploadPersistence.ts`, `mofacts/common/progressiveAssignments.ts`, `mofacts/client/lib/progressiveLessonComposer.ts`, and `mofacts/public/tdfSchema.json` and `stimSchema.json` in `C:\dev\MoFaCTS`.
