#!/usr/bin/env bash
# linux/scripts/_lib.sh — shared layer for the GoodbyeDPI-Turkey Linux port.
#
# This file is SOURCED, never executed. It must stay Bash 3.2 compatible
# (no mapfile/readarray, no ${var,,}, no associative arrays).
#
# Rules:
#   * every system-mutating command goes through `run` so DRY_RUN=1 is a
#     side-effect free preview;
#   * read-only queries go through `_capture` and never change state;
#   * nothing here calls sudo except the require_root re-exec.

# --------------------------------------------------------------------------
# Paths and constants
# --------------------------------------------------------------------------

LINUX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="$(cd "$LINUX_DIR/.." && pwd)"

CIADPI_BIN="$LINUX_DIR/bin/ciadpi"
CIADPI_HOST="127.0.0.1"
CIADPI_PORT="1080"

STATE_DIR="/var/lib/goodbyedpi-turkey"
STATE_FILE="$STATE_DIR/prev-state.env"

UNIT_NAME="goodbyedpi-turkey"
UNIT_PATH="/etc/systemd/system/$UNIT_NAME.service"
UNIT_TEMPLATE="$LINUX_DIR/systemd/$UNIT_NAME.service.template"

DEFAULT_DNS_V4_PRIMARY="77.88.8.8"
DEFAULT_DNS_V4_SECONDARY="77.88.8.1"

DRY_RUN="${DRY_RUN:-0}"
PROXY_MODE="${GOODBYEDPI_PROXY_MODE:-${PROXY_MODE:-socks}}"

# nft table/chain names used by transparent mode
NFT_TABLE="goodbyedpi_turkey"
IPT_CHAIN="GOODBYEDPI_TURKEY"
# IPv6 mirrors: IPv6 traffic must not bypass the redirect (O2).
IP6_T_CHAIN="GOODBYEDPI_TURKEY6"
NFT6_TABLE="goodbyedpi_turkey6"

case "$PROXY_MODE" in
    socks|transparent) ;;
    *) printf 'err: PROXY_MODE gecersiz: %s (socks|transparent)\n' "$PROXY_MODE" >&2; return 1 2>/dev/null || exit 1 ;;
esac

# In-memory copy of the last saved state, so DRY_RUN previews can also
# preview the restore.
_GDT_STATE_BODY=""

# --------------------------------------------------------------------------
# Environment hardening
# --------------------------------------------------------------------------

# Everything this library creates is private by default: the state file and
# the rendered unit carry the saved proxy/DNS snapshot and the desync
# arguments, so they must never be world-readable, not even between creation
# and a later chmod.
umask 077

# Fixed command lookup order for privileged code. `sudo -E` used to hand root
# the caller's PATH, so every bare `tee`/`rm`/`cp`/`chmod`/`mv`/`systemctl`
# below could resolve through a caller-owned directory (root code execution).
_GDT_SAFE_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Environment variables kept across the sudo re-exec: the documented knobs and
# DRY_RUN, nothing else. `-E` would preserve all of the caller's environment.
_GDT_SUDO_KEEP="DRY_RUN,GOODBYEDPI_ARGS,GOODBYEDPI_PROXY_MODE,GOODBYEDPI_DNS"

# --------------------------------------------------------------------------
# Logging
# --------------------------------------------------------------------------

if [ -t 2 ]; then
    _C_INFO=$'\033[36m'; _C_WARN=$'\033[33m'; _C_ERR=$'\033[31m'; _C_OFF=$'\033[0m'
else
    _C_INFO=''; _C_WARN=''; _C_ERR=''; _C_OFF=''
fi

log()  { printf '%s[i]%s %s\n' "$_C_INFO" "$_C_OFF" "$*" >&2; }
warn() { printf '%s[!]%s %s\n' "$_C_WARN" "$_C_OFF" "$*" >&2; }
err()  { printf '%s[x]%s %s\n' "$_C_ERR" "$_C_OFF" "$*" >&2; }
die()  { err "$*"; exit 1; }

# Root only: force the fixed lookup order, because only root's lookups can be
# turned into root code execution. An unprivileged run keeps the caller PATH —
# that is where a dry-run wrapper or the stub-based test suite keeps its
# shadowed commands.
if [ "$(id -u)" = "0" ] && [ "${PATH:-}" != "$_GDT_SAFE_PATH" ]; then
    warn "PATH sabitlendi (root): '${PATH:-}' yerine '$_GDT_SAFE_PATH'"
    PATH="$_GDT_SAFE_PATH"
fi
export PATH

# --------------------------------------------------------------------------
# Command execution
# --------------------------------------------------------------------------

# run <cmd...> — the only way this library mutates the system.
run() {
    if [ "$DRY_RUN" = "1" ]; then
        printf 'would-run: %s\n' "$(_gdt_preview "$@")"
        return 0
    fi
    "$@"
}

# Read-only external query. Never used for anything that changes state.
_capture() { "$@" 2>/dev/null || true; }

# _write_file <path> — write stdin to <path> through `run`, keeping the
# dry-run preview on stdout (plain `| run tee >/dev/null` would swallow it).
_write_file() {
    local path="${1:-}" body
    [ -n "$path" ] || die "_write_file: yol bos"
    body=$(cat)
    if [ "$DRY_RUN" = "1" ]; then
        run tee "$path"
        return 0
    fi
    printf '%s\n' "$body" | run tee "$path" >/dev/null
}

