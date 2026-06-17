# SPARC Intro Stats Variables

This package is generated from the first module (`Variables`, container `97146`) in
`export_intro_to_stats_flat_copy_l71p6.zip`.

Regenerate it with:

```powershell
node --experimental-strip-types C:\dev\mofacts_config\scripts\convert_oli_flat_module_to_sparc.ts
```

Generated files:

- `SPARC Intro Stats Variables_TDF.json`
- `SPARC_Intro_Stats_Variables_stims.json`
- `conversion-notes.json`

The converter maps OLI activity types to SPARC nodes as follows:

- Multiple choice: `content.choices` with no `content.inputs`; the positive-score response identifies the correct choice.
- Targeted CATA: `content.type === "TargetedCATA"`; `content.authoring.correct[0]` identifies the selected checkbox IDs.
- Dropdown multi-input: `content.inputs[]`; each input's `partId` maps to an authoring part and positive-score response.
