#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="$ROOT_DIR/.termctl"
RUN_DIR="$STATE_DIR/run"
PID_DIR="$STATE_DIR/pids"
LOG_DIR="$STATE_DIR/logs"
META_FILE="$STATE_DIR/processes.txt"

mkdir -p "$RUN_DIR" "$PID_DIR" "$LOG_DIR"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/termctl.sh start "name1::command1" "name2::command2" "name3::command3" "name4::command4"
  ./scripts/termctl.sh stop
  ./scripts/termctl.sh status
  ./scripts/termctl.sh restart

Notes:
  - `start` requires exactly 4 process specs.
  - Each process opens in its own macOS Terminal window.
  - PIDs are stored in .termctl/pids so they can be stopped later.
  - `restart` uses the last saved 4-process configuration.

Example:
  ./scripts/termctl.sh start \
    "api::npm run api" \
    "worker::npm run worker" \
    "web::npm run web" \
    "jobs::npm run jobs"
EOF
}

require_macos_terminal() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This script currently supports macOS Terminal only." >&2
    exit 1
  fi
}

is_running_pid() {
  local pid="$1"
  kill -0 "$pid" 2>/dev/null
}

escape_for_single_quotes() {
  printf "%s" "$1" | sed "s/'/'\\\\''/g"
}

write_runner_script() {
  local name="$1"
  local command="$2"
  local runner="$RUN_DIR/$name.sh"
  local log_file="$LOG_DIR/$name.log"
  local pid_file="$PID_DIR/$name.pid"

  cat > "$runner" <<EOF
#!/usr/bin/env bash
set -euo pipefail
cd '$ROOT_DIR'
echo \$\$ > '$pid_file'
echo "[$name] starting: $command"
{
  echo "===== \$(date '+%Y-%m-%d %H:%M:%S') [$name] START ====="
  $command
  exit_code=\$?
  echo "===== \$(date '+%Y-%m-%d %H:%M:%S') [$name] EXIT \$exit_code ====="
  exit \$exit_code
} 2>&1 | tee -a '$log_file'
status=\${PIPESTATUS[0]}
rm -f '$pid_file'
echo
echo "[$name] finished with exit code \$status"
echo "Logs: $log_file"
exec bash -i
EOF

  chmod +x "$runner"
  printf "%s" "$runner"
}

open_in_terminal() {
  local runner="$1"
  local runner_escaped
  runner_escaped="$(escape_for_single_quotes "$runner")"

  osascript <<EOF >/dev/null
tell application "Terminal"
  activate
  do script "bash '$runner_escaped'"
end tell
EOF
}

save_specs() {
  printf "%s\n" "$@" > "$META_FILE"
}

load_specs() {
  if [[ ! -f "$META_FILE" ]]; then
    echo "No saved process configuration found." >&2
    exit 1
  fi
  mapfile -t SAVED_SPECS < "$META_FILE"
  if [[ "${#SAVED_SPECS[@]}" -ne 4 ]]; then
    echo "Saved configuration is invalid. Expected 4 process specs." >&2
    exit 1
  fi
}

start_processes() {
  require_macos_terminal

  if [[ "$#" -ne 4 ]]; then
    echo "start requires exactly 4 process specs." >&2
    usage
    exit 1
  fi

  save_specs "$@"

  local spec name command runner
  for spec in "$@"; do
    if [[ "$spec" != *"::"* ]]; then
      echo "Invalid spec: $spec" >&2
      echo "Each spec must look like name::command" >&2
      exit 1
    fi

    name="${spec%%::*}"
    command="${spec#*::}"

    if [[ -z "$name" || -z "$command" ]]; then
      echo "Invalid spec: $spec" >&2
      exit 1
    fi

    runner="$(write_runner_script "$name" "$command")"
    open_in_terminal "$runner"
    echo "Started $name in a new Terminal window."
  done
}

stop_processes() {
  local pid_file pid name found=0

  shopt -s nullglob
  for pid_file in "$PID_DIR"/*.pid; do
    found=1
    name="$(basename "$pid_file" .pid)"
    pid="$(cat "$pid_file")"

    if is_running_pid "$pid"; then
      kill "$pid"
      echo "Stopped $name (PID $pid)."
    else
      echo "$name is not running, removing stale PID file."
    fi

    rm -f "$pid_file"
  done
  shopt -u nullglob

  if [[ "$found" -eq 0 ]]; then
    echo "No tracked processes are currently running."
  fi
}

status_processes() {
  if [[ ! -f "$META_FILE" ]]; then
    echo "No saved process configuration."
    return
  fi

  local spec name pid_file pid status
  while IFS= read -r spec; do
    name="${spec%%::*}"
    pid_file="$PID_DIR/$name.pid"

    if [[ -f "$pid_file" ]]; then
      pid="$(cat "$pid_file")"
      if is_running_pid "$pid"; then
        status="running (PID $pid)"
      else
        status="stale PID file"
      fi
    else
      status="stopped"
    fi

    echo "$name: $status"
  done < "$META_FILE"
}

restart_processes() {
  load_specs
  stop_processes
  sleep 1
  start_processes "${SAVED_SPECS[@]}"
}

main() {
  if [[ "$#" -lt 1 ]]; then
    usage
    exit 1
  fi

  local action="$1"
  shift

  case "$action" in
    start)
      start_processes "$@"
      ;;
    stop)
      stop_processes
      ;;
    status)
      status_processes
      ;;
    restart)
      restart_processes
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