_gdt_preview() {
    local out="" a
    for a in "$@"; do
        case "$a" in
            *[[:space:]]*) out="$out '$a'" ;;
            '') out="$out ''" ;;
            *) out="$out $a" ;;
        esac
    done
    printf '%s' "${out# }"
}

# --------------------------------------------------------------------------
# Preconditions
# --------------------------------------------------------------------------

require_linux() {
    [ "$(uname -s 2>/dev/null)" = "Linux" ] || die "Bu betik yalnizca Linux icin: uname -s -> $(uname -s 2>/dev/null)"
}

# _sudo_can_prompt — can sudo ask for a password in this context?
# stdin itself is not enough: a desktop launcher or an agent terminal may have
# stdin redirected while still owning a controlling terminal, and sudo reads
# its prompt from /dev/tty, not from stdin.
_sudo_can_prompt() {
    [ -t 0 ] && return 0
    [ -e /dev/tty ] || return 1
    sh -c ': < /dev/tty' 2>/dev/null
}

# require_root "$0" — re-exec under sudo, preserving GOODBYEDPI_* env.
#
# A password prompt needs a terminal. When the wrapper is started from a pipe,
# a launcher or any session without a controlling TTY, a blind `sudo -E` dies
# with only a raw sudo error on screen — and each blind retry is charged to
# pam_faillock, which locks the account for ~10 minutes after 3 failures. So
# the no-prompt case is detected *before* any authentication attempt and is
# answered with instructions instead.
require_root() {
    local script="${1:-$0}" user retry shown msg
    require_linux
    [ "$(id -u)" = "0" ] && return 0
    if [ "$DRY_RUN" = "1" ]; then
        warn "root degil; DRY_RUN=1 oldugu icin sudo atlandi (sistem degismez)"
        return 0
    fi
    command -v sudo >/dev/null 2>&1 || die "root gerekli ve sudo bulunamadi: sudo $script"

    if ! _sudo_can_prompt; then
        # Without a terminal only an already cached credential can work.
        # `sudo -n true` never prompts and is never charged as a failed
        # authentication attempt, so it cannot add to a faillock lockout.
        if ! sudo -n true 2>/dev/null; then
            user="${USER:-}"
            [ -n "$user" ] || user="$(id -un 2>/dev/null)"
            shown="$script"
            case "$shown" in *[[:space:]]*) shown="'$shown'" ;; esac
            retry="sudo --preserve-env=$_GDT_SUDO_KEEP -- $shown"
            msg=$(printf '%s\n' \
                'root gerekiyor ama bu oturumda sudo sifre soramaz: terminal (TTY) yok.' \
                'Bu yuzden hic sifre denemeden durdum; asagidaki adimlari uygulayin.' \
                '' \
                'Gercek bir terminal penceresinde su sirayla tekrar deneyin:' \
                '  1) Bir terminal penceresi acin (gnome-terminal, konsole, xterm, sanal TTY...).' \
                '  2) Sifrenizi bir kez girin ve kimligi onbellekte tutun:  sudo -v' \
                "  3) Bu komutu o terminalde tekrar calistirin:  $retry" \
                '' \
                'Uyar: uste uste 3 hatali sifre denemesi hesabi ~10 dakika kilitler (pam_faillock).' \
                "  Kilidi kontrol edin:  faillock --user $user" \
                "  Kilidi sifirlayin:    faillock --user $user --reset")
            die "$msg"
        fi
    fi
    log "Yetki yukseltiliyor: sudo --preserve-env=$_GDT_SUDO_KEEP -- $script $*"
    exec sudo --preserve-env="$_GDT_SUDO_KEEP" -- "$script" "$@"
}

require_ciadpi() {
    [ -x "$CIADPI_BIN" ] || die "ciadpi bulunamadi: $CIADPI_BIN — once 'linux/build.sh' calistirin"
    return 0
}

require_systemd() {
    command -v systemctl >/dev/null 2>&1 || die "systemctl bulunamadi; servis modu bu sistemde kullanilamaz (tek seferlik yontemi deneyin)"
    return 0
}

# --------------------------------------------------------------------------
# Method table
# --------------------------------------------------------------------------

_METHODS="default alt alt2 alt3 alt4 alt5 alt6"

_is_method() {
    local m
    for m in $_METHODS; do [ "$m" = "$1" ] && return 0; done
    return 1
}

method_args() {
    local method="${1:-default}"
    _is_method "$method" || die "Bilinmeyen yontem: $method (gecerli: $_METHODS)"
    if [ -n "${GOODBYEDPI_ARGS:-}" ]; then
        printf '%s\n' "$GOODBYEDPI_ARGS"
        return 0
    fi
    case "$method" in
        default) printf '%s\n' '--fake -1 --md5sig --ttl 8 --split 1+s --disorder 3+s --tlsrec 3+s --mod-http hcsmix,dcsmix' ;;
        alt)     printf '%s\n' '--fake -1 --ttl 3 --md5sig' ;;
        alt2)    printf '%s\n' '--split 1+s --disorder 3+s --mod-http hcsmix,dcsmix' ;;
        alt3)    printf '%s\n' '--fake -1 --ttl 3 --md5sig' ;;
        alt4)    printf '%s\n' '--split 1+s --disorder 3+s --mod-http hcsmix,dcsmix' ;;
        alt5)    printf '%s\n' '--split 1+s --tlsrec 1+s --mod-http hcsmix,dcsmix' ;;
        alt6)    printf '%s\n' '--split 1+s --tlsrec 1+s' ;;
    esac
}

