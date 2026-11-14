# SPARC PhET pilot activities

These three ordinary ZIP lesson packages include pinned public adapted PhET simulations, monitoring catalogs, corresponding source and notices. They are not equivalent to current private PhET releases. The corresponding shared monitor, secure iframe host, telemetry storage, and generator live in `C:/dev/MoFaCTS`.

| Lesson | Task |
| --- | --- |
| Density | Increase wood volume above 5 L while preserving density 400 kg/m³ |
| Pendulum Lab | Set length to at least 0.75 m and observe a subsequent left–right–left oscillation |
| Circuit Construction Kit: DC | Create/remove a component and then form a conducting circuit |

Individual upload ZIPs are stored one level above this directory as `SPARC PhET density.zip`, `SPARC PhET pendulum-lab.zip`, and `SPARC PhET circuit-construction-kit-dc.zip`; `SPARC PhET Pilot.zip` combines all three. Each TDF references its matching stimulus JSON. The pages use static `productionRules`, a packaged `simulation.buildId` and hashed `simulation.asset` HTML/catalog references, declarative bindings, contextual hints, a persistent completed-task flag, and an explicitly selected Done action. Raw observations do not update KCs or constitute scored answers. The constant selection probability only makes the single authored activity available; it is not a learning estimate.

Reload preserves completed tasks and history but requires an explicit new physical simulation attempt. The pendulum task detects angular-side transitions from observed property changes at settled checkpoints; it does not estimate an exact period. The circuit criterion uses nonzero simulated current after observed creation/removal.

Rebuild and regenerate from the application repository when shared monitor sources change:

```powershell
node tools/phet-pilot/generate-catalogs.mjs
node tools/phet-pilot/create-activities.mjs 'C:/dev/mofacts_config/SPARC PhET Pilot'
node tools/phet-pilot/verify-activities.cjs 'C:/dev/mofacts_config/SPARC PhET Pilot'
```

The generator checks that all three artifacts use the current identical collector and bridge. Each stimulus declares the packaged artifact filenames and hashes. Upload resolves these to stored asset URLs; the sandbox gives the simulation an isolated opaque origin. No private settings fragment is used.

The activities use protocol 3 and the shared version-1 registration/interaction contract. Property, emitter and observable-collection notifications update SPARC directly, with no model polling. Research trace storage runs independently. Explicit shared control notifications identify completed adjustments and reset; silent mutable fields remain unsupported.

The stimulus files author selected variable labels and units, meaningful history events, task conditions and hints. Ordinary Download includes semantic Selection–Action–Input–Outcome rows and a lossless `CF (Simulation Activity)` JSON column with build/attempt references and supporting observations. Object catalogs and detailed notifications stay in the separate research trace. Correctness and KC updates require separate explicit authored effects.

The normal uploader verifies the included HTML and catalog hashes, checks required addresses, and resolves filenames to uploaded asset IDs. No per-lesson server settings or simulation server is needed. The application loads HTML in an isolated scripts-only sandbox; the shared bridge derives the embedding origin from the browser rather than a hard-coded hostname. Actual starting values and dynamic object IDs remain attempt-specific metadata. After reload, completed tasks and prior logs remain, and a new physical attempt requires explicit Start. See the application report for verification tied to exact build identities.

Upload user-facing activities under the intended author/admin account so they are visible there. The test uploader in the application repository creates separate verification fixtures. See the application pilot README and the wiki's **PhET Simulation Pilot** page for build identities, coverage limits, reproduction and research export.

Recorded November 11 protocol-3 ten-minute baseline/monitored pairs passed the 10% p95 frame-interval target: Density 9.0/9.1 ms (+1.1%), Pendulum 8.6/8.7 ms (+1.2%), Circuit 8.7/8.8 ms (+1.1%). Ordinary Download browser checks produced 9/12/16 activity rows for the scripted cases, including unsuccessful checks, repeated hints, reset and interrupted/completed attempts; internal inventories were excluded. A full Meteor snapshot passed 1,018 server and 1,249 client cases before the final export/contract refinements; those historical targeted checks passed. See the current application report for exact evidence and limitations.

The ZIP integration requires its matching application revision; uploading these packages does not deploy application code. Earlier November 11/12 performance and Meteor results above are historical evidence for their source snapshots. The November 13 revision retains the shared event-based collector without polling and has new portable-bridge build identities.

The current ZIP upload and normal package-download round trips pass for all three lessons. Live SPARC feedback appears before held research writes complete; completion, explicit restart and retained work pass. The current scripted ordinary exports retain 9/12/16 activity rows across all download scopes. Full source archives make the ZIP files larger than the runtime HTML alone; students load only the HTML/catalog, not the source archives. The November 14 full integration run passed 1,036 server and 1,249 client tests, with zero failures and 15/seven pending. The current application/wiki record retains both this result and the earlier failed run.

The complete ZIP packages and corresponding-source ZIPs are tracked through Git LFS because they exceed ordinary Git hosting file limits. Use `git lfs install` and `git lfs pull` when checking out this repository; confirm ZIP files contain binary archives rather than LFS pointer text before uploading. This transport does not change the ordinary MoFaCTS ZIP upload format.
