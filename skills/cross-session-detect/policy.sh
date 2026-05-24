#!/usr/bin/env bash
# Cross-session conflict detection — policy resolver (slice-25, v1.16.0).
#
# Loads .claude/habeebs-policy.json from 4 scopes and merges them with
# scalar-override precedence: Managed > Local > Project > User > Defaults.
#
# Spec: docs/agents/specs/v1.16.0-cross-session-conflict-detection.md (Slice 2)
#
# Subcommands:
#   resolve    merge all scopes, validate, return effective policy as JSON

set -u

cmd=${1:-}
shift || true

# ---- path helpers (same as sidecar.sh) ----
abs_native_pwd() {
  if pwd -W >/dev/null 2>&1; then
    pwd -W
  else
    pwd
  fi
}

worktree_path() {
  (cd "$(git rev-parse --show-toplevel)" && abs_native_pwd)
}

home_dir() {
  if [ -n "${USERPROFILE:-}" ] && [ -d "$USERPROFILE" ]; then
    echo "$USERPROFILE"
  else
    echo "$HOME"
  fi
}

# ---- resolve ----
do_resolve() {
  local wt managed_path user_path project_path local_path
  wt=$(worktree_path)

  user_path="$(home_dir)/.claude/habeebs-policy.json"
  project_path="$wt/.claude/habeebs-policy.json"
  local_path="$wt/.claude/habeebs-policy.local.json"
  managed_path="${HABEEBS_MANAGED_POLICY:-}"

  local skip_val="${HABEEBS_SKIP:-}"

  USER_PATH="$user_path" \
  PROJECT_PATH="$project_path" \
  LOCAL_PATH="$local_path" \
  MANAGED_PATH="$managed_path" \
  SKIP_VAL="$skip_val" \
  node -e '
    const fs = require("fs");

    const KNOWN_KEYS = new Set([
      "pretool_use",
      "liveness_ttl_seconds",
      "require_signed_signals",
      "$schema"
    ]);

    const DEFAULTS = {
      pretool_use: false,
      liveness_ttl_seconds: 86400,
      require_signed_signals: false
    };

    const DEFERRED_KEYS = {
      prefer_worktree: "v1.1"
    };

    function readPolicy(path, label) {
      if (!path || !fs.existsSync(path)) return null;
      let raw;
      try { raw = fs.readFileSync(path, "utf8"); }
      catch { return null; }
      let parsed;
      try { parsed = JSON.parse(raw); }
      catch (e) {
        process.stderr.write("error: invalid JSON in " + label + " (" + path + "): " + e.message + "\n");
        process.exit(1);
      }
      if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
        process.stderr.write("error: " + label + " (" + path + ") must be a JSON object\n");
        process.exit(1);
      }
      for (const key of Object.keys(parsed)) {
        if (DEFERRED_KEYS[key]) {
          process.stderr.write(
            "error: \"" + key + "\" is not supported in v1 — deferred to " +
            DEFERRED_KEYS[key] + ". Remove it from " + label + " (" + path + ").\n"
          );
          process.exit(1);
        }
        if (!KNOWN_KEYS.has(key)) {
          process.stderr.write(
            "error: unknown key \"" + key + "\" in " + label + " (" + path + "). " +
            "Valid keys: " + [...KNOWN_KEYS].filter(k => k !== "$schema").join(", ") + ".\n"
          );
          process.exit(1);
        }
      }
      return parsed;
    }

    function validate(merged) {
      const ttl = merged.liveness_ttl_seconds;
      if (typeof ttl !== "number" || !Number.isFinite(ttl) || ttl <= 0) {
        process.stderr.write(
          "error: liveness_ttl_seconds must be a positive finite number, got: " +
          JSON.stringify(ttl) + "\n"
        );
        process.exit(1);
      }
      if (typeof merged.pretool_use !== "boolean") {
        process.stderr.write(
          "error: pretool_use must be a boolean, got: " +
          JSON.stringify(merged.pretool_use) + "\n"
        );
        process.exit(1);
      }
      if (typeof merged.require_signed_signals !== "boolean") {
        process.stderr.write(
          "error: require_signed_signals must be a boolean, got: " +
          JSON.stringify(merged.require_signed_signals) + "\n"
        );
        process.exit(1);
      }
    }

    // Read all scopes (lowest to highest precedence)
    const user    = readPolicy(process.env.USER_PATH,    "user-scope");
    const project = readPolicy(process.env.PROJECT_PATH, "project-scope");
    const local_  = readPolicy(process.env.LOCAL_PATH,   "local-scope");
    const managed = readPolicy(process.env.MANAGED_PATH, "managed-scope");

    // Merge: defaults <- user <- project <- local <- managed
    const merged = { ...DEFAULTS };
    for (const layer of [user, project, local_, managed]) {
      if (!layer) continue;
      for (const [k, v] of Object.entries(layer)) {
        if (k === "$schema") continue;
        merged[k] = v;
      }
    }

    validate(merged);

    // Attach skip list if HABEEBS_SKIP is set
    const skip = process.env.SKIP_VAL;
    if (skip) {
      merged.skip = skip.split(",").map(s => s.trim()).filter(Boolean);
    }

    process.stdout.write(JSON.stringify(merged));
  '
}

case "$cmd" in
  resolve) do_resolve ;;
  *) echo "usage: policy.sh {resolve}" >&2; exit 2 ;;
esac
