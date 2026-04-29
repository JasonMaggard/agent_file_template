#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s <branch-name>\n' "${0##*/}" >&2
  printf 'Example: %s codex/billing-cleanup\n' "${0##*/}" >&2
}

if [[ $# -ne 1 ]]; then
  usage
  exit 2
fi

branch_name=$1

if ! git rev-parse --verify --quiet HEAD >/dev/null; then
  printf 'Cannot create a worktree yet: this repository has no commits.\n' >&2
  printf 'Create an initial commit, then rerun: %s %s\n' "${0##*/}" "$branch_name" >&2
  exit 1
fi

repo_root=$(git rev-parse --show-toplevel)
repo_name=$(basename "$repo_root")
worktree_parent="$(dirname "$repo_root")/${repo_name}.worktrees"
safe_branch_name=$(printf '%s' "$branch_name" | sed -E 's#[/[:space:]:]+#__#g')
worktree_path="${worktree_parent}/${safe_branch_name}"

mkdir -p "$worktree_parent"

if [[ -d "$worktree_path/.git" || -f "$worktree_path/.git" ]]; then
  printf 'Worktree already exists: %s\n' "$worktree_path"
else
  if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
    git worktree add "$worktree_path" "$branch_name"
  else
    git worktree add -b "$branch_name" "$worktree_path"
  fi
fi

mkdir -p "$worktree_path/.agents.local"

if [[ ! -f "$worktree_path/.agents.local/AGENTS.local.md" ]]; then
  printf '%s' '# Local Agent Preferences

These preferences are local to this worktree and must not be committed.

## Default Collaboration Contract

- Read this file before planning or implementing.
- Maintain `.agents.local/plan.md`, `.agents.local/progress.md`, and
  `.agents.local/implementation.md` as part of normal work.
- Update the plan when the objective, phases, blockers, or validation approach
  changes.
- Update progress after meaningful discoveries, completed steps, corrected
  mistakes, or changed decisions.
- Update implementation notes after adding or changing run, test, verification,
  environment, or handoff instructions.
- Ask before creating branches, creating worktrees, committing, opening PRs, or
  running destructive commands.

' \
    > "$worktree_path/.agents.local/AGENTS.local.md"
fi

if [[ ! -f "$worktree_path/.agents.local/plan.md" ]]; then
  printf '%s' '# Plan

## Current Task

- Status: Not started
- Objective: Describe the active task here.

## Phases

- Pending: Define reviewable phases before implementation.

## Blockers

- None recorded.

## Validation

- Pending: Define how this work will be checked.

' > "$worktree_path/.agents.local/plan.md"
fi

if [[ ! -f "$worktree_path/.agents.local/progress.md" ]]; then
  printf '%s' '# Progress

Record meaningful discoveries, decisions, completed work, corrected mistakes,
and remaining gaps here.

' > "$worktree_path/.agents.local/progress.md"
fi

if [[ ! -f "$worktree_path/.agents.local/implementation.md" ]]; then
  printf '%s' '# Implementation

Record how to run, test, verify, and hand off the current work here.

' > "$worktree_path/.agents.local/implementation.md"
fi

printf 'Ready: %s\n' "$worktree_path"
printf 'Next: cd %s\n' "$worktree_path"
