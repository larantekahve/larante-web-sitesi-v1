#!/usr/bin/env bash
# DWS-1 S1 reviewer-isolation preflight (read-only). Exit 0 = PASS, 1 = FAIL (blocking), 2 = cannot run.
# Usage (Git Bash): bash reviewer-preflight.sh [reviewer-home]   default: C:\Users\Monster\.codex-review
# Supplies CODEX_HOME per process only; never exports it. Launches no model.
# Fail-closed: a CLI listing that fails, is empty or is unrecognised is a FAIL, never "no findings".
# The reviewer config is validated with TOML-aware parsing (Python 3.11+ tomllib), not text matching.
H="${1:-C:\\Users\\Monster\\.codex-review}"
CFG="$(cygpath -u "$H")/config.toml"
fail=0; note() { printf '%-42s %s\n' "$1" "$2"; }
[ -f "$CFG" ] || { echo "reviewer config missing: $CFG"; exit 2; }
command -v codex >/dev/null 2>&1 || { echo "codex not on PATH"; exit 2; }
command -v python >/dev/null 2>&1 || { echo "python not on PATH (tomllib needed)"; exit 2; }
python -c "import tomllib" 2>/dev/null || { echo "python tomllib unavailable (need Python 3.11+)"; exit 2; }

ver=$(CODEX_HOME="$H" codex --version 2>&1 | head -1); note "codex version" "$ver"
case "$ver" in codex-cli\ 0.154.*) ;; *) note "  expected codex-cli 0.154.x" "FAIL"; fail=1;; esac

# MCP servers: the command must succeed AND report exactly an empty JSON array.
mcp_raw=$(CODEX_HOME="$H" codex mcp list --json 2>/dev/null); mcp_rc=$?
mcp=$(printf '%s' "$mcp_raw" | grep -v '^WARNING' | tr -d ' \n\r')
note "mcp list --json (rc=$mcp_rc)" "${mcp:-<empty>}"
if [ "$mcp_rc" != "0" ]; then note "  mcp inventory unavailable" "FAIL"; fail=1
elif [ "$mcp" != "[]" ]; then note "  expected []" "FAIL"; fail=1; fi

# Plugins: the command must succeed and its output must be a recognised inventory.
# Local marketplaces (bundled / primary-runtime) must not exist in this home. Account-level remote connectors
# ("installed, enabled" in the remote catalogue) cannot be changed by local config; each must be disabled by a
# [plugins."<name>"] table whose `enabled` value is false (TOML check below), and features.apps must be false.
plist=$(CODEX_HOME="$H" codex plugin list 2>&1); pl_rc=$?
plist=$(printf '%s\n' "$plist" | grep -v '^WARNING')
recognised=$(printf '%s\n' "$plist" | grep -cE '^(Marketplace `|No marketplace plugins found)')
note "plugin list (rc=$pl_rc, recognised=$recognised)" "$(printf '%s\n' "$plist" | head -1 | cut -c1-60)"
if [ "$pl_rc" != "0" ] || [ "$recognised" = "0" ]; then note "  plugin inventory unavailable/unrecognised" "FAIL"; fail=1; fi
localmk=$(printf '%s\n' "$plist" | grep -cE '^Marketplace `(openai-bundled|openai-primary-runtime)`')
note "local marketplaces present" "$localmk"; [ "$localmk" = "0" ] || { note "  local plugin marketplace in reviewer home" "FAIL"; fail=1; }
remote_en=$(printf '%s\n' "$plist" | awk '/^Marketplace `openai-curated-remote`/{r=1} r && $2=="installed," && $3=="enabled"{print $1}' | tr '\n' ' ')
note "remote connectors installed+enabled" "${remote_en:-none}"

# Feature families: the command must succeed and every family must be reported as false.
feat=$(CODEX_HOME="$H" codex features list 2>/dev/null); ft_rc=$?
[ "$ft_rc" = "0" ] || { note "features list" "FAIL (rc=$ft_rc)"; fail=1; }
for f in apps computer_use browser_use browser_use_external browser_use_full_cdp_access image_generation hooks js_repl multi_agent skill_mcp_dependency_install skill_search; do
  v=$(printf '%s\n' "$feat" | awk -v k="$f" '$1==k{print $NF}')
  note "feature $f" "${v:-?}"; [ "$v" = "false" ] || { note "  expected false" "FAIL"; fail=1; }
done

# Reviewer config: TOML-aware validation of the effective (root) settings and prohibited tables.
cfg_out=$(REMOTE_EN="$remote_en" python - "$(cygpath -w "$CFG")" <<'PY'
import os, sys, tomllib
bad = []
try:
    with open(sys.argv[1], 'rb') as fh:
        cfg = tomllib.load(fh)
except Exception as e:
    print(f"FAIL parse: {e}"); sys.exit(1)
for key in ('notify', 'mcp_servers', 'projects', 'marketplaces', 'hooks', 'profile', 'profiles', 'model_providers', 'shell_environment_policy'):
    if key in cfg: bad.append(f"prohibited root key/table `{key}`")
if cfg.get('sandbox_mode') != 'read-only': bad.append(f"root sandbox_mode = {cfg.get('sandbox_mode')!r} (expected 'read-only')")
if cfg.get('approval_policy') != 'never': bad.append(f"root approval_policy = {cfg.get('approval_policy')!r} (expected 'never')")
feats = cfg.get('features', {})
if not isinstance(feats, dict): bad.append("features is not a table"); feats = {}
for f in ('apps','computer_use','browser_use','browser_use_external','browser_use_full_cdp_access','image_generation','hooks','js_repl','multi_agent','skill_mcp_dependency_install','skill_search'):
    if feats.get(f) is not False: bad.append(f"features.{f} is not false in config")
plugins = cfg.get('plugins', {})
if not isinstance(plugins, dict): bad.append("plugins is not a table"); plugins = {}
for name, tbl in plugins.items():
    if not (isinstance(tbl, dict) and tbl.get('enabled') is False): bad.append(f"plugin `{name}` is not disabled (enabled must be false)")
for name in os.environ.get('REMOTE_EN', '').split():
    if not (isinstance(plugins.get(name), dict) and plugins[name].get('enabled') is False): bad.append(f"account-level connector `{name}` has no enabled = false table")
win = cfg.get('windows', {})
if isinstance(win, dict) and win.get('sandbox') not in ('elevated', 'unelevated', None): bad.append(f"windows.sandbox = {win.get('sandbox')!r}")
print("\n".join(bad) if bad else "OK root: sandbox_mode=read-only approval_policy=never; features off; plugins all disabled; no prohibited tables")
sys.exit(1 if bad else 0)
PY
); cfg_rc=$?
printf '%s\n' "$cfg_out" | while IFS= read -r l; do note "config (toml)" "$l"; done
[ "$cfg_rc" = "0" ] || fail=1

auth=$(CODEX_HOME="$H" codex login status 2>&1); au_rc=$?
auth=$(printf '%s\n' "$auth" | sed -E 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+/<email>/g' | head -1)
note "login status (rc=$au_rc)" "$auth"; case "$au_rc:$auth" in 0:*"Logged in"*) ;; *) note "  reviewer home not authenticated" "FAIL"; fail=1;; esac

[ -z "${CODEX_HOME:-}" ] || { note "CODEX_HOME exported in this shell" "FAIL (must be per-process only)"; fail=1; }
[ "$fail" = 0 ] && { echo "REVIEWER PREFLIGHT: PASS"; exit 0; } || { echo "REVIEWER PREFLIGHT: FAIL (blocking)"; exit 1; }
