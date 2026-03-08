# MoFaCTS Config Repo Agent Guide

## Purpose
- Repository: `C:\Users\ppavl\OneDrive\Active projects\mofacts_config`
- Holds MoFaCTS configuration/content definitions (including TDF-related structures) consumed by application code.

## Sibling Repositories In This Workspace
- `C:\Users\ppavl\OneDrive\Active projects\mofacts` (main application code)
- `C:\Users\ppavl\OneDrive\Active projects\mofacts.wiki` (documentation)
- `C:\Users\ppavl\OneDrive\Active projects\optimallearning.org` (public-facing website)

## When To Inspect Siblings
- If config fields, names, schemas, payload structures, or required values change, inspect `mofacts` to verify runtime compatibility.
- If TDF field names or required structures change, confirm the application still expects the same definitions.
- If config behavior or setup expectations change, inspect `mofacts.wiki` for required doc updates.
- If changes affect user-facing messaging/workflows, inspect `optimallearning.org` for alignment.

## Cross-Repo Coordination Is Expected
- Do not assume this repo is self-contained.
- Application code and configuration definitions must evolve together.

## Required Sync Procedure
- Before committing/pushing config changes, follow `README-SYNC-SCRIPTS.md`.
- Use the sync scripts (`sync-config.js` or wrappers) for normal config sync so API keys are stripped in committed content and restored locally after push.
- If a manual commit/push is explicitly requested by the user, still verify key-safety requirements from `README-SYNC-SCRIPTS.md` before pushing.
