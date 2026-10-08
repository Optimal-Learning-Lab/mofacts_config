# CogniVideo Main Final

Cleaned local source for the supplied `cognivideo_main_final.zip` (SHA-256 `202F49724EA464B04C39124F98CE6D0949DB98E90B474225F4FB4204EE74942C`). The original download is unchanged. `../CogniVideo Main Final.zip` contains the four TDFs, shared stimulus JSON and 24 original JPEGs, without the redundant nested `main.zip`.

The four independent experiment entries remain CS (correct/static), CA (correct/adaptive), ES (erroneous/static) and EA (erroneous/adaptive). Public visibility and experiment targets are preserved from the supplied ZIP. Adaptive associations, checkpoint times, video URLs, response keys, distractors, cluster order and image bytes are unchanged.

Repairs:

- Replace six malformed `<h3/>` closing tags with `</h3>`.
- Clarify that selection questions have one correct option and the final prequiz question needs written text.
- Use canonical `deliverySettings`, retaining German UI labels and the authored green/dark-orange colors as `#008000` and `#ff8c00`.
- Remove obsolete UI settings, including the feedback-suppression switch. Trial type and duration control feedback.
- Keep all video questions as drills with `correctprompt: 2000` and `reviewstudy: 2000`, including the former 12000-ms ES outlier. Prequiz entries remain test trials.
- Name the EA wheat template `erroneous_wheat_adaptive`, matching its condition. Existing saved generated sequences are not rewritten by this source cleanup.

Do not upload this ID-less source ZIP over an existing production lesson as an implicit update. Download the current package and retain its server-issued TDF IDs when preparing an authorized update; the application assigns new identities to first imports. Production content updates and application deployment are separate actions. Existing learner attempts and frozen adaptive sequences are not reset or remapped.

The CA/EA association difference and authored answer-key questions remain unchanged pending the research owner's explanation. This cleanup does not establish a change to the experimental protocol.
