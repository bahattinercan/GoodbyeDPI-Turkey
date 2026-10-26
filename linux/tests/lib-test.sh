#!/usr/bin/env bash
# linux/tests/lib-test.sh — stub-based unit tests for linux/scripts/_lib.sh.
#
# The library is sourced, never executed. Every command that would mutate the
# real system (ciadpi, resolvectl, gsettings, systemctl, iptables, nft, ip,
# ipset, cp) is shadowed by a stub in a throw-away directory that only records
# its argv. `tee` is stubbed too because the library pipes state files through
# it. `mkdir` and `chmod` stay real, but they only ever see paths inside the
# sandbox. No root, no network, no systemd, no real DNS/proxy/firewall change.
#
# `set -e` is deliberately absent: several assertions expect a command to fail.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_FILE="$SCRIPT_DIR/../scripts/_lib.sh"

if [ ! -r "$LIB_FILE" ]; then
    printf 'err: kutuphane bulunamadi: %s\n' "$LIB_FILE" >&2
    exit 2
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/lib-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP"
}
trap cleanup EXIT

RESULTS="$TMP/results.log"
: > "$RESULTS"
export CALLS_LOG="$TMP/calls.log"
: > "$CALLS_LOG"

# --------------------------------------------------------------------------
# Assertion helpers — all of them use shell builtins only, so they also work
# in the sub-shell where PATH points at a single stub directory.
# --------------------------------------------------------------------------

pass() {
    printf 'ok: %s\n' "$1"
    printf 'ok %s\n' "$1" >>"$RESULTS"
}

fail() {
    printf 'fail: %s\n' "$1"
    printf 'fail %s\n' "$1" >>"$RESULTS"
}

check_eq() { # <name> <expected> <actual>
    if [ "$2" = "$3" ]; then
        pass "$1"
    else
        fail "$1 (beklenen: [$2], gelen: [$3])"
    fi
}

check_has() { # <name> <haystack> <needle>
    case "$2" in
        *"$3"*) pass "$1" ;;
        *) fail "$1 (eksik: [$3])" ;;
    esac
}

check_has_not() { # <name> <haystack> <needle>
    case "$2" in
        *"$3"*) fail "$1 (olmamaliydi: [$3])" ;;
        *) pass "$1" ;;
    esac
}

calls() { # recorded stub argv, builtins only
    local line out=''
    if [ ! -f "$CALLS_LOG" ]; then
        return 0
    fi
    while IFS= read -r line; do
        out="$out$line"$'\n'
    done <"$CALLS_LOG"
    printf '%s' "$out"
}

calls_reset() { : >"$CALLS_LOG"; }

# --------------------------------------------------------------------------
# Stubs
# --------------------------------------------------------------------------

STUB_BIN="$TMP/bin"
STUB_BIN_NFT="$TMP/bin-nft"
mkdir -p "$STUB_BIN" "$STUB_BIN_NFT"

write_stub() { # <dir> <name>
    local dir="$1" name="$2"
    cat >"$dir/$name" <<'STUB'
#!/bin/bash
# Test stub: record argv, never touch the real system.
name=${0##*/}
printf '%s %s\n' "$name" "$*" >>"${CALLS_LOG:-/dev/null}"
case "$name" in
    tee)
        # `_write_file` calls `run tee <path>`: the first argv element is the
        # path (not $2), so behave like `tee <path> >/dev/null`.
        if [ -n "${1:-}" ]; then
            cat >"$1"
        fi
        ;;
    iptables)
        # `-C` probes whether a rule exists; report "missing" so the library
        # takes the add path. `-L` probes whether the chain exists -> 0.
        case " $* " in
            *' -C '*) exit 1 ;;
        esac
        ;;
    resolvectl)
        if [ "${1:-}" = status ] && [ -n "${STUB_RESOLVECTL_STATUS:-}" ]; then
            printf '%s\n' "$STUB_RESOLVECTL_STATUS"
        fi
        ;;
    gsettings)
        if [ "${1:-}" = list-schemas ] && [ -n "${STUB_GSETTINGS_SCHEMA:-}" ]; then
            printf '%s\n' 'org.gnome.system.proxy'
        fi
        ;;
esac
exit 0
STUB
    chmod +x "$dir/$name"
}

for stub in ciadpi resolvectl gsettings systemctl iptables nft ip ipset tee cp; do
    write_stub "$STUB_BIN" "$stub"
done
# A PATH with nft only, so transparent mode falls back to the nft branch.
write_stub "$STUB_BIN_NFT" nft

