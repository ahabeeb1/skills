#!/usr/bin/env bash
# Cross-session conflict detection — sidecar lifecycle (slice-24, v1.16.0).
#
# Implements the four-sub-clause-guarded session sidecar per ADR-0019:
#   (a) advisory, (b) defined stale-data contract, (c) per-writer-unique
#   artifact, (d) read-only across writers.
#
# Sidecar location: $(git rev-parse --git-common-dir)/habeebs-sessions/<id>.json
# Spec: docs/agents/specs/v1.16.0-cross-session-conflict-detection.md (Slice 1)
#
# Subcommands:
#   write          --session-id <id>            create own sidecar
#   end            --session-id <id>            remove own sidecar
#   list           --session-id <self>          enumerate live peers (prunes
#                                               dead/expired sidecars; excludes
#                                               self)
#   probe          --pid <pid>                  -> alive | dead
#   probe-sidecar  --path <file>                -> alive | dead | inconclusive
#   current-env                                 -> posix | wsl-debian |
#                                                  powershell | git-bash

set -u

cmd=${1:-}
shift || true

# ---- env detection ----
detect_env() {
  if [ -n "${WSL_DISTRO_NAME:-}" ] || grep -qi microsoft /proc/version 2>/dev/null; then
    echo wsl-debian
  elif [ -n "${PSModulePath:-}" ] && [ -z "${MSYSTEM:-}" ]; then
    echo powershell
  elif [ -n "${MSYSTEM:-}" ]; then
    echo git-bash
  else
    echo posix
  fi
}

# ---- shared helpers ----
# pwd-style helper that prefers Win32-native paths when running under MSYS /
# Git Bash, so Node (a Win32 binary) can open the file without the /tmp →
# C:\tmp mistranslation. Falls back to POSIX absolute path elsewhere.
abs_native_pwd() {
  if pwd -W >/dev/null 2>&1; then
    pwd -W
  else
    pwd
  fi
}