method_dns_mode() {
    local method="${1:-default}"
    _is_method "$method" || die "Bilinmeyen yontem: $method (gecerli: $_METHODS)"
    case "$method" in
        default|alt3|alt4|alt5) printf '%s\n' 'yandex' ;;
        alt|alt2|alt6)          printf '%s\n' 'off' ;;
    esac
}

# --------------------------------------------------------------------------
# Backend detection (read-only)
# --------------------------------------------------------------------------

detect_dns_backend() {
    if command -v resolvectl >/dev/null 2>&1 && [ -n "$(_capture resolvectl status)" ]; then
        printf '%s\n' 'resolved'
        return 0
    fi
    [ -r /etc/resolv.conf ] || die "/etc/resolv.conf okunamiyor; DNS arka ucu yok"
    printf '%s\n' 'resolvconf'
}

detect_proxy_backend() {
    if command -v gsettings >/dev/null 2>&1 &&
       _capture gsettings list-schemas | grep -qx 'org.gnome.system.proxy'; then
        printf '%s\n' 'gsettings'
        return 0
    fi
    if [ -d /etc/environment.d ] && [ -w /etc/environment.d ]; then
        printf '%s\n' 'environmentd'
        return 0
    fi
    if [ -d "$HOME/.config/environment.d" ] && [ -w "$HOME/.config/environment.d" ]; then
        printf '%s\n' 'environmentd'
        return 0
    fi
    if [ -w "$HOME/.config" ]; then
        printf '%s\n' 'environmentd'
        return 0
    fi
    printf '%s\n' 'none'
}

# Default route interface, e.g. "eth0". Read-only.
detect_default_iface() {
    local iface=""
    if command -v ip >/dev/null 2>&1; then
        iface=$(_capture ip route show default | sed -n 's/.*[[:space:]]dev[[:space:]]\([^[:space:]]*\).*/\1/p' | head -n 1)
    fi
    [ -n "$iface" ] || die "Varsayilan ag arayuzu belirlenemedi (ip route show default bos)"
    printf '%s\n' "$iface"
}

# --------------------------------------------------------------------------
# State
# --------------------------------------------------------------------------

# State values are stored raw (one KEY=value per line). Keep them reversible:
# values never contain newlines, and no shell quoting is applied, so a value
# that already carries GVariant quotes (e.g. gsettings get output) survives.
_gdt_q() { printf '%s' "$1" | tr -d '\n'; }

# Managed env file for the environment.d proxy backend.
_env_file_path() {
    if [ "$(id -u)" = "0" ] && [ -d /etc/environment.d ] && [ -w /etc/environment.d ]; then
        printf '%s\n' "/etc/environment.d/90-goodbyedpi-turkey.conf"
    elif [ -d "$HOME/.config/environment.d" ]; then
        printf '%s\n' "$HOME/.config/environment.d/90-goodbyedpi-turkey.conf"
    else
        printf '%s\n' "$HOME/.config/environment.d/90-goodbyedpi-turkey.conf"
    fi
}

# save_state <iface> — snapshot everything apply_* can change.
save_state() {
    local iface="${1:-}"
    [ -n "$iface" ] || iface=$(detect_default_iface)

    local dns_backend proxy_backend prev_dns="" resolv_bak="" env_file="" env_present=0
    local gs_mode='' gs_host='' gs_port='' gs_ignore=''
    local t_backend='none' t_v6=0
    local body

    dns_backend=$(detect_dns_backend)
    proxy_backend=$(detect_proxy_backend)

    # Transparent mode records what it is about to install, so teardown uses
    # the same backend instead of re-detecting it later (O3).
    if [ "$PROXY_MODE" = 'transparent' ]; then
        t_backend=$(_transparent_backend)
        t_v6=$(_transparent_v6_capable "$t_backend")
    fi

    if [ "$dns_backend" = 'resolved' ]; then
        prev_dns=$(_capture resolvectl dns "$iface" | sed -n 's/^[^:]*:[[:space:]]*//p' | head -n 1)
    else
        resolv_bak="$STATE_DIR/resolv.conf.bak"
        if [ ! -f "$resolv_bak" ]; then
            run mkdir -p "$STATE_DIR"
            run chmod 700 "$STATE_DIR"
            run cp -p /etc/resolv.conf "$resolv_bak"
        else
            log "Mevcut resolv.conf yedegi korunuyor: $resolv_bak"
        fi
    fi

    if [ "$proxy_backend" = 'gsettings' ]; then
        gs_mode=$(_capture gsettings get org.gnome.system.proxy mode)
        gs_host=$(_capture gsettings get org.gnome.system.proxy.socks host)
        gs_port=$(_capture gsettings get org.gnome.system.proxy.socks port)
        gs_ignore=$(_capture gsettings get org.gnome.system.proxy ignore-hosts)
    elif [ "$proxy_backend" = 'environmentd' ]; then
        env_file=$(_env_file_path)
        [ -f "$env_file" ] && env_present=1
    fi

    body=$(cat <<EOF
SAVED_IFACE=$(_gdt_q "$iface")
SAVED_PROXY_MODE=$(_gdt_q "$PROXY_MODE")
SAVED_DNS_BACKEND=$(_gdt_q "$dns_backend")
SAVED_DNS_PREV=$(_gdt_q "$prev_dns")
SAVED_RESOLV_BACKUP=$(_gdt_q "$resolv_bak")
SAVED_PROXY_BACKEND=$(_gdt_q "$proxy_backend")
SAVED_GS_MODE=$(_gdt_q "$gs_mode")
SAVED_GS_HOST=$(_gdt_q "$gs_host")
SAVED_GS_PORT=$(_gdt_q "$gs_port")
SAVED_GS_IGNORE=$(_gdt_q "$gs_ignore")
SAVED_ENV_FILE=$(_gdt_q "$env_file")
SAVED_ENV_FILE_PRESENT=$(_gdt_q "$env_present")
SAVED_TRANSPARENT_BACKEND=$(_gdt_q "$t_backend")
SAVED_TRANSPARENT_V6=$(_gdt_q "$t_v6")
EOF
)
    _GDT_STATE_BODY="$body"
    run mkdir -p "$STATE_DIR"
    run chmod 700 "$STATE_DIR"
    # Write to a sibling and rename: the final path is never readable with a
    # wider mode, not even for the instant between create and chmod.
    printf '%s\n' "$body" | _write_file "$STATE_FILE.tmp"
    run chmod 600 "$STATE_FILE.tmp"
    run mv -f "$STATE_FILE.tmp" "$STATE_FILE"
    log "Durum kaydedildi: $STATE_FILE (arayuz=$iface, dns=$dns_backend, proxy=$proxy_backend)"
}