export PATH="$STUB_BIN:$PATH"
export HOME="$TMP/home"
mkdir -p "$HOME"

# --------------------------------------------------------------------------
# a/b/c — method table, GOODBYEDPI_ARGS override, unknown method
# --------------------------------------------------------------------------

METHOD_LIST="default alt alt2 alt3 alt4 alt5 alt6"

expected_args() {
    case "$1" in
        default) printf '%s' '--fake -1 --md5sig --ttl 8 --split 1+s --disorder 3+s --tlsrec 3+s --mod-http hcsmix,dcsmix' ;;
        alt)     printf '%s' '--fake -1 --ttl 3 --md5sig' ;;
        alt2)    printf '%s' '--split 1+s --disorder 3+s --mod-http hcsmix,dcsmix' ;;
        alt3)    printf '%s' '--fake -1 --ttl 3 --md5sig' ;;
        alt4)    printf '%s' '--split 1+s --disorder 3+s --mod-http hcsmix,dcsmix' ;;
        alt5)    printf '%s' '--split 1+s --tlsrec 1+s --mod-http hcsmix,dcsmix' ;;
        alt6)    printf '%s' '--split 1+s --tlsrec 1+s' ;;
        *)       printf '%s' '<bilinmeyen>' ;;
    esac
}

expected_dns() {
    case "$1" in
        default | alt3 | alt4 | alt5) printf '%s' 'yandex' ;;
        alt | alt2 | alt6)            printf '%s' 'off' ;;
        *)                            printf '%s' '<bilinmeyen>' ;;
    esac
}

(
    # shellcheck source=/dev/null
    . "$LIB_FILE"

    for method in $METHOD_LIST; do
        check_eq "method_args:$method" "$(expected_args "$method")" "$(method_args "$method")"
        check_eq "method_dns_mode:$method" "$(expected_dns "$method")" "$(method_dns_mode "$method")"
    done

    check_eq "method_args:default-when-omitted" "$(expected_args default)" "$(method_args)"

    GOODBYEDPI_ARGS='--fake -1 --ttl 4 --split 5+s'
    check_eq "method_args:GOODBYEDPI_ARGS-override" '--fake -1 --ttl 4 --split 5+s' "$(method_args alt6)"
    unset GOODBYEDPI_ARGS

    if (method_args yok-boyle-bir-yontem >/dev/null 2>&1); then
        fail "method_args:unknown-method-dies"
    else
        pass "method_args:unknown-method-dies"
    fi

    if (method_dns_mode yok-boyle-bir-yontem >/dev/null 2>&1); then
        fail "method_dns_mode:unknown-method-dies"
    else
        pass "method_dns_mode:unknown-method-dies"
    fi
)

# --------------------------------------------------------------------------
# d — render_unit
# --------------------------------------------------------------------------

(
    # shellcheck source=/dev/null
    . "$LIB_FILE"
    CIADPI_BIN="$STUB_BIN/ciadpi"

    unit="$(render_unit "$UNIT_NAME" "$CIADPI_BIN" --split 1+s --disorder 3+s)"

    check_has "render_unit:execstart-ciadpi" "$unit" "ExecStart=$CIADPI_BIN "
    check_has "render_unit:ip" "$unit" '--ip "127.0.0.1"'
    check_has "render_unit:port" "$unit" '--port "1080"'
    # render_unit quotes every whitespace-separated token, which systemd parses
    # back into the same argv, so `--split 1+s` lands as two quoted tokens.
    check_has "render_unit:arg-split" "$unit" '"--split" "1+s"'
    check_has "render_unit:arg-disorder" "$unit" '"--disorder" "3+s"'
    check_has "render_unit:caps-socks" "$unit" 'AmbientCapabilities=CAP_NET_RAW'
    check_has_not "render_unit:caps-socks-no-net-admin" "$unit" 'CAP_NET_ADMIN'
    check_has_not "render_unit:no-args-placeholder" "$unit" '@ARGS@'
    check_has_not "render_unit:no-ciadpi-placeholder" "$unit" '@CIADPI@'
)

(
    PROXY_MODE=transparent
    # shellcheck source=/dev/null
    . "$LIB_FILE"
    CIADPI_BIN="$STUB_BIN/ciadpi"

    unit="$(render_unit "$UNIT_NAME" "$CIADPI_BIN" --fake -1 --ttl 3 --md5sig)"

    check_has "render_unit:transparent-caps" "$unit" 'AmbientCapabilities=CAP_NET_RAW CAP_NET_ADMIN'
    check_has "render_unit:transparent-bound" "$unit" 'CapabilityBoundingSet=CAP_NET_RAW CAP_NET_ADMIN'
    check_has "render_unit:transparent-args" "$unit" '"--fake"'
)

