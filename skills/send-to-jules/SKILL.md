---
name: send-to-jules
description: Delegate isolated, long-running, or repository-wide coding work to Google Jules and inspect or pull its remote sessions. Use when the user asks to send, assign, delegate, monitor, or retrieve a task from Jules. Do not use for local Codex subagents or ordinary interactive edits.
---

# Send to Google Jules

Use Google's official `jules` CLI to delegate repository work to a remote Jules session.

## Authorization boundary

Creating a Jules session sends repository context and the task prompt to an external service. Create a session only when the user explicitly asks to send, assign, delegate, or start work in Jules. Requests to draft a Jules prompt, estimate suitability, or explain the workflow do not authorize session creation.

Do not push commits, connect repositories, pull changes, or create pull requests unless the user requested that action. Never print, store, or commit credentials.

## Before delegation

1. Confirm `jules` is installed with `command -v jules`.
2. Confirm the working directory belongs to the intended Git repository and inspect its `origin`, current branch, worktree status, and upstream divergence.
3. Treat uncommitted, untracked, and unpushed work as unavailable to Jules. Tell the user when this could materially change the task; do not push it automatically.
4. Ensure the task is suitable for remote, asynchronous work and can be verified independently. Keep interactive, ambiguous, architecture-sensitive, or secret-bearing work local unless the user specifically directs otherwise.
5. Build a self-contained prompt containing the objective, relevant paths or interfaces, constraints, acceptance criteria, and verification commands. Refer to repository files instead of pasting large source files. Require Jules to report files changed, decisions, unresolved issues, and verification performed.

If authentication is missing, ask the user to run `jules login`. If the repository is not available to Jules, direct the user to connect its GitHub repository in Jules. These are user-controlled account actions.

## Create the task

Run the bundled wrapper from the target repository:

```bash
.agents/skills/send-to-jules/scripts/send_task.sh --repo . -- "TASK PROMPT"
```

The live command needs network access and access to the user's Jules authentication cache. If the execution sandbox blocks either one, request approval to rerun the same command with those permissions; do not copy credentials into the repository or bypass the sandbox.

Use `--dry-run` to validate and display the command without creating a remote session. Use `--parallel 2` through `--parallel 5` only when the user explicitly requests multiple independent attempts and accepts the additional Jules usage.

Return the session identifier or URL emitted by Jules. State any warning about local-only changes.

## Follow-up operations

- List sessions: `jules remote list --session`
- List connected repositories: `jules remote list --repo`
- Pull a completed result only when requested: `jules remote pull --session SESSION_ID`

Before pulling, inspect the current worktree and avoid overwriting or mixing with unrelated local changes. After pulling, review the diff and run the cheapest relevant project verification. Do not treat a completed Jules session as verified until local checks pass.

The CLI is documented at <https://jules.google/docs/cli/reference>. The Jules REST API is alpha; prefer the CLI unless API automation is specifically requested.