# Parse raw "KEY=value" lines from stdin into SAVED_* globals.
_gdt_load_state() {
    local line key val
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        key=${line%%=*}
        val=${line#*=}
        case "$key" in
            SAVED_IFACE)           SAVED_IFACE="$val" ;;
            SAVED_PROXY_MODE)      SAVED_PROXY_MODE="$val" ;;
            SAVED_DNS_BACKEND)     SAVED_DNS_BACKEND="$val" ;;
            SAVED_DNS_PREV)        SAVED_DNS_PREV="$val" ;;
            SAVED_RESOLV_BACKUP)   SAVED_RESOLV_BACKUP="$val" ;;
            SAVED_PROXY_BACKEND)   SAVED_PROXY_BACKEND="$val" ;;
            SAVED_GS_MODE)         SAVED_GS_MODE="$val" ;;
            SAVED_GS_HOST)         SAVED_GS_HOST="$val" ;;
            SAVED_GS_PORT)         SAVED_GS_PORT="$val" ;;
            SAVED_GS_IGNORE)       SAVED_GS_IGNORE="$val" ;;
            SAVED_ENV_FILE)        SAVED_ENV_FILE="$val" ;;
            SAVED_ENV_FILE_PRESENT) SAVED_ENV_FILE_PRESENT="$val" ;;
            SAVED_TRANSPARENT_BACKEND) SAVED_TRANSPARENT_BACKEND="$val" ;;
            SAVED_TRANSPARENT_V6)  SAVED_TRANSPARENT_V6="$val" ;;
        esac
    done
}

# restore_state — idempotent; safe to call twice and with no state at all.
restore_state() {
    local body="" from_file=0
    if [ -r "$STATE_FILE" ]; then
        body=$(cat "$STATE_FILE" 2>/dev/null || true)
        [ -n "$body" ] && from_file=1
    fi
    if [ -z "$body" ] && [ -n "$_GDT_STATE_BODY" ]; then
        body="$_GDT_STATE_BODY"
    fi
    if [ -z "$body" ]; then
        log "Geri yuklenecek durum yok ($STATE_FILE)"
        return 0
    fi

    SAVED_IFACE=''; SAVED_PROXY_MODE=''; SAVED_DNS_BACKEND=''; SAVED_DNS_PREV=''
    SAVED_RESOLV_BACKUP=''; SAVED_PROXY_BACKEND=''; SAVED_GS_MODE=''
    SAVED_GS_HOST=''; SAVED_GS_PORT=''; SAVED_GS_IGNORE=''
    SAVED_ENV_FILE=''; SAVED_ENV_FILE_PRESENT=''
    SAVED_TRANSPARENT_BACKEND=''; SAVED_TRANSPARENT_V6=''
    # here-string (not a pipe) so the SAVED_* assignments survive in this shell
    _gdt_load_state <<< "$body"

    # transparent rules first: they reference the port ciadpi was listening on.
    # Teardown is failure-tolerant by design, but the `|| true` here makes the
    # guarantee explicit: nothing may abort before the proxy/DNS restore below.
    transparent_down || true

    case "${SAVED_PROXY_BACKEND:-none}" in
        gsettings)
            if [ -n "${SAVED_GS_MODE:-}" ]; then
                run gsettings set org.gnome.system.proxy mode "$SAVED_GS_MODE" || true
            else
                run gsettings set org.gnome.system.proxy mode 'none' || true
            fi
            [ -n "${SAVED_GS_HOST:-}" ] && { run gsettings set org.gnome.system.proxy.socks host "$SAVED_GS_HOST" || true; }
            [ -n "${SAVED_GS_PORT:-}" ] && { run gsettings set org.gnome.system.proxy.socks port "$SAVED_GS_PORT" || true; }
            [ -n "${SAVED_GS_IGNORE:-}" ] && { run gsettings set org.gnome.system.proxy ignore-hosts "$SAVED_GS_IGNORE" || true; }
            ;;
        environmentd)
            if [ "${SAVED_ENV_FILE_PRESENT:-0}" = '1' ]; then
                log "Onceki environment.d dosyasi korunuyor: ${SAVED_ENV_FILE:-}"
            elif [ -n "${SAVED_ENV_FILE:-}" ]; then
                run rm -f "$SAVED_ENV_FILE" || true
            fi
            ;;
        *) : ;;
    esac

    case "${SAVED_DNS_BACKEND:-none}" in
        resolved)
            if [ -n "${SAVED_DNS_PREV:-}" ]; then
                # shellcheck disable=SC2086
                run resolvectl dns "$SAVED_IFACE" $SAVED_DNS_PREV || true
            else
                run resolvectl revert "$SAVED_IFACE" || true
            fi
            run resolvectl flush-caches || true
            ;;
        resolvconf)
            if [ -n "${SAVED_RESOLV_BACKUP:-}" ] && [ -f "$SAVED_RESOLV_BACKUP" ]; then
                run cp -p "$SAVED_RESOLV_BACKUP" /etc/resolv.conf || true
                run rm -f "$SAVED_RESOLV_BACKUP"
            else
                log "resolv.conf yedegi yok; DNS degistirilmemis olabilir"
            fi
            ;;
        *) : ;;
    esac

    if [ "$from_file" = '1' ]; then
        run rm -f "$STATE_FILE"
    fi
    _GDT_STATE_BODY=""
    log "Onceki durum geri yuklendi (arayuz=${SAVED_IFACE:-?})"
}