# --------------------------------------------------------------------------
# e — DRY_RUN=1 is a side-effect free preview
# --------------------------------------------------------------------------

(
    DRY_RUN=1
    # shellcheck source=/dev/null
    . "$LIB_FILE"
    STATE_DIR="$TMP/dry-state"
    STATE_FILE="$STATE_DIR/prev-state.env"

    preview="$(save_state lo 2>/dev/null)"
    rc=$?
    check_eq "dry-run:rc" 0 "$rc"
    check_has "dry-run:prints-would-run" "$preview" 'would-run:'

    stray=0
    while IFS= read -r line; do
        case "$line" in
            '') : ;;
            would-run:*) : ;;
            *) stray=1 ;;
        esac
    done <<<"$preview"
    check_eq "dry-run:only-preview-lines" 0 "$stray"

    if [ -e "$STATE_DIR" ]; then
        fail "dry-run:no-state-dir"
    else
        pass "dry-run:no-state-dir"
    fi
    if [ -e "$STATE_FILE" ]; then
        fail "dry-run:no-state-file"
    else
        pass "dry-run:no-state-file"
    fi
)

# --------------------------------------------------------------------------
# f — save_state / restore_state round-trip (real sandbox files, stub commands)
# --------------------------------------------------------------------------

(
    DRY_RUN=0
    STUB_RESOLVECTL_STATUS='Global'
    export STUB_RESOLVECTL_STATUS
    # shellcheck source=/dev/null
    . "$LIB_FILE"
    STATE_DIR="$TMP/state"
    STATE_FILE="$STATE_DIR/prev-state.env"
    UNIT_PATH="$TMP/etc/$UNIT_NAME.service"
    CIADPI_BIN="$STUB_BIN/ciadpi"

    calls_reset
    save_state lo >/dev/null 2>&1
    rc=$?
    check_eq "save_state:rc" 0 "$rc"

    if [ -f "$STATE_FILE" ]; then
        pass "save_state:state-file-created"
    else
        fail "save_state:state-file-created"
    fi

    check_eq "save_state:mode-600" 600 "$(stat -c '%a' "$STATE_FILE" 2>/dev/null)"

    for key in SAVED_IFACE SAVED_PROXY_MODE SAVED_DNS_BACKEND SAVED_DNS_PREV \
        SAVED_RESOLV_BACKUP SAVED_PROXY_BACKEND SAVED_GS_MODE SAVED_GS_HOST \
        SAVED_GS_PORT SAVED_GS_IGNORE SAVED_ENV_FILE SAVED_ENV_FILE_PRESENT; do
        if grep -q "^$key=" "$STATE_FILE" 2>/dev/null; then
            pass "save_state:key-$key"
        else
            fail "save_state:key-$key"
        fi
    done

    check_eq "save_state:iface-value" 'SAVED_IFACE=lo' "$(grep '^SAVED_IFACE=' "$STATE_FILE" 2>/dev/null)"
    check_eq "save_state:dns-backend-value" 'SAVED_DNS_BACKEND=resolved' "$(grep '^SAVED_DNS_BACKEND=' "$STATE_FILE" 2>/dev/null)"

    calls_reset
    restore_state >/dev/null 2>&1
    rc=$?
    check_eq "restore_state:rc" 0 "$rc"

    if [ -f "$STATE_FILE" ]; then
        fail "restore_state:state-file-removed"
    else
        pass "restore_state:state-file-removed"
    fi

    trace="$(calls)"
    check_has "restore_state:dns-command" "$trace" 'resolvectl revert lo'
    check_has "restore_state:flush-caches" "$trace" 'resolvectl flush-caches'
    check_has "restore_state:transparent-down-first" "$trace" 'iptables -t nat -D OUTPUT -j GOODBYEDPI_TURKEY'

    restore_state >/dev/null 2>&1
    rc=$?
    check_eq "restore_state:second-call-safe" 0 "$rc"
)

# --------------------------------------------------------------------------
# g — transparent_up / transparent_down (iptables and nft branches)
# --------------------------------------------------------------------------

