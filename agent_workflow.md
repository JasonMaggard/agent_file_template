# Agent Workflow Pattern

## Purpose

This document defines a practical pattern for using AI coding agents across team
repositories without mixing three different concerns:

1. Shared repository instructions.
2. Personal collaboration preferences.
3. Branch-specific planning and memory.

The goal is to make agent behavior consistent enough for a team, while still
leaving room for individual working style and task-specific context.

## Recommended Decision

Use a committed `AGENTS.md` for team-wide repository instructions.

Use a local, ignored `.agents.local/` directory for personal preferences and
branch-specific planning docs.

Use git worktrees when branch-specific plans and memory should stay attached to a
branch without being committed to the codebase.

Use helper scripts to make this workflow routine. The user should not have to
manually create, remember, or update every planning and handoff document.

## File Responsibilities

### `AGENTS.md`

`AGENTS.md` is committed to the repo and should contain shared guidance that
applies to every agent and every contributor working in the project.

Good content for `AGENTS.md` includes:

- Build, test, and verification commands.
- Repo architecture notes.
- Team coding standards.
- Documentation expectations.
- Safety rules for migrations, public interfaces, schemas, and destructive
  commands.
- Instructions to read local-only context if present.

Avoid putting personal tone, communication style, or individual workflow quirks
directly in the committed `AGENTS.md`.

### `.agents.local/AGENTS.local.md`

This file is local-only and should contain personal preferences for working with
AI agents.

Good content includes:

- Preferred planning style.
- Communication style.
- How much confirmation the user wants before coding.
- Whether the user prefers plan-first workflows.
- Personal conventions for phase completion and progress summaries.

This file should not be committed.

### `.agents.local/plan.md`

This is the current task plan for the worktree.

It should include:

- Current objective.
- Reviewable phases.
- Dependencies and prerequisites.
- Known blockers.
- Validation steps.

### `.agents.local/progress.md`

This is a running progress log.

It should include:

- What changed.
- What was learned.
- Mistakes corrected.
- Remaining gaps.
- Decisions made during the session.

### `.agents.local/implementation.md`

This is the operational handoff document for the current branch or task.

It should include:

- How to run the work.
- How to test the work.
- How to verify the work.
- Required working directory.
- Required environment setup.
- Exact commands used for important manual verification.

## Why Local Docs Should Be Ignored

Planning and memory docs are useful to the person driving the work, but they are
usually not durable project documentation. Committing them can create noise,
merge conflicts, and accidental exposure of personal workflow notes.

Keeping them under `.agents.local/` gives agents a predictable place to look
without treating personal context as project source.

The repo should ignore this directory:

```gitignore
.agents.local/
```

## Automation Contract

Agents should treat the local documents as part of the work loop, not as
optional paperwork. On session start, an agent should initialize missing local
docs, read them, and then keep them current.

Minimum automatic behavior:

- Run `./scripts/agent-session.sh init` when `.agents.local/` is missing or
  incomplete.
- Read `.agents.local/AGENTS.local.md` before planning or implementing.
- Update `.agents.local/plan.md` when the objective, phases, blockers, or
  validation approach changes.
- Update `.agents.local/progress.md` after meaningful discoveries, completed
  steps, corrected mistakes, or changed decisions.
- Update `.agents.local/implementation.md` after adding or changing run, test,
  verification, environment, or handoff instructions.
- Use `./scripts/agent-session.sh status` when the agent needs to understand the
  current branch/worktree/local-doc state.
- Use `./scripts/agent-session.sh snapshot "message"` for quick progress
  checkpoints.

These updates should happen without the user needing to say "update the plan" or
"record our progress" every time.

## Worktree-Based Branch Memory

A single checkout can only have one local `.agents.local/` state at a time. That
becomes awkward when switching between branches.

Git worktrees solve this by giving each branch its own working directory. Each
worktree can then have its own ignored `.agents.local/` directory.

Recommended structure:

```text
parent-directory/
  repo/
  repo.worktrees/
    codex__billing-cleanup/
      .agents.local/
        AGENTS.local.md
        plan.md
        progress.md
        implementation.md
    codex__stripe-migration/
      .agents.local/
        AGENTS.local.md
        plan.md
        progress.md
        implementation.md
```

Branch names are converted to folder names by replacing `/` with `__`.

Example:

```text
codex/billing-cleanup -> codex__billing-cleanup
```

## Example Flow

1. A contributor opens the repository.
2. The agent reads `AGENTS.md`.
3. `AGENTS.md` tells the agent to check `.agents.local/` if it exists.
4. The agent reads personal preferences and branch docs from `.agents.local/`.
5. The contributor asks to start a new branch.
6. The agent asks for permission before creating the branch or worktree.
7. The agent creates a branch-specific worktree.
8. The agent initializes `.agents.local/` in that worktree.
9. Future planning and progress updates happen inside that worktree's local docs.
10. The local docs remain uncommitted.

## Helper Script

This repo includes session and worktree helper scripts:

```bash
./scripts/agent-session.sh init
./scripts/agent-session.sh status
./scripts/agent-session.sh snapshot "finished first pass"
./scripts/agent-session.sh start codex/billing-cleanup
```

`agent-session.sh start` delegates to the lower-level worktree helper:

```bash
./scripts/agent-worktree.sh <branch-name>
```

Example:

```bash
./scripts/agent-worktree.sh codex/billing-cleanup
```

The script:

- Creates or reuses a worktree path based on the branch name.
- Creates the branch if it does not already exist.
- Initializes `.agents.local/AGENTS.local.md`.
- Initializes `.agents.local/plan.md`.
- Initializes `.agents.local/progress.md`.
- Initializes `.agents.local/implementation.md`.

The generated local docs are ignored by git.

The repository must have at least one commit before the script can create a
useful worktree. If a repo is still brand new, make the initial commit first,
then create branch worktrees.

## Sample Personal Local Instructions

A contributor might keep the following in `.agents.local/AGENTS.local.md`:

```md
# Local Agent Preferences

## Plan First

- Start new sessions by planning.
- Do not edit files until I approve implementation.
- Do not commit without asking permission first.
- Do not create branches, open PRs, or run destructive git commands without
  asking permission first.

## Planning Docs

- Maintain `.agents.local/plan.md` as the authoritative plan.
- Prefer updating the existing plan instead of rewriting it.
- Break work into independently reviewable phases.
- Mark unverified capabilities as blocked, deferred, or needing validation.

## Progress Docs

When I say "update our progress," update:

- `.agents.local/plan.md`
- `.agents.local/progress.md`
- `.agents.local/implementation.md`
```

## Team Guidance

Keep committed agent instructions boring, practical, and shared.

Keep personal preferences local.

Keep branch memory in the worktree.

This preserves the usefulness of AI planning docs without turning the repository
into a scrapbook of every local working session.
