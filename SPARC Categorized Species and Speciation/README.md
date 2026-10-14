# SPARC Categorized Species and Speciation

Created October 14, 2026 from the current SPARC Categorized Confidence Interval agent/student templates. This package implements the accepted 24-KC Chapter 21 revision in the existing categorized v2 SPARC system.

## Files and use

- Agent: `SPARC_Categorized_Species_and_Speciation_agent_TDF.json` and `SPARC_Categorized_Species_and_Speciation_agent_stims.json`, packaged together in `SPARC_Categorized_Species_and_Speciation_agent.zip`.
- Student: `SPARC_Categorized_Species_and_Speciation_student_TDF.json` and `SPARC_Categorized_Species_and_Speciation_student_stims.json`, packaged together in `SPARC_Categorized_Species_and_Speciation_student.zip`.
- [Complete English lesson review](Lesson%20review.html), generated from the saved payload and accompanied by source page mappings below.

Each ZIP contains only its matching TDF and stimulus JSON at archive root. Upload the chosen version through MoFaCTS content upload to a runtime supporting dynamic-instruction-agent-v2 and dynamic-instruction-student-v2. Both retain the template's admin-only access. No uploaded tdfId is copied; page, lesson, source, and KC identities are biology-specific. The two conditions intentionally use the same semantic biology KC identities, as the template does; they have distinct lesson/page identities. This does not establish cross-condition learner-state isolation, which depends on application attempt/model identity.

## Ordered learner experience

1. One SPARC adaptive unit covering all 24 chapter KCs. There is no fixed opening scenario or separate prequiz/postquiz. Startup targets S15 (From divergence to reproductive isolation), the most central authored KC, then follows the existing condition's selection behavior. This is not a fixed KC sequence.
2. The agent condition chooses an instructional move; the student condition exposes the existing six choices and next-KC navigation. The six choices combine three compositions (question; explanation and question; explanation with worked example or figure and question) with text and multiple-choice response formats.
3. Completion occurs when all 24 targets meet coverage 0.8 and no authored misconception remains active at support 0.2, OR when 96 learner turns are reached. A turn-limit ending is not mastery or complete coverage.

## Settings inherited and adapted

Retained: `openai/gpt-5.4-nano`, the template's calculateProbability expression, unitMode distance, minimumProgress 0.3, thresholds 0.33/0.67/0.67 with coverage 0.8 and misconception support 0.2, target-selection weights frontier 0.5/coherence 0.3/centrality 0.2, and the existing display nodes/layout/controller adapter. No probability coefficients were fitted for biology.

Adapted: title/topic/identities/tags; 24 clusters and expectations; 20 diagnostic misconceptions; all 24 required targets; 96-turn cap (four per KC as an initial budget, not a per-KC allocation or validated sufficiency estimate); and a complete biology relationship graph. The cap replaces the seven-KC template's 25 turns to give the larger chapter room for instruction and repair.

The current runtime maintains one coverage score for each KC. Required facets are written directly into each expectation with cumulative-evidence instructions. There is no invented facet-state field or deterministic subfacet mastery gate. The live preview must assess whether the provider generates sufficiently varied questions and scores these multi-facet expectations appropriately.

## Authored targets

Fact/model/rule labels denote intended learning demands. Model + rule is a principle. Category and authored text are identical across both conditions.

| KC | Target | Category | Chapter pages |
| --- | --- | --- | --- |
| S01 | Species as distinguishable but changing groups | model | 434-435 |
| S02 | Biological species membership | fact-rule | 435-436 |
| S03 | Genetic exchange and species cohesion | model | 435-436, 445-446 |
| S04 | When reproductive evidence is usable | rule | 436-438 |
| S05 | Identification by appearance and its exceptions | fact-rule | 436 |
| S06 | Identification using DNA | rule | 436 |
| S07 | Incomplete species boundaries | model | 437 |
| S08 | Species identification through ecology | model-rule | 437-438 |
| S09 | Species identification through ancestry | model-rule | 437-438 |
| S10 | Recognizing reproductive barriers | fact-rule | 438-439 |
| S11 | Barriers to encountering or accepting a mate | model | 438-439 |
| S12 | Mechanical and gametic barriers | model | 439 |
| S13 | Failure after fertilization | model | 439 |
| S14 | Reproductive investment and barrier timing | model | 439 |
| S15 | From divergence to reproductive isolation | fact-model | 440-441 |
| S16 | Geographic routes to separation | fact-rule | 440-441, 447 |
| S17 | Divergence in a small peripheral population | model-rule | 441-443 |
| S18 | Adaptive radiation | model-rule | 443-445 |
| S19 | Co-speciation | model | 443, 445-446 |
| S20 | Divergence despite geographic overlap | model | 445-447 |
| S21 | Evidence about a speciation history | model-rule | 441-442, 447, 450 |
| S22 | New species through hybridization | model-rule | 447-449 |
| S23 | New species through chromosome-set changes | fact-model-rule | 448-449 |
| S24 | The relationship between selection and speciation | model-rule | 434, 449-453 |

