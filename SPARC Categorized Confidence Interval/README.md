# SPARC Categorized Confidence Interval

New test packages for dynamic-instruction-agent-v2 and dynamic-instruction-student-v2. Both require admin access. Each extends the seven-expectation/three-misconception Dynamic Confidence Interval content with authored categories and six instructional choices: three compositions in text and MC formats. Student navigation to the next KC remains separate.

The two new TDF/page identities preserve the existing target texts and knowledge graph; the source packages are unchanged. Upload requires the matching category-aware application runtime. The ZIPs contain exactly their corresponding TDF and stimulus files. ZIPs are generated locally and ignored by this repository; the JSON files are the committed sources. To make an upload archive, zip the matching condition's TDF and stimulus JSON files together at the archive root, retaining their filenames. Saved packages and archive/source comparison do not establish application upload, generation, or learner delivery.

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
| M2 | fact-model | The interval means 95% of individual observations fall between 42 and 50. |
| M3 | model-rule | The interval means 95% of sample means, future sample means, or future confidence intervals will fall between 42 and 50. |

The category denotes the authored demand, including corrective understanding for misconceptions. It is not inferred from incidental facts in an explanation. See the main repository docs/sparc-instructional-cycle.md and the current wiki specification for the runtime and acceptance contract.
