#!/usr/bin/env bash
# Build helper for the Linux port of GoodbyeDPI-Turkey.
#
# This script fetches the upstream byedpi (https://github.com/hufrea/byedpi)
# source into linux/third_party/byedpi when it is not already there, compiles
# it and copies the resulting `ciadpi` binary into linux/bin/.
#
# Why byedpi: WinDivert (used by GoodbyeDPI on Windows) is a Windows-only
# kernel driver and Linux has no equivalent of it in this project, so the
# Linux port drives byedpi instead — a userspace DPI evasion tool that
# implements the same tricks (TLS ClientHello splitting, TCP disorder, OOB
# byte, TLS record splitting, HTTP header mixing) behind a SOCKS5 proxy.

set -euo pipefail

BYEDPI_REPO="${BYEDPI_REPO:-https://github.com/hufrea/byedpi.git}"
BYEDPI_REF="${BYEDPI_REF:-main}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THIRD_PARTY_DIR="${SCRIPT_DIR}/third_party"
BYEDPI_DIR="${THIRD_PARTY_DIR}/byedpi"
BIN_DIR="${SCRIPT_DIR}/bin"

log() { printf '\033[1;34m[build]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[build]\033[0m %s\n' "$*" >&2; }

if [[ "$(uname -s)" != "Linux" ]]; then
    err "This build helper targets Linux only."
    err "On macOS use macos/build.sh; on Windows build src/ with MinGW."
    exit 1
fi

for tool in git make cc; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        err "Required tool '$tool' is missing."
        err "Install it with your package manager, e.g. 'apt install git make gcc'."
        exit 1
    fi
done

mkdir -p "$THIRD_PARTY_DIR" "$BIN_DIR"

if [[ ! -d "$BYEDPI_DIR/.git" ]]; then
    log "Fetching byedpi from ${BYEDPI_REPO} (ref: ${BYEDPI_REF})"
    git clone --depth 1 --branch "$BYEDPI_REF" "$BYEDPI_REPO" "$BYEDPI_DIR"
else
    log "byedpi already cloned at ${BYEDPI_DIR} — skipping clone"
    log "(use 'git -C ${BYEDPI_DIR} pull' to update, or delete the dir to re-clone)"
fi

JOBS="$(nproc 2>/dev/null || echo 1)"

log "Building ciadpi for $(uname -m) with ${JOBS} job(s)"
make -C "$BYEDPI_DIR" -j"$JOBS"

if [[ ! -x "$BYEDPI_DIR/ciadpi" ]]; then
    err "Build appears to have failed: $BYEDPI_DIR/ciadpi is missing or not executable."
    exit 1
fi

cp -f "$BYEDPI_DIR/ciadpi" "$BIN_DIR/ciadpi"
chmod +x "$BIN_DIR/ciadpi"

log "Built binary: ${BIN_DIR}/ciadpi"
log "Done. Run 'make help' in ${SCRIPT_DIR} to list the available targets."
