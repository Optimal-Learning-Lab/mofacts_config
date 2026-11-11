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
node tools/phet-pilot/create-activities.mjs 'C:/dev/mofacts_config/SPARC PhET Pilot'
node tools/phet-pilot/verify-activities.cjs 'C:/dev/mofacts_config/SPARC PhET Pilot'
```

The generator checks that all three artifacts use the current identical collector and bridge. The build server's ignored settings fragment supplies the approved IDs, URLs, and artifact hashes. Use the documented local watcher and separate simulation origin; do not copy private settings into this content directory.

The current activities use protocol-2 reactive builds and the same explicit version-1 registration contract. Property/emitter notifications and Axon observable collections update SPARC without model polling; research storage runs asynchronously. Silent mutable fields are inventoried as unsupported. All three final builds produced authored instructional feedback while the first research write was held, then persisted the supporting observations after release. Reload preserved completed work and required an explicit fresh simulation attempt. Controlled ten-minute performance qualification remains outstanding.

Upload user-facing activities under the intended author/admin account so they are visible there. The test uploader in the application repository creates separate verification fixtures. See the application pilot README and the wiki's **PhET Simulation Pilot** page for build identities, coverage limits, reproduction and research export.
