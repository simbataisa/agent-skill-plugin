#!/usr/bin/env bash
# BMAD Playwright environment diagnostic
# ---------------------------------------
# Runs the diagnostic ladder from
#   agents/tester-qe/references/ui-automation-playwright.md § Troubleshooting
# so tester-qe can decide — in one command, without retry loops — whether to:
#   * proceed with the current playwright.config (READY)
#   * change the local port (FIX A)
#   * skip webServer and target a deployed URL  (FIX B, MCP-sandbox default)
#   * bind to 0.0.0.0 instead of 127.0.0.1      (FIX C)
#
# Usage:
#   scripts/check-playwright-env.sh                 # auto-detect port from playwright.config.*
#   scripts/check-playwright-env.sh --port 3100     # override port
#   scripts/check-playwright-env.sh --json          # machine-readable verdict
#
# Exit codes:
#   0  READY         — environment can bind; existing config should work
#   1  FIX_A         — loopback bind blocked on THIS port; use a different one
#   2  FIX_B         — sandbox blocks all local binds; use BASE_URL against a deployed URL
#   3  FIX_C         — 127.0.0.1 blocked but 0.0.0.0 works; rebind the app
#   4  NO_NODE       — Node.js not on PATH; cannot diagnose
#   5  CONFIG_ERROR  — playwright config missing or unreadable
# ---------------------------------------

set -u

PORT=""
EMIT_JSON="false"
PROJECT_ROOT="$(pwd)"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --port) PORT="$2"; shift 2 ;;
        --port=*) PORT="${1#*=}"; shift ;;
        --json) EMIT_JSON="true"; shift ;;
        --project-root) PROJECT_ROOT="$2"; shift 2 ;;
        --project-root=*) PROJECT_ROOT="${1#*=}"; shift ;;
        -h|--help)
            sed -n '2,/^set -u$/p' "$0" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *) echo "unknown arg: $1" >&2; exit 64 ;;
    esac
done

# ---------- helpers ----------

emit_json() {
    # $1=verdict  $2=exit_code  $3=port  $4=loopback_ok  $5=any_ok  $6=webserver  $7=base_url  $8=message
    printf '{"verdict":"%s","exit":%s,"port":%s,"loopbackOk":%s,"anyInterfaceOk":%s,"webServerConfigured":%s,"baseUrl":%s,"message":%s}\n' \
        "$1" "$2" \
        "${3:-null}" \
        "$4" "$5" "$6" \
        "${7:-null}" \
        "$(printf '%s' "$8" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || printf '"%s"' "$8")"
}

emit_human() {
    # $1=verdict $2=message
    local verdict="$1" message="$2"
    case "$verdict" in
        READY)  printf '\033[0;32m✓ READY\033[0m — %s\n' "$message" ;;
        FIX_A)  printf '\033[0;33m⚠ FIX A\033[0m — %s\n' "$message" ;;
        FIX_B)  printf '\033[0;33m⚠ FIX B\033[0m — %s\n' "$message" ;;
        FIX_C)  printf '\033[0;33m⚠ FIX C\033[0m — %s\n' "$message" ;;
        *)      printf '\033[0;31m✗ %s\033[0m — %s\n' "$verdict" "$message" ;;
    esac
}

report() {
    local verdict="$1" code="$2" msg="$3"
    if [[ "$EMIT_JSON" == "true" ]]; then
        emit_json "$verdict" "$code" "${PORT:-null}" "${LOOPBACK_OK:-null}" "${ANY_OK:-null}" "${HAS_WEBSERVER:-null}" "${BASE_URL:-}" "$msg"
    else
        emit_human "$verdict" "$msg"
    fi
    exit "$code"
}

# ---------- step 0: Node present? ----------
if ! command -v node >/dev/null 2>&1; then
    report NO_NODE 4 "node not found on PATH — cannot run the bind diagnostic."
fi

# ---------- step 1: inspect playwright config ----------
CONFIG_FILE=""
for c in playwright.config.ts playwright.config.js playwright.config.mjs playwright.config.cjs; do
    if [[ -f "$PROJECT_ROOT/$c" ]]; then CONFIG_FILE="$PROJECT_ROOT/$c"; break; fi
