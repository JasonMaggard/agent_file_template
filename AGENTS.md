# Agent Instructions

These instructions are shared, repo-level guidance for AI agents working in this
repository. They should stay focused on project workflow, engineering standards,
and safety rules that apply to the whole team.

## Startup Checklist

Before planning or implementing, an agent should:

1. Read this `AGENTS.md`.
2. If present, read the local-only agent context files:
   - `.agents.local/AGENTS.local.md`
   - `.agents.local/plan.md`
   - `.agents.local/progress.md`
   - `.agents.local/implementation.md`
3. Treat local files as user/session context. They must not be committed.
4. If local preferences conflict with repo instructions or an explicit user
   message, follow the explicit user message first, then this file, then local
   preferences.

Missing local context files are not an error.

## Engineering Principles

- Work in small, committable, testable phases.
- Each phase should end in a working, testable state.
- Prefer preserving existing behavior before improving architecture.
- Prefer local and existing patterns found in the code.
- Optimize code style for human readability and audit.
- Do not guess when something can be verified from code, docs, or tests.
- If an assumption is necessary, state it clearly.
- Validate API capabilities against documentation or observed behavior before
  designing around them.
- Make dependencies and prerequisites explicit up front.
- Ask before changing public interfaces, schemas, database structure, or
  behavior with broad downstream impact.
- Do not refactor, rename, or reorganize code outside the current task.
- If a task is blocked, say so explicitly.

## Testing Expectations

- Use tests to lock behavior before introducing abstractions.
- Prefer tests around externally visible behavior over implementation details.
- Keep tests reviewable and easy to reason about.
- When parity matters between two systems, define exactly what parity means and
  test for it explicitly.
- If two systems are being migrated between, create tests that let the same
  behavior be verified against both.

## Review Hygiene

- Do not silently fix unrelated code while working on a task.
- When changing direction, replacing an approach, or moving code from one layer
  to another, clean up code and tests made stale by that decision.
- Remove dead helpers, superseded tests, unused wiring, and stale docs introduced
  during the current task as soon as they are no longer part of the chosen
  design.
- Limit cleanup to code introduced or directly changed in the current task unless
  broader refactoring is explicitly requested.
- Preserve existing comments and docs unless they are clearly wrong or need to
  change with the implementation.

## Documentation Expectations

- If a task discovers a one-off shell command, curl command, SQL query, or manual
  step that was materially necessary to unblock work or verify behavior,
  document the exact command in the relevant operator-facing docs.
- Include the exact command, required working directory, env-loading steps,
  placeholders, and prerequisites.
- When a task materially changes library architecture, public integrations,
  migration behavior, or verification workflows, update the relevant README or
  operator-facing documentation.
- Verification and harness output should state whether the operation succeeded,
  what was verified, what conclusion the operator should draw, and any upstream
  caveats that affect interpretation.
- Keep machine-readable output such as `--json` available where appropriate, but
  do not make it the only practical way to understand what happened.

## Local Agent Context

Local agent state belongs under `.agents.local/`.

Recommended files:

- `.agents.local/AGENTS.local.md`: personal working preferences and collaboration
  style.
- `.agents.local/plan.md`: current task plan.
- `.agents.local/progress.md`: running progress log, learnings, corrected
  mistakes, and remaining gaps.
- `.agents.local/implementation.md`: run, test, and verification instructions for
  completed phases.

The `.agents.local/` directory is ignored by git and must remain local-only.

## Worktree Workflow

When starting work for a new branch, ask before creating a branch or worktree.

Use the helper script to create a consistently named worktree and initialize
local agent docs:

```bash
./scripts/agent-worktree.sh codex/example-branch
```

The repository must have at least one commit before a useful worktree can be
created.

The script stores worktrees next to this repository:

```text
../<repo-name>.worktrees/<sanitized-branch-name>
```

For example, branch `codex/example-branch` becomes:

```text
../Playground.worktrees/codex__example-branch
```

After creating or opening the worktree, continue the session from that worktree
and use its `.agents.local/` files for branch-specific plan and memory.