# --------------------------------------------------------------------------
# Proxy
# --------------------------------------------------------------------------

apply_proxy() {
    if [ "$PROXY_MODE" = 'transparent' ]; then
        log "PROXY_MODE=transparent: SOCKS proxy kurulmuyor (iptables/nft yonlendirmesi kullanilir)"
        return 0
    fi
    local backend env_file
    backend=$(detect_proxy_backend)
    case "$backend" in
        gsettings)
            run gsettings set org.gnome.system.proxy mode 'manual'
            run gsettings set org.gnome.system.proxy.socks host "$CIADPI_HOST"
            run gsettings set org.gnome.system.proxy.socks port "$CIADPI_PORT"
            run gsettings set org.gnome.system.proxy ignore-hosts "['localhost', '127.0.0.0/8', '::1']"
            log "GNOME proxy ayarlandi: socks $CIADPI_HOST:$CIADPI_PORT"
            ;;
        environmentd)
            env_file=$(_env_file_path)
            run mkdir -p "$(dirname "$env_file")"
            printf 'ALL_PROXY=socks5h://%s:%s\nall_proxy=socks5h://%s:%s\n' \
                "$CIADPI_HOST" "$CIADPI_PORT" "$CIADPI_HOST" "$CIADPI_PORT" |
                _write_file "$env_file"
            log "environment.d proxy yazildi: $env_file (yeniden oturum acinca etkin)"
            ;;
        none)
            warn "Kullanilabilir proxy arka ucu yok (gsettings yok, environment.d yazilamiyor); SOCKS proxy kurulmadi"
            ;;
    esac
}

clear_proxy() {
    local backend env_file
    backend=$(detect_proxy_backend)
    case "$backend" in
        gsettings)
            run gsettings set org.gnome.system.proxy mode 'none'
            log "GNOME proxy kapatildi"
            ;;
        environmentd)
            env_file=$(_env_file_path)
            run rm -f "$env_file"
            log "environment.d proxy dosyasi kaldirildi: $env_file"
            ;;
        none) : ;;
    esac
}

# --------------------------------------------------------------------------
# DNS
# --------------------------------------------------------------------------

apply_dns() {
    local iface="${1:-}"
    [ -n "$iface" ] || iface=$(detect_default_iface)
    local backend
    backend=$(detect_dns_backend)
    case "$backend" in
        resolved)
            run resolvectl dns "$iface" "$DEFAULT_DNS_V4_PRIMARY" "$DEFAULT_DNS_V4_SECONDARY"
            run resolvectl flush-caches
            log "DNS (systemd-resolved) $iface -> $DEFAULT_DNS_V4_PRIMARY $DEFAULT_DNS_V4_SECONDARY"
            ;;
        resolvconf)
            printf 'nameserver %s\nnameserver %s\n' "$DEFAULT_DNS_V4_PRIMARY" "$DEFAULT_DNS_V4_SECONDARY" |
                _write_file /etc/resolv.conf
            log "DNS (/etc/resolv.conf) -> $DEFAULT_DNS_V4_PRIMARY $DEFAULT_DNS_V4_SECONDARY"
            ;;
    esac
}

