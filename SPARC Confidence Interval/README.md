# SPARC Confidence Interval

The editable TDF and stimulus JSON files are in this folder. The [agent upload ZIP](../SPARC_Confidence_Interval_agent.zip) and [student upload ZIP](../SPARC_Confidence_Interval_student.zip) are directly in `C:\dev\mofacts_config`, alongside the other upload packages.

New test packages for dynamic-instruction-agent-v2 and dynamic-instruction-student-v2. Both require admin access. Each extends the seven-expectation/three-misconception Dynamic Confidence Interval content with authored categories and six instructional choices: three compositions in text and MC formats. Student navigation to the next KC remains separate.

The two new TDF/page identities retain the existing target meanings; the source packages are unchanged. Misconception wording refers to the computed interval without depending on endpoints from the removed opening scenario. Upload requires the matching category-aware application runtime. The ZIPs contain exactly their corresponding TDF and stimulus files. ZIPs are generated locally and ignored by this repository; the JSON files are the committed sources. To make an upload archive, zip the matching condition's TDF and stimulus JSON files together at the archive root, retaining their filenames. Saved packages and archive/source comparison do not establish application upload, generation, or learner delivery.

## Starting instruction

These units have no fixed opening scenario or focal question. The authored `dialogue.source.topic` supplies lesson context. Both units set `sparcsession.startingKC` to `dynamic.stats-confidence-interval-001.kc.a`: constructing an interval as estimate ± critical value × standard error.

Canonical upload generates the complete relationship graph from expectation-text embeddings and saves an exact maximum-weight Hamiltonian path with a fixed as the starting endpoint. The resulting order is **a → d → e1 → e3 → e2 → b → c**, with total relationship strength **4.355836** on the current generated graph. Graph values and the path are server-generated, not supplied by these packages. The former supplied graph and ranking weights have been removed.

Practice selects the first KC in the saved path below the existing coverage criterion (0.8), skipping incidentally covered KCs. Automatic units generate the selected instructional move; student-selected units offer the six existing moves and separate next-KC navigation in chain order. Misconception priority and instructional move/assistance selection are unchanged. Existing accepted decisions and histories remain available for resume.

Starting explanations briefly orient the concept in the lesson topic. Questions supply their own necessary givens. No learner assessment or feedback occurs before the first answer. Existing attempts resume without an additional opening move.

## Authored categories

| Target | Category | Learning demand |
| --- | --- | --- |
| e1 | model-rule | Repeated-sampling interpretation assumes random samples and the same interval-construction method across repetitions. |
| e2 | model | The confidence level describes the long-run proportion of constructed intervals that contain the true population mean. |
| e3 | fact-model | A computed confidence interval either contains the fixed true population mean or it does not. |
| a | rule | Construct a confidence interval by extending critical value × standard error on each side of the parameter estimate. |
| b | model-rule | With confidence level and population variability held fixed, margin of error decreases in proportion to 1/√n. |
| c | fact-rule | When population standard deviation is unknown and estimated from the sample, a mean interval uses a t multiplier with n − 1 degrees of freedom rather than the known-σ normal multiplier. |
| d | rule | The normal-approximation proportion interval requires sufficiently many observations in both outcome categories. A large total sample alone is insufficient. |
| M1 | model | There is a 95% probability that the true mean lies inside this specific interval. |
| M2 | fact-model | The interval means 95% of individual observations fall inside the computed interval. |
| M3 | model-rule | The interval means 95% of sample means, future sample means, or future confidence intervals will fall inside the computed interval. |

The category denotes the authored demand, including corrective understanding for misconceptions. It is not inferred from incidental facts in an explanation. See the main repository docs/sparc-instructional-cycle.md and the current wiki specification for the runtime and acceptance contract.
