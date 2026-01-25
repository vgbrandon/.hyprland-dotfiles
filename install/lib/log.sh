#!/usr/bin/env bash
set -Eeuo pipefail

log()  { printf "%s\n" "$*"; }
info() { log "INFO: $*"; }
ok()   { log "OK:   $*"; }
warn() { log "WARN: $*"; }
die()  { log "ERR:  $*"; exit 1; }