clear_dns() {
    local iface="${1:-}"
    [ -n "$iface" ] || iface=$(detect_default_iface)
    local backend
    backend=$(detect_dns_backend)
    case "$backend" in
        resolved)
            run resolvectl revert "$iface"
            run resolvectl flush-caches
            log "DNS (systemd-resolved) $iface geri alindi"
            ;;
        resolvconf)
            if [ -f "$STATE_DIR/resolv.conf.bak" ]; then
                run cp -p "$STATE_DIR/resolv.conf.bak" /etc/resolv.conf
                run rm -f "$STATE_DIR/resolv.conf.bak"
                log "/etc/resolv.conf yedekten geri yuklendi"
            else
                warn "/etc/resolv.conf yedegi yok: $STATE_DIR/resolv.conf.bak"
            fi
            ;;
    esac
}

# --------------------------------------------------------------------------
# Transparent mode (iptables, nft fallback)
# --------------------------------------------------------------------------

_transparent_backend() {
    if command -v iptables >/dev/null 2>&1; then
        printf '%s\n' 'iptables'
    elif command -v nft >/dev/null 2>&1; then
        printf '%s\n' 'nft'
    else
        printf '%s\n' 'none'
    fi
}

transparent_up() {
    [ "$PROXY_MODE" = 'transparent' ] || return 0
    local backend
    backend=$(_transparent_backend)
    case "$backend" in
        iptables)
            # idempotent under `set -e`: create the chain only when missing
            if iptables -t nat -n -L "$IPT_CHAIN" >/dev/null 2>&1; then
                run iptables -t nat -F "$IPT_CHAIN"
            else
                run iptables -t nat -N "$IPT_CHAIN"
            fi
            run iptables -t nat -A "$IPT_CHAIN" -d 127.0.0.0/8 -j RETURN
            run iptables -t nat -A "$IPT_CHAIN" -d 10.0.0.0/8 -j RETURN
            run iptables -t nat -A "$IPT_CHAIN" -d 172.16.0.0/12 -j RETURN
            run iptables -t nat -A "$IPT_CHAIN" -d 192.168.0.0/16 -j RETURN
            run iptables -t nat -A "$IPT_CHAIN" -p tcp -m tcp --dport "$CIADPI_PORT" -j RETURN
            run iptables -t nat -A "$IPT_CHAIN" -p tcp -j REDIRECT --to-ports "$CIADPI_PORT"
            if ! iptables -t nat -C OUTPUT -j "$IPT_CHAIN" >/dev/null 2>&1; then
                run iptables -t nat -A OUTPUT -j "$IPT_CHAIN"
            fi
            log "Seffaf mod: iptables nat/$IPT_CHAIN -> 127.0.0.1:$CIADPI_PORT"
            _transparent_up_ip6tables
            ;;
        nft)
            if nft list table "ip $NFT_TABLE" >/dev/null 2>&1; then
                run nft "delete table ip $NFT_TABLE"
            fi
            run nft "add table ip $NFT_TABLE"
            run nft "add chain ip $NFT_TABLE output { type nat hook output priority 0; policy accept; }"
            run nft "add rule ip $NFT_TABLE output ip daddr 127.0.0.0/8 return"
            run nft "add rule ip $NFT_TABLE output ip daddr 10.0.0.0/8 return"
            run nft "add rule ip $NFT_TABLE output ip daddr 172.16.0.0/12 return"
            run nft "add rule ip $NFT_TABLE output ip daddr 192.168.0.0/16 return"
            run nft "add rule ip $NFT_TABLE output tcp dport $CIADPI_PORT return"
            run nft "add rule ip $NFT_TABLE output tcp redirect to :$CIADPI_PORT"
            log "Seffaf mod: nft $NFT_TABLE output -> 127.0.0.1:$CIADPI_PORT"
            _transparent_up_nft6
            ;;
        none)
            die "Seffaf mod icin iptables veya nft gerekli; ikisi de bulunamadi"
            ;;
    esac
}

# 1 when <backend> can mirror the redirect for IPv6, 0 otherwise. Read-only:
# it only asks whether the tool is present, never whether a rule exists.
_transparent_v6_capable() {
    case "${1:-}" in
        iptables) command -v ip6tables >/dev/null 2>&1 && printf '1\n' || printf '0\n' ;;
        nft)      command -v nft >/dev/null 2>&1 && printf '1\n' || printf '0\n' ;;
        *)        printf '0\n' ;;
    esac
}

# IPv6 mirror of the iptables rules. Missing ip6tables is a warning, never a
# failure: IPv4 keeps working and teardown stays symmetric.
_transparent_up_ip6tables() {
    if ! command -v ip6tables >/dev/null 2>&1; then
        warn "ip6tables yok; IPv6 seffaf yonlendirme kurulmadi (IPv6 trafigi proxy'yi atlar)"
        return 0
    fi
    if ip6tables -t nat -n -L "$IP6_T_CHAIN" >/dev/null 2>&1; then
        run ip6tables -t nat -F "$IP6_T_CHAIN"
    else
        run ip6tables -t nat -N "$IP6_T_CHAIN"
    fi
    run ip6tables -t nat -A "$IP6_T_CHAIN" -d ::1/128 -j RETURN
    run ip6tables -t nat -A "$IP6_T_CHAIN" -d fc00::/7 -j RETURN
    run ip6tables -t nat -A "$IP6_T_CHAIN" -d fe80::/10 -j RETURN
    run ip6tables -t nat -A "$IP6_T_CHAIN" -p tcp -m tcp --dport "$CIADPI_PORT" -j RETURN
    run ip6tables -t nat -A "$IP6_T_CHAIN" -p tcp -j REDIRECT --to-ports "$CIADPI_PORT"
    if ! ip6tables -t nat -C OUTPUT -j "$IP6_T_CHAIN" >/dev/null 2>&1; then
        run ip6tables -t nat -A OUTPUT -j "$IP6_T_CHAIN"
    fi
    log "Seffaf mod: ip6tables nat/$IP6_T_CHAIN -> 127.0.0.1:$CIADPI_PORT"
    return 0
}

