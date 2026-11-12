# SPARC PhET pilot activities

These three local feasibility activities use pinned public adapted PhET builds. They are not deployed and are not equivalent to current private releases. The corresponding shared monitor, secure iframe host, telemetry storage, and generator live in `C:/dev/MoFaCTS`.

| Lesson | Task |
| --- | --- |
| Density | Increase wood volume above 5 L while preserving density 400 kg/m³ |
| Pendulum Lab | Set length to at least 0.75 m and observe a subsequent left–right–left oscillation |
| Circuit Construction Kit: DC | Create/remove a component and then form a conducting circuit |

The ZIP is stored one level above this directory as `SPARC PhET Pilot.zip`. Each TDF references its matching stimulus JSON. The pages use static `productionRules`, an approved `simulation.buildId`, declarative bindings, contextual hints, a persistent completed-task flag, and an explicitly selected Done action. Raw observations do not update KCs or constitute scored answers. The constant selection probability only makes the single authored activity available; it is not a learning estimate.

Reload preserves completed tasks and history but requires an explicit new physical simulation attempt. The pendulum task detects angular-side transitions from observed property changes at settled checkpoints; it does not estimate an exact period. The circuit criterion uses nonzero simulated current after observed creation/removal.

Rebuild and regenerate from the application repository when shared monitor sources change:

```powershell
node tools/phet-pilot/generate-catalogs.mjs
node tools/phet-pilot/create-activities.mjs 'C:/dev/mofacts_config/SPARC PhET Pilot'
node tools/phet-pilot/verify-activities.cjs 'C:/dev/mofacts_config/SPARC PhET Pilot'
```

The generator checks that all three artifacts use the current identical collector and bridge. The build server's ignored settings fragment supplies the approved IDs, URLs, and artifact hashes. Use the documented local watcher and separate simulation origin; do not copy private settings into this content directory.

The activities use protocol 3 and the shared version-1 registration/interaction contract. Property, emitter and observable-collection notifications update SPARC directly, with no model polling. Research trace storage runs independently. Explicit shared control notifications identify completed adjustments and reset; silent mutable fields remain unsupported.

The stimulus files author selected variable labels and units, meaningful history events, task conditions and hints. Ordinary Download includes semantic Selection–Action–Input–Outcome rows and a lossless `CF (Simulation Activity)` JSON column with build/attempt references and supporting observations. Object catalogs and detailed notifications stay in the separate research trace. Correctness and KC updates require separate explicit authored effects.

The approved build settings also reference a hash-verified descriptive catalog asset. Actual starting values and dynamic object IDs remain attempt-specific metadata. After reload, completed tasks and prior logs remain, and a new physical attempt requires explicit Start. These are local feasibility activities; see the application report for current verification and performance evidence.

Upload user-facing activities under the intended author/admin account so they are visible there. The test uploader in the application repository creates separate verification fixtures. See the application pilot README and the wiki's **PhET Simulation Pilot** page for build identities, coverage limits, reproduction and research export.

Final protocol-3 ten-minute baseline/monitored pairs passed the 10% p95 frame-interval target: Density 9.0/9.1 ms (+1.1%), Pendulum 8.6/8.7 ms (+1.2%), Circuit 8.7/8.8 ms (+1.1%). Ordinary Download browser checks produced 9/12/16 activity rows for the scripted cases, including unsuccessful checks, repeated hints, reset and interrupted/completed attempts; internal inventories were excluded. A full Meteor snapshot passed 1,018 server and 1,249 client cases before the final export/contract refinements; final targeted checks pass and a full-suite rerun awaits fresh authorization. See the current application report for exact evidence and limitations.
