# SPARC Dynamic Confidence Interval

These are new admin-only agent-selected and student-selected lessons, with seven expectations and three misconceptions. The original Confidence Interval packages remain intact.

Each TDF uses its matching stimulus file:

| Condition | TDF | Stimulus file | Policy |
| --- | --- | --- | --- |
| Agent | `SPARC_Dynamic_Confidence_Interval_agent_TDF.json` | `SPARC_Dynamic_Confidence_Interval_agent_stims.json` | `dynamic-instruction-agent-v1` |
| Student | `SPARC_Dynamic_Confidence_Interval_student_TDF.json` | `SPARC_Dynamic_Confidence_Interval_student_stims.json` | `dynamic-instruction-student-v1` |

Both use `sparc-autotutor-v1` at policy version 1. The three instructional moves have total assistance 0, 1.8, and 2.77 logits. Agent selection uses the existing calculation with a fixed 0.8 target and 0.2 initial knowledge/floor. Feedback precedes selection in both conditions. The student also has separate next-KC navigation. No forgetting model or worksheet sequence is added.

The original E1–E3 and M1–M3 wording is retained exactly. The four additions cover interval construction, sample size and margin of error, t-versus-normal method selection, and proportion-interval normal-approximation conditions. The canned opening remains the original 95% interval `[42, 50]` question. Misconception meaning applies across generated cases, rather than matching literal numbers.

The graph has complete symmetric relationships and centralities derived from their average strengths. These authored conceptual weights can be refined independently of the unchanged graph-selection algorithm; they do not define a fixed instructional sequence or new mastery prerequisites.

Status: saved locally and checked against the application's upload-time content contract and runtime rule dispatch. Both variants have been uploaded privately to localhost; live AI/browser acceptance is partial. Application checks and browser findings are recorded in the implementation plan and wiki. No deployment has occurred. Use the existing OpenRouter configuration and private image-generation infrastructure when testing figures. The TDF's retained general scheduler configuration does not govern the production-owned KC selection or assistance calculation.

October 12 integration verification: the authorized Meteor suite passed 16 harness checks, 795 server tests (15 pending), and 1,104 client tests (7 pending), with zero server or client failures. The compatible application now uses Sunburst 2.5 Medium and a shared embedding-based library for complete teaching figures. A local synthetic student trial generated a figure, switched expectations, and reused byte-identical pixels in a distinct move. A complete graduation walkthrough and deployment remain separate from these checks.