(
    DRY_RUN=0
    PROXY_MODE=transparent
    # shellcheck source=/dev/null
    . "$LIB_FILE"

    calls_reset
    transparent_up >/dev/null 2>&1
    rc=$?
    check_eq "transparent_up:rc" 0 "$rc"

    trace="$(calls)"
    check_has "transparent_up:chain-flush" "$trace" 'iptables -t nat -F GOODBYEDPI_TURKEY'
    check_has_not "transparent_up:chain-not-recreated" "$trace" 'iptables -t nat -N GOODBYEDPI_TURKEY'
    check_has "transparent_up:private-range-return" "$trace" 'iptables -t nat -A GOODBYEDPI_TURKEY -d 10.0.0.0/8 -j RETURN'
    check_has "transparent_up:port-return" "$trace" 'iptables -t nat -A GOODBYEDPI_TURKEY -p tcp -m tcp --dport 1080 -j RETURN'
    check_has "transparent_up:redirect" "$trace" 'iptables -t nat -A GOODBYEDPI_TURKEY -p tcp -j REDIRECT --to-ports 1080'
    check_has "transparent_up:output-hook" "$trace" 'iptables -t nat -A OUTPUT -j GOODBYEDPI_TURKEY'

    calls_reset
    transparent_down >/dev/null 2>&1
    rc=$?
    check_eq "transparent_down:rc" 0 "$rc"

    trace="$(calls)"
    check_has "transparent_down:unhook" "$trace" 'iptables -t nat -D OUTPUT -j GOODBYEDPI_TURKEY'
    check_has "transparent_down:flush-chain" "$trace" 'iptables -t nat -F GOODBYEDPI_TURKEY'
    check_has "transparent_down:delete-chain" "$trace" 'iptables -t nat -X GOODBYEDPI_TURKEY'
)

(
    DRY_RUN=0
    PROXY_MODE=transparent
    # shellcheck source=/dev/null
    . "$LIB_FILE"
    # nft-only PATH: iptables is not reachable, so the fallback branch is used.
    PATH="$STUB_BIN_NFT"
    export PATH

    calls_reset
    transparent_up >/dev/null 2>&1
    rc=$?
    check_eq "transparent_up-nft:rc" 0 "$rc"

    trace="$(calls)"
    check_has "transparent_up-nft:table" "$trace" 'nft add table ip goodbyedpi_turkey'
    check_has "transparent_up-nft:chain" "$trace" 'nft add chain ip goodbyedpi_turkey output'
    check_has "transparent_up-nft:redirect" "$trace" 'nft add rule ip goodbyedpi_turkey output tcp redirect to :1080'
    check_has_not "transparent_up-nft:no-iptables" "$trace" 'iptables'

    calls_reset
    transparent_down >/dev/null 2>&1
    rc=$?
    check_eq "transparent_down-nft:rc" 0 "$rc"
    check_has "transparent_down-nft:delete-table" "$(calls)" 'nft delete table ip goodbyedpi_turkey'
)

# --------------------------------------------------------------------------
# h — backend detection returns documented values
# --------------------------------------------------------------------------

(
    # shellcheck source=/dev/null
    . "$LIB_FILE"

    dns_backend="$(detect_dns_backend)"
    case "$dns_backend" in
        resolved | resolvconf) pass "detect_dns_backend:documented-value ($dns_backend)" ;;
        *) fail "detect_dns_backend:documented-value (gelen: [$dns_backend])" ;;
    esac

    proxy_backend="$(detect_proxy_backend)"
    case "$proxy_backend" in
        none | environmentd | gsettings) pass "detect_proxy_backend:documented-value ($proxy_backend)" ;;
        *) fail "detect_proxy_backend:documented-value (gelen: [$proxy_backend])" ;;
    esac
)

(
    STUB_RESOLVECTL_STATUS='Global'
    STUB_GSETTINGS_SCHEMA=1
    export STUB_RESOLVECTL_STATUS STUB_GSETTINGS_SCHEMA
    # shellcheck source=/dev/null
    . "$LIB_FILE"

    check_eq "detect_dns_backend:resolved" 'resolved' "$(detect_dns_backend)"
    check_eq "detect_proxy_backend:gsettings" 'gsettings' "$(detect_proxy_backend)"
)

# --------------------------------------------------------------------------
# i — require_root and the sudo password-prompt problem
#
# The real sudo binary is NEVER reached: both cases put a stub `sudo` first in
# PATH and that stub only records its argv. This matters — invoking the real
# sudo here could ask for a password and charge the attempt to pam_faillock,
# which is exactly the failure the library is meant to avoid.
# `sudo -n true` is the cache probe; `sudo --preserve-env=<list> -- <script>`
# is the re-exec (an explicit allow-list, never `-E`).
# --------------------------------------------------------------------------

SUDO_CACHED="$TMP/sudo-cached"
SUDO_NOCACHE="$TMP/sudo-nocache"
mkdir -p "$SUDO_CACHED" "$SUDO_NOCACHE"

