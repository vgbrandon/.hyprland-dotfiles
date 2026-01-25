#!/usr/bin/env bash
set -Eeuo pipefail

# Usage: read_list "/path/to/list.txt"
# prints packages one per line
read_list() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  sed 's/#.*$//' "$file" | sed '/^[[:space:]]*$/d' | awk '{$1=$1}1'
}