# IPv6 mirror of the nft rules. The table create is the capability probe: if
# nft cannot add it (kernel without ip6 nat, no netns support) the IPv6 half is
# skipped with a warning instead of aborting a working IPv4 setup.
_transparent_up_nft6() {
    if nft list table "ip6 $NFT6_TABLE" >/dev/null 2>&1; then
        run nft "delete table ip6 $NFT6_TABLE" || true
    fi
    if ! run nft "add table ip6 $NFT6_TABLE"; then
        warn "nft ip6 tablosu olusturulamadi; IPv6 seffaf yonlendirme atlandi (IPv6 trafigi proxy'yi atlar)"
        return 0
    fi
    run nft "add chain ip6 $NFT6_TABLE output { type nat hook output priority 0; policy accept; }"
    run nft "add rule ip6 $NFT6_TABLE output ip6 daddr ::1/128 return"
    run nft "add rule ip6 $NFT6_TABLE output ip6 daddr fc00::/7 return"
    run nft "add rule ip6 $NFT6_TABLE output ip6 daddr fe80::/10 return"
    run nft "add rule ip6 $NFT6_TABLE output tcp dport $CIADPI_PORT return"
    run nft "add rule ip6 $NFT6_TABLE output ip6 nexthdr tcp redirect to :$CIADPI_PORT"
    log "Seffaf mod: nft $NFT6_TABLE output -> 127.0.0.1:$CIADPI_PORT"
    return 0
}

# --- teardown -------------------------------------------------------------
# Every helper below is failure-tolerant: `set -e` must never abort a cleanup,
# because restore_state has to reach the proxy/DNS restore after it (O3).

_transparent_down_iptables() {
    command -v iptables >/dev/null 2>&1 || return 0
    if iptables -t nat -n -L "$IPT_CHAIN" >/dev/null 2>&1; then
        run iptables -t nat -D OUTPUT -j "$IPT_CHAIN" || true
        run iptables -t nat -F "$IPT_CHAIN" || true
        run iptables -t nat -X "$IPT_CHAIN" || true
        log "Seffaf mod IPv4 kurallari kaldirildi (iptables)"
    fi
    return 0
}

_transparent_down_ip6tables() {
    command -v ip6tables >/dev/null 2>&1 || return 0
    if ip6tables -t nat -n -L "$IP6_T_CHAIN" >/dev/null 2>&1; then
        run ip6tables -t nat -D OUTPUT -j "$IP6_T_CHAIN" || true
        run ip6tables -t nat -F "$IP6_T_CHAIN" || true
        run ip6tables -t nat -X "$IP6_T_CHAIN" || true
        log "Seffaf mod IPv6 kurallari kaldirildi (ip6tables)"
    fi
    return 0
}

_transparent_down_nft() {
    command -v nft >/dev/null 2>&1 || return 0
    if nft list table "ip $NFT_TABLE" >/dev/null 2>&1; then
        run nft "delete table ip $NFT_TABLE" || true
        log "Seffaf mod IPv4 tablosu kaldirildi (nft)"
    fi
    return 0
}

_transparent_down_nft6() {
    command -v nft >/dev/null 2>&1 || return 0
    if nft list table "ip6 $NFT6_TABLE" >/dev/null 2>&1; then
        run nft "delete table ip6 $NFT6_TABLE" || true
        log "Seffaf mod IPv6 tablosu kaldirildi (nft)"
    fi
    return 0
}

transparent_down() {
    local backend v6
    # Prefer the backend recorded at install time: re-detecting at teardown
    # time leaves nft-installed rules behind when iptables happens to be
    # present as well (O3).
    backend="${SAVED_TRANSPARENT_BACKEND:-}"
    if [ -n "$backend" ]; then
        v6="${SAVED_TRANSPARENT_V6:-$(_transparent_v6_capable "$backend")}"
    else
        backend=$(_transparent_backend)
        v6=$(_transparent_v6_capable "$backend")
    fi
    case "$backend" in
        iptables)
            _transparent_down_iptables
            [ "$v6" = '1' ] && _transparent_down_ip6tables
            # leftovers of the other backend, when it is available
            _transparent_down_nft
            _transparent_down_nft6
            ;;
        nft)
            _transparent_down_nft
            [ "$v6" = '1' ] && _transparent_down_nft6
            _transparent_down_iptables
            _transparent_down_ip6tables
            ;;
        *)
            # nothing recorded: clean everything that is reachable
            _transparent_down_iptables
            _transparent_down_ip6tables
            _transparent_down_nft
            _transparent_down_nft6
            ;;
    esac
    return 0
}

# --------------------------------------------------------------------------
# Cleanup + ciadpi process
# --------------------------------------------------------------------------

_gdt_cleanup() {
    local rc=$?
    [ "$PROXY_MODE" = 'transparent' ] && transparent_down
    restore_state
    exit "$rc"
}

