---
name: send-to-jules
description: Delegate isolated, long-running, or repository-wide coding work to Google Jules and inspect or pull its remote sessions. Use when the user asks to send, assign, delegate, monitor, or retrieve a task from Jules. Do not use for local Codex subagents or ordinary interactive edits.
---

# Send to Google Jules

Use Google's official `jules` CLI to delegate repository work to a remote Jules session.

Creating a session sends repository context and the prompt to an external service. Do so only when the user explicitly asks to send, assign, delegate, or start work in Jules. Do not push commits, connect repositories, pull changes, or create pull requests unless requested. Never print or store credentials.

Before delegation, check `command -v jules`, the intended Git repository and `origin`, current branch, worktree status, and upstream divergence. Uncommitted, untracked, and unpushed work is unavailable to remote Jules; warn the user and never push automatically. Ensure the task is self-contained with objective, relevant paths, constraints, acceptance criteria, and verification commands. Ask Jules to report files changed, decisions, unresolved issues, and verification performed.

If authentication is missing, ask the user to run `jules login`. If the repository is unavailable, direct them to connect it in Jules.

## Create a task

```bash
.agents/skills/send-to-jules/scripts/send_task.sh --repo . -- "TASK PROMPT"
```

Use `--dry-run` to inspect the command without creating a session. Use `--parallel 2` through `--parallel 5` only when explicitly requested. The live command needs network access and the user's Jules authentication cache; request approval if the sandbox blocks either one.

## Follow-up

- List sessions: `jules remote list --session`
- List connected repositories: `jules remote list --repo`
- Pull a completed result only when requested: `jules remote pull --session SESSION_ID`

Before pulling, inspect the worktree and avoid mixing unrelated changes. Review the diff and run relevant checks afterward.

CLI reference: <https://jules.google/docs/cli/reference>
