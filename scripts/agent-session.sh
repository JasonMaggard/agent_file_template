#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  agent-session.sh init
  agent-session.sh status
  agent-session.sh start <branch-name>
  agent-session.sh snapshot [message]

Commands:
  init      Ensure .agents.local files exist in the current worktree.
  status    Print branch, worktree, and local agent document status.
  start     Create or reuse a branch worktree via scripts/agent-worktree.sh.
  snapshot  Append a short timestamped checkpoint to progress.md.
EOF
}

repo_root() {
  git rev-parse --show-toplevel
}

agent_dir() {
  printf '%s/.agents.local' "$(repo_root)"
}

write_if_missing() {
  local path=$1
  local content=$2

  if [[ ! -f "$path" ]]; then
    printf '%s' "$content" > "$path"
  fi
}

init_docs() {
  local dir
  dir=$(agent_dir)
  mkdir -p "$dir"

  write_if_missing "$dir/AGENTS.local.md" '# Local Agent Preferences

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

'

  write_if_missing "$dir/plan.md" '# Plan

## Current Task

- Status: Not started
- Objective: Describe the active task here.

## Phases

- Pending: Define reviewable phases before implementation.

## Blockers

- None recorded.

## Validation

- Pending: Define how this work will be checked.

'

  write_if_missing "$dir/progress.md" '# Progress

Record meaningful discoveries, decisions, completed work, corrected mistakes,
and remaining gaps here.

'

  write_if_missing "$dir/implementation.md" '# Implementation

Record how to run, test, verify, and hand off the current work here.

'

  printf 'Ensured local agent docs in %s\n' "$dir"
}

status_docs() {
  local root dir branch worktree_state
  root=$(repo_root)
  dir="$root/.agents.local"
  branch=$(git branch --show-current)
  worktree_state=$(git rev-parse --is-inside-work-tree)

  printf 'Repository: %s\n' "$root"
  printf 'Branch: %s\n' "${branch:-detached HEAD}"
  printf 'Inside worktree: %s\n' "$worktree_state"
  printf 'Local agent docs: %s\n' "$dir"

  for file in AGENTS.local.md plan.md progress.md implementation.md; do
    if [[ -f "$dir/$file" ]]; then
      printf '  present: %s\n' "$file"
    else
      printf '  missing: %s\n' "$file"
    fi
  done
}

start_branch() {
  if [[ $# -ne 1 ]]; then
    usage
    exit 2
  fi

  local root
  root=$(repo_root)
  "$root/scripts/agent-worktree.sh" "$1"
}

snapshot_progress() {
  init_docs >/dev/null

  local message=${1:-Manual checkpoint}
  local progress
  progress="$(agent_dir)/progress.md"

  {
    printf '\n## %s\n\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
    printf '%s\n' "- $message"
    printf '%s\n' "- Branch: $(git branch --show-current || true)"
    printf '%s\n' "- Status:"
    git status --short | sed 's/^/  - /'
  } >> "$progress"

  printf 'Appended checkpoint to %s\n' "$progress"
}

if [[ $# -lt 1 ]]; then
  usage
  exit 2
fi

command=$1
shift

case "$command" in
  init)
    init_docs
    ;;
  status)
    status_docs
    ;;
  start)
    start_branch "$@"
    ;;
  snapshot)
    snapshot_progress "${*:-Manual checkpoint}"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage
    exit 2
    ;;
esac
