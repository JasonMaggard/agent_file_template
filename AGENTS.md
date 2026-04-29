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

When writing any plan, implementation, or progress docs, use a branch-specific local worktree.
Do not create additional worktrees when one already exists for the branch.
If the current branch already has an appropriate local worktree, continue there.
If it does not, create one with the helper script.

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
../portal.worktrees/codex__example-branch
```

After creating or opening the worktree, continue the session from that worktree
and use its `.agents.local/` files for branch-specific plan and memory.

<!-- nx configuration start-->
<!-- Leave the start & end comments to automatically receive updates. -->

## General Guidelines for working with Nx

- For navigating/exploring the workspace, invoke the `nx-workspace` skill first - it has patterns for querying projects, targets, and dependencies
- When running tasks (for example build, lint, test, e2e, etc.), always prefer running the task through `nx` (i.e. `nx run`, `nx run-many`, `nx affected`) instead of using the underlying tooling directly
- Prefix nx commands with the workspace's package manager (e.g., `pnpm nx build`, `npm exec nx test`) - avoids using globally installed CLI
- You have access to the Nx MCP server and its tools, use them to help the user
- For Nx plugin best practices, check `node_modules/@nx/<plugin>/PLUGIN.md`. Not all plugins have this file - proceed without it if unavailable.
- NEVER guess CLI flags - always check nx_docs or `--help` first when unsure

## Scaffolding & Generators

- For scaffolding tasks (creating apps, libs, project structure, setup), ALWAYS invoke the `nx-generate` skill FIRST before exploring or calling MCP tools

## When to use nx_docs

- USE for: advanced config options, unfamiliar flags, migration guides, plugin configuration, edge cases
- DON'T USE for: basic generator syntax (`nx g @nx/react:app`), standard commands, things you already know
- The `nx-generate` skill handles generator discovery internally - don't call nx_docs just to look up generator syntax

<!-- nx configuration end-->
