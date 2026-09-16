#!/usr/bin/env bash
set -euo pipefail

repo="."
parallel=1
dry_run=false
while (($#)); do
  case "$1" in
    --repo) [[ $# -ge 2 ]] || { echo "error: --repo requires a value" >&2; exit 2; }; repo="$2"; shift 2 ;;
    --parallel) [[ $# -ge 2 ]] || { echo "error: --parallel requires a value" >&2; exit 2; }; parallel="$2"; shift 2 ;;
    --dry-run) dry_run=true; shift ;;
    --help|-h) echo 'Usage: send_task.sh [--repo OWNER/REPO|.] [--parallel 1-5] [--dry-run] -- "TASK"'; exit 0 ;;
    --) shift; break ;;
    *) echo "error: unknown option: $1" >&2; exit 2 ;;
  esac
done
[[ "$parallel" =~ ^[1-5]$ ]] || { echo "error: --parallel must be an integer from 1 to 5" >&2; exit 2; }
if (($#)); then task="$*"; elif [[ ! -t 0 ]]; then task="$(cat)"; else echo "error: provide a task after -- or through stdin" >&2; exit 2; fi
[[ -n "${task//[[:space:]]/}" ]] || { echo "error: task must not be empty" >&2; exit 2; }
jules_bin="$(command -v jules || true)"
[[ -n "$jules_bin" ]] || { echo "error: jules CLI not found; install @google/jules and run 'jules login'" >&2; exit 127; }

if [[ "$repo" == "." ]]; then
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "error: --repo . requires a Git working tree" >&2; exit 2; }
  [[ -z "$(git status --porcelain)" ]] || echo "warning: uncommitted or untracked files are not visible to remote Jules" >&2
  if upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)"; then
    ahead="$(git rev-list --count "${upstream}..HEAD")"
    ((ahead == 0)) || echo "warning: $ahead local commit(s) are not present on $upstream" >&2
  else
    echo "warning: the current branch has no upstream; confirm Jules can access the intended branch" >&2
  fi
fi
if [[ "$dry_run" == true ]]; then
  printf 'dry run: %q remote new --repo %q --parallel %q --session %q\n' "$jules_bin" "$repo" "$parallel" "$task"
  exit 0
fi
exec "$jules_bin" remote new --repo "$repo" --parallel "$parallel" --session "$task"
