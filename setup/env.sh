#!/usr/bin/env bash

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETUP_DIR="$ROOT_DIR/setup"

TASKS_DIR="$SETUP_DIR/tasks"
SERVICES_DIR="$SETUP_DIR/services"
PACKAGES_DIR="$SETUP_DIR/packages"
SHARED_DIR="$SETUP_DIR/shared"

STOW_DIR="$ROOT_DIR/stow"
SCRIPTS_DIR="$ROOT_DIR/scripts"
ASSETS_DIR="$ROOT_DIR/assets"
DOCS_DIR="$ROOT_DIR/docs"