common_dir() {
  # Force absolute so downstream Node calls don't get a bare .git/... path
  # whose resolution depends on cwd.
  local d; d=$(git rev-parse --git-common-dir)
  case "$d" in
    /*|?:*) printf '%s\n' "$d" ;;
    *)      (cd "$d" && abs_native_pwd) ;;
  esac
}

worktree_path() {
  # Override the simpler `git rev-parse --show-toplevel` so we get a path
  # Node can actually open under Windows.
  (cd "$(git rev-parse --show-toplevel)" && abs_native_pwd)
}
sidecar_dir() { echo "$(common_dir)/habeebs-sessions"; }
now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# Resolve the effective liveness_ttl_seconds via the 4-scope policy resolver
# (slice-25). Falls back to 86400 if the resolver errors (e.g. invalid JSON in
# a policy file — the resolver prints the error to stderr; we degrade silently
# here so the sidecar lifecycle doesn't crash on a bad policy file).
liveness_ttl() {
  local script_dir; script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  local ttl
  ttl=$(bash "$script_dir/policy.sh" resolve 2>/dev/null | node -e "
    let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{
      try{process.stdout.write(String(JSON.parse(d).liveness_ttl_seconds))}
      catch{process.stdout.write('86400')}
    });
  ") || true
  echo "${ttl:-86400}"
}

# Liveness probe via Node's process.kill(pid, 0). 0 = alive, 1 = dead.
# Fails SAFE: if node is unavailable we cannot determine liveness, so return
# `inconclusive` (TTL-gated, non-destructive) rather than `dead` — returning
# `dead` would make maybe_prune rm a live peer's sidecar and silently disable
# conflict detection for everyone.
probe_pid() {
  local pid="$1"
  command -v node >/dev/null 2>&1 || { echo inconclusive; return; }
  if node -e "try{process.kill($pid,0);process.exit(0)}catch{process.exit(1)}" 2>/dev/null; then
    echo alive
  else
    echo dead
  fi
}

# Read sidecar fields in a single Node invocation; emits 4 lines:
#   env, hostname, pid, start_epoch.
# One Node startup, four fields — amortizes the ~300ms Win32 Node cold-start
# cost that dominates runtime on Windows. Uses fs.readFileSync (not require)
# so paths needn't start with ./ or / for Node's module resolver.
read_sidecar_fields() {
  node -e "
    try {
      const fs = require('fs');
      const s = JSON.parse(fs.readFileSync(process.argv[1], 'utf8'));
      const epoch = s.start_time_iso
        ? Math.floor(new Date(s.start_time_iso).getTime() / 1000)
        : 0;
      process.stdout.write([s.env || '', s.hostname || '', s.pid || '', epoch].join('\\n'));
    } catch (e) {
      process.stdout.write(['', '', '', '0'].join('\\n'));
    }
  " "$1" 2>/dev/null
}

# Probe a peer sidecar. Returns alive | dead | inconclusive.
# Inconclusive when env or hostname differs from the calling process (we can't
# trust the PID-namespace), per ADR-0019 sub-clause (b).
probe_sidecar() {
  local path="$1"
  [ -f "$path" ] || { echo dead; return; }
  local self_env self_host fields peer_env peer_host peer_pid
  self_env=$(detect_env)
  self_host=$(hostname)
  fields=$(read_sidecar_fields "$path")
  peer_env=$(printf '%s' "$fields" | sed -n '1p')
  peer_host=$(printf '%s' "$fields" | sed -n '2p')
  peer_pid=$(printf '%s' "$fields" | sed -n '3p')
  if [ "$peer_env" != "$self_env" ] || [ "$peer_host" != "$self_host" ]; then
    echo inconclusive
    return
  fi
  probe_pid "$peer_pid"
}

# Prune a sidecar if it has aged out beyond the TTL with an inconclusive or
# dead probe. Returns 0 if pruned, 1 if kept. TTL is passed in (not re-read)
# so callers can amortize the policy-file read across a list-prune loop.
maybe_prune() {
  local path="$1" ttl="$2" probe start age
  probe=$(probe_sidecar "$path")
  case "$probe" in
    alive) return 1 ;;
    dead)  rm -f "$path"; return 0 ;;
    inconclusive)
      start=$(read_sidecar_fields "$path" | sed -n '4p')
      age=$(( $(date +%s) - start ))
      if [ "$age" -ge "$ttl" ]; then
        rm -f "$path"
        return 0
      fi
      return 1
      ;;
  esac
}

# ---- subcommands ----
do_write() {
  local sid="" pid_override=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --session-id) sid="$2"; shift 2 ;;
      --pid)        pid_override="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  [ -n "$sid" ] || { echo "write requires --session-id" >&2; exit 2; }

  local dir; dir=$(sidecar_dir)
  mkdir -p "$dir"
  local path="$dir/${sid}.json"
  local stash_sha; stash_sha=$(git stash create 2>/dev/null || true)
  local iso; iso=$(now_iso)
  local host; host=$(hostname)
  local env; env=$(detect_env)
  local wt; wt=$(worktree_path)
  # Default to PPID — the shell that invoked us, which in production is the
  # Claude Code session that ran the SessionStart hook. Caller can override
  # via --pid (used by tests pinning an OS-visible live process).
  local pid="${pid_override:-$PPID}"

  # Pass all values as argv-via-env to avoid path-translation surprises
  # (MSYS POSIX paths vs Node's Win32 view of the filesystem).
  PATH_ARG="$path" \
  SID="$sid" \
  PID_VAL="$pid" \
  HOST="$host" \
  ENV_KIND="$env" \
  ISO="$iso" \
  WT="$wt" \
  STASH="$stash_sha" \
  node -e '
    const fs = require("fs");
    fs.writeFileSync(process.env.PATH_ARG, JSON.stringify({
      session_id: process.env.SID,
      pid: parseInt(process.env.PID_VAL, 10),
      hostname: process.env.HOST,
      env: process.env.ENV_KIND,
      start_time_iso: process.env.ISO,
      worktree_path: process.env.WT,
      stash_sha: process.env.STASH,
      mtime_iso: process.env.ISO
    }, null, 2));
  '
}

do_end() {
  local sid=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --session-id) sid="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  [ -n "$sid" ] || { echo "end requires --session-id" >&2; exit 2; }
  rm -f "$(sidecar_dir)/${sid}.json"
}

do_list() {
  local self=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --session-id) self="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  local dir; dir=$(sidecar_dir)
  [ -d "$dir" ] || return 0

  # Read the TTL once and pass it into each prune call — every sidecar in the
  # directory consults the same policy, so re-reading per peer is waste.
  local ttl; ttl=$(liveness_ttl)

  for path in "$dir"/*.json; do
    [ -f "$path" ] || continue
    local base; base=$(basename "$path" .json)
    if [ "$base" = "$self" ]; then
      continue
    fi
    if maybe_prune "$path" "$ttl"; then
      continue
    fi
    # Sidecar survived the prune pass → live peer
    echo "$base"
  done
}

do_probe() {
  local pid=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --pid) pid="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  [ -n "$pid" ] || { echo "probe requires --pid" >&2; exit 2; }
  probe_pid "$pid"
}

do_probe_sidecar() {
  local path=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --path) path="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  [ -n "$path" ] || { echo "probe-sidecar requires --path" >&2; exit 2; }
  probe_sidecar "$path"
}

case "$cmd" in
  write)         do_write "$@" ;;
  end)           do_end "$@" ;;
  list)          do_list "$@" ;;
  probe)         do_probe "$@" ;;
  probe-sidecar) do_probe_sidecar "$@" ;;
  current-env)   detect_env ;;
  *) echo "usage: sidecar.sh {write|end|list|probe|probe-sidecar|current-env} [args...]" >&2; exit 2 ;;
esac
