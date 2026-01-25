#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="$REPO_ROOT/install"

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
  --only-stow             Only run stow task.
  --only-packages         Only run packages task. (placeholder)
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

# -----------------------------
# Load libs (minimal)
# -----------------------------
# You can expand this later (log.sh, detect.sh, etc.)
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
  [[ -x "$task" ]] || die "Task not executable: $task"
  info "Running: ${task#$REPO_ROOT/}"
  NONINTERACTIVE="$NONINTERACTIVE" MODULES_CSV="$MODULES_CSV" REPO_ROOT="$REPO_ROOT" bash "$task"
  ok "Done: ${task#$REPO_ROOT/}"
}

# -----------------------------
# Decide which tasks to run
# -----------------------------
TASKS=()

if [[ "$ONLY_STOW" -eq 1 && "$ONLY_PACKAGES" -eq 1 ]]; then
  die "Choose only one: --only-stow OR --only-packages"
fi

if [[ "$ONLY_STOW" -eq 1 ]]; then
  TASKS+=("$INSTALL_DIR/tasks/30-stow.sh")
elif [[ "$ONLY_PACKAGES" -eq 1 ]]; then
  TASKS+=("$INSTALL_DIR/tasks/10-packages.sh") # placeholder if you create it
else
  # full run (for now only stow, you can add others later)
  [[ -f "$INSTALL_DIR/tasks/10-packages.sh" ]] && TASKS+=("$INSTALL_DIR/tasks/10-packages.sh")
  [[ -f "$INSTALL_DIR/tasks/20-services.sh" ]] && TASKS+=("$INSTALL_DIR/tasks/20-services.sh")
  TASKS+=("$INSTALL_DIR/tasks/30-stow.sh")
  [[ -f "$INSTALL_DIR/tasks/40-post.sh" ]] && TASKS+=("$INSTALL_DIR/tasks/40-post.sh")
fi

# -----------------------------
# Execute
# -----------------------------
[[ -d "$REPO_ROOT/stow" ]] || die "Missing stow directory: $REPO_ROOT/stow"
command -v stow >/dev/null 2>&1 || die "stow is not installed. Install it first: sudo pacman -S stow"

for t in "${TASKS[@]}"; do
  run_task "$t"
done

