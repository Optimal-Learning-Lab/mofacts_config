# MoFaCTS Config Repo Agent Guide

## Purpose
- Repository: `C:\Users\ppavl\OneDrive\Active projects\mofacts_config`
- Holds MoFaCTS configuration and content definitions, including TDF-related structures consumed by application code.

## Repo Selection Rule
- Do not assume the current working directory is the correct repo for the task.
- Choose the repo based on feature ownership first, then use the current directory only if it matches that ownership.
- For runtime behavior, UI rendering, themes, transitions, Svelte components, state machines, or application logic, switch to `C:\dev\mofacts` and prefer `svelte-app/`.
- Stay in this repo when the task is about configuration content, TDF definitions, schemas, payload values, or sync workflows.
- When a task spans repos, start in the primary owning repo and inspect sibling repos for compatibility as needed.

## Sibling Repositories In This Workspace
- `C:\dev\mofacts` (main application code)
- `C:\Users\ppavl\OneDrive\Active projects\mofacts.wiki` (documentation)

## When To Inspect Siblings
- If config fields, names, schemas, payload structures, or required values change, inspect `mofacts` to verify runtime compatibility.
- If TDF field names or required structures change, confirm the application still expects the same definitions.
- If config behavior or setup expectations change, inspect `mofacts.wiki` for required doc updates.

## Cross-Repo Coordination Is Expected
- Do not assume this repo is self-contained.
- Application code and configuration definitions must evolve together.

## Required Sync Procedure
- Before committing or pushing config changes, follow `README-SYNC-SCRIPTS.md`.
- Use the sync scripts (`sync-config.js` or wrappers) for normal config sync so API keys are stripped in committed content and restored locally after push.
- If a manual commit or push is explicitly requested by the user, still verify key-safety requirements from `README-SYNC-SCRIPTS.md` before pushing.