done

HAS_WEBSERVER="false"
DETECTED_PORT=""
if [[ -n "$CONFIG_FILE" ]]; then
    if grep -qE '^\s*webServer\s*:' "$CONFIG_FILE"; then
        HAS_WEBSERVER="true"
    fi
    # Try to pull port from `url: 'http(s)://host:PORT'` or `port: PORT`
    DETECTED_PORT="$(grep -Eo "url:\s*['\"]https?://[^'\"]+" "$CONFIG_FILE" 2>/dev/null \
                    | grep -Eo ':[0-9]+' | head -n1 | tr -d ':')"
    if [[ -z "$DETECTED_PORT" ]]; then
        DETECTED_PORT="$(grep -Eo "port:\s*[0-9]+" "$CONFIG_FILE" 2>/dev/null \
                        | grep -Eo '[0-9]+' | head -n1)"
    fi
fi

# Resolve the port we'll test
if [[ -z "$PORT" ]]; then
    PORT="${DETECTED_PORT:-3000}"
fi
if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
    report CONFIG_ERROR 5 "detected port '$PORT' is not numeric"
fi

BASE_URL="${BASE_URL:-}"

# ---------- step 2: bind test on 127.0.0.1 ----------
# Use a short-lived Node one-liner. Exit 0 on listening, 1 on any error.
bind_test() {
    local host="$1" port="$2"
    node -e "
const s = require('http').createServer();
s.on('error', e => { console.error(e.code || e.message); process.exit(1); });
s.listen($port, '$host', () => { s.close(() => process.exit(0)); });
setTimeout(() => { try { s.close(); } catch(_) {} process.exit(1); }, 3000);
" 2>&1
}

LOOPBACK_OUTPUT="$(bind_test 127.0.0.1 "$PORT" || true)"
LOOPBACK_RC=$?
if [[ $LOOPBACK_RC -eq 0 ]]; then
    LOOPBACK_OK="true"
else
    LOOPBACK_OK="false"
fi

# ---------- step 3: bind test on 0.0.0.0 (only if loopback failed) ----------
ANY_OK="null"
ANY_OUTPUT=""
if [[ "$LOOPBACK_OK" == "false" ]]; then
    ANY_OUTPUT="$(bind_test 0.0.0.0 "$PORT" || true)"
    ANY_RC=$?
    if [[ $ANY_RC -eq 0 ]]; then ANY_OK="true"; else ANY_OK="false"; fi
fi

# ---------- step 4: verdict ----------
if [[ "$LOOPBACK_OK" == "true" ]]; then
    msg="Node can bind 127.0.0.1:$PORT. Existing config should run. "
    if [[ "$HAS_WEBSERVER" == "true" ]]; then
        msg+="(webServer is configured — Playwright will boot the app itself.)"
    else
        msg+="(no webServer block — ensure your app is running or BASE_URL is set before tests.)"
    fi
    report READY 0 "$msg"
fi

# Loopback blocked — is it EPERM or something else?
IS_EPERM="false"
if echo "$LOOPBACK_OUTPUT" | grep -qE 'EPERM|EACCES'; then
    IS_EPERM="true"
fi

if [[ "$ANY_OK" == "true" ]]; then
    report FIX_C 3 "127.0.0.1:$PORT is blocked (error: $LOOPBACK_OUTPUT) but 0.0.0.0:$PORT works. Start the app with HOST=0.0.0.0 and keep Playwright's url as http://127.0.0.1:$PORT."
fi

# Nothing binds at all.
if [[ "$IS_EPERM" == "true" ]]; then
    msg="Sandbox forbids local listening sockets (EPERM on both 127.0.0.1:$PORT and 0.0.0.0:$PORT). Apply Fix B: remove 'webServer' from playwright.config and set BASE_URL to a deployed URL (staging / preview / tunnel)."
    report FIX_B 2 "$msg"
fi

# Non-EPERM failure on both — probably the port itself is blocked but other ports may work.
report FIX_A 1 "Port $PORT cannot be bound (error: $LOOPBACK_OUTPUT). Try a different port (e.g. 3100): PORT=3100 npm run start, and update playwright.config url/port accordingly."
