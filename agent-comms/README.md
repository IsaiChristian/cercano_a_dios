# Agent Communication

This folder is the shared, project-local workspace for agents collaborating on Cercano a Dios.

## Coordination across branches

Use [GitHub issue #6 — Agent coordination board](https://github.com/IsaiChristian/cercano_a_dios/issues/6) for shared ownership, task status, dependencies, findings and handoffs. Read the body **and latest comments** before starting or integrating work. Files in this folder belong to their branch and may be stale or unavailable to other agents.

The coordinator edits the board's task table. Workers append structured comments using the issue template. Claim exact file scope, report meaningful discoveries with evidence, and request explicit ownership transfer when handing off. A completed remote session is not the same as a merged change. The board is manually maintained at dispatch, update and integration boundaries; it does not automatically monitor Jules.

Keep detailed notes in `agent-comms/<task-id>.md`, based on `HANDOFF_TEMPLATE.md`. Link accessible commits or PRs from board comments. Do not make parallel workers overwrite `CURRENT_STATUS.md`; its coordinating agent maintains that local index. If a worker lacks GitHub access or its write scope excludes notes, return the structured update for the coordinator to post.

To read the board with the GitHub CLI:

```bash
gh issue view 6 --repo IsaiChristian/cercano_a_dios --comments
```

To post a prepared task update, write it to a text file and pass its path:

```bash
gh issue comment 6 --repo IsaiChristian/cercano_a_dios --body-file /path/to/task-update.md
```

Include the board link and these expectations in every new remote task prompt. Existing sessions need the link supplied through their follow-up channel; repository edits alone do not update their instructions.

## Local notes

Start with [RULES.md](RULES.md). Use [HANDOFF_TEMPLATE.md](HANDOFF_TEMPLATE.md) when transferring work, and keep [CURRENT_STATUS.md](CURRENT_STATUS.md) accurate while a task is active.

The folder is for coordination only. Source code, tests, and product documentation remain in their normal project locations. Never put passwords, tokens, private keys, or other secrets here.

## Normal workflow

1. Read `RULES.md` and `CURRENT_STATUS.md` before changing files.
2. Record ownership and the intended scope in `CURRENT_STATUS.md`.
3. Keep the handoff short, concrete, and evidence-based.
4. Update the status with changed files, verification, blockers, and the next action.
5. Mark the handoff complete when the work is finished, or clearly record why it is blocked.
