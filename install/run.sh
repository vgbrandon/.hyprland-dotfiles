#!/usr/bin/env bash
set -Eeuo pipefail

# run.sh vive en install/, así que repo root es ../
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="$REPO_ROOT/install"
TASKS_DIR="$INSTALL_DIR/tasks"

# -----------------------------
# Flags
# -----------------------------
NONINTERACTIVE=0
ONLY_STOW=0
ONLY_PACKAGES=0
MODULES_CSV=""

usage() {
  cat <<'EOF'
Usage: install/run.sh [options]

Options:
  --noninteractive        No prompts. Defaults to backup on conflicts.
  --only-stow             Only run stow task(s) (prefix 20-).
  --only-packages         Only run packages task(s) (prefix 10-).
  --modules "a,b,c"       Stow only these modules from ./stow
  -h, --help              Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --noninteractive) NONINTERACTIVE=1; shift ;;
    --only-stow) ONLY_STOW=1; shift ;;
    --only-packages) ONLY_PACKAGES=1; shift ;;
    --modules) MODULES_CSV="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

if [[ "$ONLY_STOW" -eq 1 && "$ONLY_PACKAGES" -eq 1 ]]; then
  echo "ERR: Choose only one: --only-stow OR --only-packages" >&2
  exit 1
fi

# -----------------------------
# Minimal logging
# -----------------------------
log()  { printf "%b\n" "$*"; }
info() { log "ℹ️  $*"; }
ok()   { log "✅ $*"; }
warn() { log "⚠️  $*"; }
die()  { log "❌ $*"; exit 1; }

# -----------------------------
# Task runner
# -----------------------------
run_task() {
  local task="$1"
  [[ -f "$task" ]] || die "Task missing: $task"
  [[ -x "$task" ]] || die "Task not executable: $task"
  info "Running: ${task#$REPO_ROOT/}"
  NONINTERACTIVE="$NONINTERACTIVE" MODULES_CSV="$MODULES_CSV" REPO_ROOT="$REPO_ROOT" bash "$task"
  ok "Done: ${task#$REPO_ROOT/}"
}

# -----------------------------
# Discover tasks automatically
# -----------------------------
[[ -d "$TASKS_DIR" ]] || die "Missing tasks directory: $TASKS_DIR"

mapfile -t ALL_TASKS < <(
  find "$TASKS_DIR" -maxdepth 1 -type f -name '*.sh' -printf '%p\n' \
  | sort
)

((${#ALL_TASKS[@]} > 0)) || die "No tasks found in: $TASKS_DIR"

# Filter by mode
TASKS=()
if [[ "$ONLY_PACKAGES" -eq 1 ]]; then
  for t in "${ALL_TASKS[@]}"; do
    [[ "$(basename "$t")" == 10-* ]] && TASKS+=("$t")
  done
elif [[ "$ONLY_STOW" -eq 1 ]]; then
  for t in "${ALL_TASKS[@]}"; do
    [[ "$(basename "$t")" == 20-* ]] && TASKS+=("$t")
  done
else
  TASKS=("${ALL_TASKS[@]}")
fi

((${#TASKS[@]} > 0)) || die "No tasks matched the selected mode."

# -----------------------------
# Pre-flight checks
# -----------------------------
needs_stow=0
for t in "${TASKS[@]}"; do
  [[ "$(basename "$t")" == 20-* ]] && needs_stow=1 && break
done

if [[ "$needs_stow" -eq 1 ]]; then
  [[ -d "$REPO_ROOT/stow" ]] || die "Missing stow directory: $REPO_ROOT/stow"
  command -v stow >/dev/null 2>&1 || die "stow is not installed. Install it first: sudo pacman -S stow"
fi

# -----------------------------
# Execute
# -----------------------------
for t in "${TASKS[@]}"; do
  run_task "$t"
done