## Source coverage

Source: Morris et al., Biology: How Life Works, fourth edition (2023), Chapter 21, [publisher sample](https://prod-cat-files.macmillan.cloud/CMS/SampleChapters/402518043f7e6a04529ce12a085b196578ba59c4/2023-ml-morris-HLW4e-ch21_flipbook/index.html). Targets are original paraphrases. No textbook pages, figures, or Achieve questions are redistributed.

- Section 21.1: S01–S09; section 21.2: S10–S14; section 21.3: S15–S24, reusing S03 for gene flow.
- Figures 21.1→S01/S05; 21.2→S02; 21.3→S05/S13; 21.4→S07; 21.5→S11; 21.6→S15; 21.7→S16/S21; 21.8→S17; 21.9–21.10→S18; 21.11→S19; 21.12→S20; 21.13→S16/S17/S20; 21.14→S22; 21.15→S23; 21.16→S22.
- Table 21.1→S10–S13. Self-assessment 1–5→S01–S09; 6–7→S10–S13; 8→S15; 9→S03/S16/S20; 10→S16; 11→S17/S18; 12→S16/S21. Summary and Visual Synthesis 6 integrate existing targets, especially S03/S15/S24.
- Earlier knowledge: mutation, selection, drift, fixation, fertilization, meiosis, chromosome pairing/sets, and nondisjunction. Their new connections to speciation remain in the targets. Niche and simple ancestry-tree interpretation are taught to the extent introduced here; forward references do not establish prior mastery.
- Names, historical dates, chromosome counts for particular organisms, and locations are examples or supplied givens rather than separate recall targets. New biological distinctions are explicitly included. The chapter's models are not converted into universal claims that any DNA difference, any niche difference, any shared ancestor, any hybrid, or any chromosome change settles species identity.

## Relationship graph rationale

The graph expresses conceptual association, not prerequisites or a fixed sequence. Every ordered non-self pair is present (24 × 23 = 552 relationships); symmetric links share one strength. Explicit strong links (0.9) connect direct definitions, mechanisms, or evidence dependencies; moderate links (0.6) connect substantial supporting concepts. Every other pair has an authored weak chapter-context link (0.1). These are transparent authoring judgments, not empirical fitted weights. Each centrality is the mean of its 23 outgoing strengths, rounded to six decimals, following the template's normalized weighted-degree convention. The initial highest node is S15 (0.608696).

| Pair | Strength |
| --- | --- |
| S01 ↔ S02 | 0.9 |
| S01 ↔ S03 | 0.6 |
| S01 ↔ S04 | 0.6 |
| S01 ↔ S05 | 0.9 |
| S01 ↔ S07 | 0.6 |
| S01 ↔ S09 | 0.9 |
| S01 ↔ S15 | 0.6 |
| S01 ↔ S24 | 0.6 |
| S02 ↔ S03 | 0.9 |
| S02 ↔ S04 | 0.9 |
| S02 ↔ S05 | 0.6 |
| S02 ↔ S06 | 0.6 |
| S02 ↔ S07 | 0.9 |
| S02 ↔ S08 | 0.6 |
| S02 ↔ S09 | 0.6 |
| S02 ↔ S10 | 0.9 |
| S02 ↔ S13 | 0.6 |
| S02 ↔ S15 | 0.9 |
| S02 ↔ S22 | 0.6 |
| S03 ↔ S07 | 0.9 |
| S03 ↔ S09 | 0.6 |
| S03 ↔ S11 | 0.6 |
| S03 ↔ S13 | 0.6 |
| S03 ↔ S15 | 0.9 |
| S03 ↔ S16 | 0.6 |
| S03 ↔ S17 | 0.6 |
| S03 ↔ S18 | 0.6 |
| S03 ↔ S19 | 0.6 |
| S03 ↔ S20 | 0.9 |
| S03 ↔ S21 | 0.6 |
| S03 ↔ S22 | 0.6 |
| S03 ↔ S23 | 0.6 |
| S03 ↔ S24 | 0.6 |
| S04 ↔ S05 | 0.9 |
| S04 ↔ S06 | 0.9 |
| S04 ↔ S07 | 0.6 |
| S04 ↔ S08 | 0.9 |
| S04 ↔ S09 | 0.9 |
| S04 ↔ S21 | 0.6 |
| S05 ↔ S06 | 0.9 |
| S05 ↔ S07 | 0.6 |
| S05 ↔ S17 | 0.6 |
| S06 ↔ S09 | 0.6 |
| S06 ↔ S21 | 0.6 |
| S07 ↔ S13 | 0.6 |
| S07 ↔ S15 | 0.6 |
| S07 ↔ S20 | 0.6 |
| S07 ↔ S22 | 0.6 |
| S07 ↔ S23 | 0.6 |
| S08 ↔ S09 | 0.9 |
| S08 ↔ S11 | 0.6 |
| S08 ↔ S17 | 0.6 |
| S08 ↔ S18 | 0.9 |
| S08 ↔ S19 | 0.6 |
| S08 ↔ S20 | 0.9 |
| S08 ↔ S22 | 0.6 |
| S09 ↔ S15 | 0.6 |
| S09 ↔ S18 | 0.6 |
| S09 ↔ S19 | 0.9 |
| S09 ↔ S21 | 0.9 |
| S09 ↔ S22 | 0.6 |
| S10 ↔ S11 | 0.9 |
| S10 ↔ S12 | 0.9 |
| S10 ↔ S13 | 0.9 |
| S10 ↔ S14 | 0.9 |
| S10 ↔ S15 | 0.6 |
| S10 ↔ S20 | 0.6 |
| S10 ↔ S23 | 0.6 |
| S11 ↔ S14 | 0.6 |
| S11 ↔ S15 | 0.6 |
| S11 ↔ S16 | 0.9 |
| S11 ↔ S17 | 0.6 |
| S11 ↔ S19 | 0.6 |
| S11 ↔ S20 | 0.6 |
| S12 ↔ S13 | 0.9 |
| S12 ↔ S14 | 0.6 |
| S12 ↔ S15 | 0.6 |
| S12 ↔ S23 | 0.6 |
| S13 ↔ S14 | 0.9 |
| S13 ↔ S15 | 0.9 |
| S13 ↔ S20 | 0.6 |
| S13 ↔ S22 | 0.9 |
| S13 ↔ S23 | 0.9 |
| S15 ↔ S16 | 0.9 |
| S15 ↔ S17 | 0.9 |
| S15 ↔ S18 | 0.6 |
| S15 ↔ S19 | 0.6 |
| S15 ↔ S20 | 0.9 |
| S15 ↔ S21 | 0.6 |
| S15 ↔ S22 | 0.9 |
| S15 ↔ S23 | 0.9 |
| S15 ↔ S24 | 0.9 |
| S16 ↔ S17 | 0.9 |
| S16 ↔ S18 | 0.6 |
| S16 ↔ S19 | 0.6 |
| S16 ↔ S20 | 0.6 |
| S16 ↔ S21 | 0.9 |
| S16 ↔ S22 | 0.6 |
| S16 ↔ S23 | 0.6 |
| S16 ↔ S24 | 0.6 |
| S17 ↔ S18 | 0.9 |
| S17 ↔ S21 | 0.6 |
| S17 ↔ S24 | 0.6 |
| S18 ↔ S19 | 0.6 |
| S18 ↔ S20 | 0.9 |
| S18 ↔ S21 | 0.6 |
| S18 ↔ S22 | 0.6 |
| S18 ↔ S24 | 0.9 |
| S19 ↔ S20 | 0.6 |
| S19 ↔ S21 | 0.9 |
| S20 ↔ S21 | 0.9 |
| S20 ↔ S22 | 0.6 |
| S20 ↔ S23 | 0.6 |
| S20 ↔ S24 | 0.9 |
| S21 ↔ S22 | 0.6 |
| S21 ↔ S23 | 0.6 |
| S21 ↔ S24 | 0.6 |
| S22 ↔ S23 | 0.9 |
| S22 ↔ S24 | 0.6 |
| S23 ↔ S24 | 0.6 |

## Evidence level

Live run-throughs and persistence retests were performed on October 14, 2026. Both packages were uploaded privately through MoFaCTS on localhost. The initial scored-response failure (SPARC extensions above 16,384 bytes) was repaired in application source using transactional, change-only score history. The agent version saved two scored responses and resumed with the same conversation, selected answers, next question, scores, and turn count. The student version saved three responses, including partial knowledge, an activated misconception, and its repair to zero, with matching state after reload. See [Testing run-throughs](Testing%20run-throughs.md) for exact evidence and remaining checks. A complete 24-KC learner run-through has not been performed.

The repository remains passive storage; application upload owns content validation. The modern v2 content template was retained. The runtime repair passed 214 focused checks and, after aligning two stale prompt assertions, 241 combined client/history checks, full application type checking, and lint. No full Meteor/CI invocation was run for this repair. All six student choices, full chapter traversal, and live graduation remain unverified; one generated figure had a contrast issue. Git commit and push were authorized after local verification. No production upload, public publication, or deployment was performed.