install_cleanup_trap() {
    trap '_gdt_cleanup' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
}

# start_ciadpi_foreground <args...> — background + wait (no exec) so the EXIT
# trap still restores state. ciadpi itself is started directly because a
# background job's pid (needed for signal forwarding) cannot come from `run`.
start_ciadpi_foreground() {
    local rc=0 pid=""
    require_ciadpi
    if [ "$DRY_RUN" = "1" ]; then
        run "$CIADPI_BIN" --ip "$CIADPI_HOST" --port "$CIADPI_PORT" "$@"
        return 0
    fi
    "$CIADPI_BIN" --ip "$CIADPI_HOST" --port "$CIADPI_PORT" "$@" &
    pid=$!
    log "ciadpi calisiyor: pid=$pid, $CIADPI_HOST:$CIADPI_PORT"
    trap 'kill -TERM "$pid" 2>/dev/null || true' INT TERM
    wait "$pid" || rc=$?
    wait "$pid" 2>/dev/null || true
    trap - INT TERM
    return "$rc"
}

# --------------------------------------------------------------------------
# systemd unit rendering
# --------------------------------------------------------------------------

_sd_quote() {
    printf '"%s"' "$(printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\$/$$/g')"
}

render_unit() {
    local label="${1:-$UNIT_NAME}" ciadpi="${2:-$CIADPI_BIN}"
    shift 2 2>/dev/null || shift $#
    [ -n "$label" ] || die "render_unit: etiket bos"
    [ -n "$ciadpi" ] || die "render_unit: ciadpi yolu bos"
    [ -r "$UNIT_TEMPLATE" ] || die "render_unit: sablon bulunamadi: $UNIT_TEMPLATE"

    local args="" a q
    for a in "$@"; do
        q=$(_sd_quote "$a")
        args="$args $q"
    done
    args="--ip $(_sd_quote "$CIADPI_HOST") --port $(_sd_quote "$CIADPI_PORT")${args}"

    local caps="CAP_NET_RAW"
    [ "$PROXY_MODE" = 'transparent' ] && caps="CAP_NET_RAW CAP_NET_ADMIN"

    sed -e "s|@CIADPI@|$ciadpi|g" \
        -e "s|@ARGS@|$args|g" \
        -e "s|^AmbientCapabilities=.*|AmbientCapabilities=$caps|" \
        -e "s|^CapabilityBoundingSet=.*|CapabilityBoundingSet=$caps|" \
        "$UNIT_TEMPLATE"
}

# --------------------------------------------------------------------------
# Methods
# --------------------------------------------------------------------------

run_method_oneshot() {
    local method="${1:-default}" args mode iface
    local argv=()
    require_linux
    require_root "$0"
    require_ciadpi
    args=$(method_args "$method")
    mode=$(method_dns_mode "$method")
    iface=$(detect_default_iface)

    install_cleanup_trap
    save_state "$iface"
    [ "$mode" = 'yandex' ] && apply_dns "$iface"
    if [ "$PROXY_MODE" = 'transparent' ]; then
        transparent_up
    else
        apply_proxy
    fi

    log "Yontem: $method (dns=$mode, proxy=$PROXY_MODE, arayuz=$iface)"
    # method_args returns one string; split it into argv exactly once so the
    # desync arguments reach ciadpi literally (no globbing).
    read -r -a argv <<< "$args"
    start_ciadpi_foreground "${argv[@]}"
}

run_method_service_install() {
    local method="${1:-default}" args mode iface
    local argv=()
    require_linux
    require_root "$0"
    require_ciadpi
    require_systemd
    args=$(method_args "$method")
    mode=$(method_dns_mode "$method")
    iface=$(detect_default_iface)

    if [ -f "$UNIT_PATH" ]; then
        log "Var olan servis durduruluyor: $UNIT_NAME"
        run systemctl stop "$UNIT_NAME"
        run systemctl disable "$UNIT_NAME"
        run rm -f "$UNIT_PATH"
    fi

    if [ -f "$STATE_FILE" ]; then
        log "Onceki durum korunuyor: $STATE_FILE"
    else
        save_state "$iface"
    fi

    # same single argv split as the one-shot path: no globbing
    read -r -a argv <<< "$args"
    render_unit "$UNIT_NAME" "$CIADPI_BIN" "${argv[@]}" | _write_file "$UNIT_PATH"
    run systemctl daemon-reload
    run systemctl enable --now "$UNIT_NAME"

    [ "$mode" = 'yandex' ] && apply_dns "$iface"
    if [ "$PROXY_MODE" = 'transparent' ]; then
        transparent_up
    else
        apply_proxy
    fi
    log "Servis kuruldu: $UNIT_PATH (yontem=$method, dns=$mode, proxy=$PROXY_MODE)"
}

run_service_remove() {
    require_linux
    require_root "$0"
    require_systemd
    if systemctl list-unit-files "$UNIT_NAME.service" >/dev/null 2>&1; then
        run systemctl stop "$UNIT_NAME"
        run systemctl disable "$UNIT_NAME"
    fi
    if [ -f "$UNIT_PATH" ]; then
        run rm -f "$UNIT_PATH"
    fi
    run systemctl daemon-reload
    transparent_down
    restore_state
    log "Servis kaldirildi ve onceki durum geri yuklendi: $UNIT_NAME"
}