# write_sudo_stub <dir> — argv-logging sudo stub; the exit code of the `-n true`
# cache probe is controlled by SUDO_STUB_PROBE_RC so one stub serves both cases.
write_sudo_stub() {
    cat >"$1/sudo" <<'STUB'
#!/bin/bash
# Test stub for sudo: records argv, never touches PAM.
printf 'sudo %s\n' "$*" >>"${CALLS_LOG:-/dev/null}"
case " $* " in
    *' -n true '*) exit "${SUDO_STUB_PROBE_RC:-0}" ;;
esac
exit 0
STUB
    chmod +x "$1/sudo"
}
write_sudo_stub "$SUDO_CACHED"
write_sudo_stub "$SUDO_NOCACHE"

# The re-exec keeps an explicit allow-list instead of the whole environment;
# read the list from the library so the assertion cannot drift from the code.
SUDO_KEEP="$(
    # shellcheck source=/dev/null
    . "$LIB_FILE"
    printf '%s' "$_GDT_SUDO_KEEP"
)"

# A stand-in for the wrapper the user ran; never executed (sudo is stubbed).
FAKE_WRAPPER="$TMP/turkey_dnsredir.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"$FAKE_WRAPPER"

( # (a) cached credential: re-exec happens, no hint, no failure
    DRY_RUN=0
    SUDO_STUB_PROBE_RC=0
    PATH="$SUDO_CACHED:$PATH"
    export PATH SUDO_STUB_PROBE_RC
    # shellcheck source=/dev/null
    . "$LIB_FILE"

    calls_reset
    out="$(require_root "$FAKE_WRAPPER" 2>&1)"
    rc=$?
    trace="$(calls)"

    check_eq "require_root:cached-credential-rc" 0 "$rc"
    check_has "require_root:cached-credential-reexec" "$trace" "sudo --preserve-env=$SUDO_KEEP -- $FAKE_WRAPPER"
    check_has_not "require_root:cached-credential-no-sudo-E" "$trace" 'sudo -E'
    check_has_not "require_root:cached-credential-no-hint" "$out" 'faillock'
)

( # (b) no TTY and no cached credential: stop with instructions, never re-exec
    DRY_RUN=0
    SUDO_STUB_PROBE_RC=1
    PATH="$SUDO_NOCACHE:$PATH"
    export PATH SUDO_STUB_PROBE_RC

    child="$TMP/no-tty-child.sh"
    cat >"$child" <<'CHILD'
#!/usr/bin/env bash
# Sources the library and calls require_root with no controlling terminal.
set -u
# shellcheck source=/dev/null
. "$1"
require_root "$2"
CHILD
    chmod +x "$child"

    out_file="$TMP/no-tty.out"
    calls_reset
    if setsid -w true 2>/dev/null; then
        # </dev/null kills stdin, setsid drops the controlling terminal, so
        # sudo would have nowhere to print a prompt.
        setsid -w bash "$child" "$LIB_FILE" "$FAKE_WRAPPER" </dev/null >"$out_file" 2>&1
        rc=$?
    else
        fail "require_root:no-tty-case-needs-setsid"
        : >"$out_file"
        rc=0
    fi
    out="$(cat "$out_file")"
    trace="$(calls)"

    if [ "$rc" -eq 0 ]; then
        fail "require_root:no-tty-nonzero-rc (rc=0)"
    else
        pass "require_root:no-tty-nonzero-rc"
    fi
    check_has "require_root:no-tty-hint-sudo-v" "$out" 'sudo -v'
    check_has "require_root:no-tty-hint-faillock" "$out" 'faillock --user'
    check_has "require_root:no-tty-hint-retry-command" "$out" "sudo --preserve-env=$SUDO_KEEP -- $FAKE_WRAPPER"
    check_has_not "require_root:no-tty-no-raw-password-error" "$out" 'a password is required'
    check_has_not "require_root:no-tty-no-raw-tty-error" "$out" 'a terminal is required'
    check_has "require_root:no-tty-cache-probe-only" "$trace" 'sudo -n true'
    check_has_not "require_root:no-tty-no-sudo-E" "$trace" 'sudo -E'
)

# --------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------

passed=$(grep -c '^ok ' "$RESULTS" 2>/dev/null || true)
failed=$(grep -c '^fail ' "$RESULTS" 2>/dev/null || true)
passed=${passed:-0}
failed=${failed:-0}

printf 'lib-test: %s passed, %s failed\n' "$passed" "$failed"

if [ "$failed" -eq 0 ]; then
    exit 0
fi
exit 1
