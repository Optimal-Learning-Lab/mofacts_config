# AutoTutor Runtime Production Rules

- Policy: `progressive-scaffolding-v1`
- Ownership: runtime code in `learning-components/units/sparcsession/sparcProgressiveScaffoldingRules.ts`
- AutoTutor stimulus files configure expectations, misconceptions, thresholds, and graph facts. They do not copy the runtime production rules.
- Any misconception at or above `dialogue.thresholds.misconceptionThreshold` has priority over expectations. The strongest eligible misconception begins with a targeted prompt.
- Expectations begin with a pump. Meaningful gain at pump stays at pump; insufficient gain advances to prompt.
