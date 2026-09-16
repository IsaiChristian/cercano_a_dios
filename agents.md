# Agent Roles & Delegation Policy

## Primary Goal

Optimize for:
1. Correctness
2. Minimal Codex quota consumption
3. Small, independently verifiable changes
4. Minimal duplicated context between agents

## Long-context reading — Luna max

Use GPT-5.6 Luna (`gpt-5.6-luna`) with `max` reasoning for long-context
reading, repository exploration, and synthesis of large documents or logs.
Return concise findings with file references, relevant contracts, constraints,
uncertainties, and acceptance criteria for the implementation worker.

Keep this role read-only. Do not have the implementation worker repeat broad
context collection; it should inspect the specific source needed to verify the
handoff and make the change.

## Implementation — Astra low

Use GPT-6 Astra (`gpt-6-astra`) with `low` reasoning for implementation.
“Light” means the supported `low` effort setting.

This default applies to all implementation work, including simple edits, tests,
business logic, architecture changes, debugging, and mechanical changes.
Keep work narrowly scoped and verify each change with the cheapest appropriate
checks. The coordinator may make small coordination edits directly.

Terra, Gemini Flash, and Jules are no longer automatic implementation routes.
Use a different model or service only when the user explicitly requests it.

## Routing and escalation

1. When substantial context must be read, assign that read-only work to Luna max.
2. Give Astra low the resulting concise handoff, relevant files, and acceptance
   criteria. For tasks with enough context already available, start directly
   with Astra low.
3. Implement and run the relevant verification.
4. Only after **two failed Astra low implementation attempts on the same task**
   may reasoning effort be increased. Record each attempt, its change or approach,
   and the concrete failure before escalating.
5. Increase effort only as needed, starting with the next suitable supported
   level, and carry forward the findings rather than restarting investigation.

Task size, long context, architectural impact, or uncertainty alone do not
permit increasing implementation effort before two failed low-effort attempts.
Missing permissions, unavailable tools, and unanswered requirements are blockers,
not failed implementation attempts; surface them to the coordinator.

## Review

Require focused Astra review when domain contracts or architecture change,
multiple features/layers are affected, a worker reports uncertainty, or tests
still fail after implementation. Review follows the same low-effort default
and escalation threshold. Otherwise automated verification is sufficient.

---

# Context Budget Policy

Minimize context duplication.

Workers receive only:
- task description,
- relevant files/interfaces,
- project conventions required for the task,
- acceptance criteria.

Do not provide workers the complete conversation history.

Prefer references to repository files over copying large amounts of source code.

Each worker must return:
- files changed,
- decisions made,
- unresolved issues,
- verification performed.

---

# Shared Findings, Coordination & Handoffs

Use the existing [`agent-comms/`](agent-comms/README.md) folder as the shared memory and coordination space for this project. Do not create a second `agentcomms` folder.

## Shared board across branches

- The [GitHub coordination board, issue #6](https://github.com/IsaiChristian/cercano_a_dios/issues/6), is the shared record of task ownership, dependencies, discoveries and handoffs across branches and remote sessions. Read its body and latest comments before starting work, changing scope or integrating a result.
- The coordinator maintains the issue body and task table. Workers append `CLAIM`, `UPDATE`, `HANDOFF` or `READY FOR REVIEW` comments using the issue template; do not overwrite another worker's update. Only mark work merged with a verified merge reference.
- Record your task, branch/session, base commit and exact write scope before edits. If another claim overlaps, wait for the coordinator to resolve ownership. Branch-local status files are not a cross-branch lock.
- Post useful findings with evidence and meaningful blockers, not routine polling updates. Keep detailed notes in `agent-comms/<task-id>.md` and link them at an accessible commit or PR; identify notes that are still local-only.
- Include the board URL and instruction to read/comment on it in every new delegated task prompt. Already-running agents do not receive this file or issue automatically; provide the link through an available follow-up channel or relay their updates as coordinator.
- If an agent cannot read or comment on GitHub, the coordinator supplies the current board context and posts the agent's structured update. Do not infer that saving a local note notifies another agent or dispatches a handoff.
- Task coordination comments on this board are part of the assigned workflow. They do not authorize unrelated messages, pushes, merges, extra tasks or PR creation. Follow the user's task scope and tool permissions.

## Before starting work

- Read [`RULES.md`](agent-comms/RULES.md), [`CURRENT_STATUS.md`](agent-comms/CURRENT_STATUS.md), and existing task notes relevant to your scope.
- Check the actual branch, commit, and working tree. Treat notes as context to verify, not proof that a change is present in your checkout.
- Claim your task and file ownership in `CURRENT_STATUS.md` before editing. Preserve other agents' entries and user-owned changes.
- For parallel work, use a separate `agent-comms/<task-id>.md` note per task. The coordinating agent maintains the shared status index; workers update their own notes to avoid competing edits. Honor a narrower task allowlist: if coordination files are excluded, return the note content to the coordinator instead.

## Record useful discoveries

- Add findings that will help another agent avoid repeated investigation: relevant entry points, established patterns, hidden dependencies, behavior that must be preserved, working verification commands, environment limitations, and failed approaches worth avoiding.
- Keep notes concise and actionable. Include the finding, supporting file or command, the commit or environment it applies to, and its consequence for future work.
- Separate verified facts from hypotheses. Record failed attempts with the observed result and why the approach was abandoned; do not repeat an unsuccessful approach without new evidence.
- Link to source files, tests, and existing documentation instead of copying large code blocks, logs, or conversation history. Correct or mark outdated findings when new evidence supersedes them.
- Store no credentials, private prayer content, recordings, or other sensitive data. Product documentation and implementation code remain in their normal locations.

## When a task is too difficult or blocked

- Follow the existing escalation policy. Hand off when the task exceeds your assigned scope or capability, when a contract or architecture decision is needed, or after two unsuccessful implementation attempts. Do not escalate solely because the task is large.
- Use [`HANDOFF_TEMPLATE.md`](agent-comms/HANDOFF_TEMPLATE.md) in your task note. Include the objective, acceptance criteria, owner and write scope, starting/current commit, files changed, completed work, exact attempts and results, verification, unresolved questions, and the first concrete next step.
- State the required decision or expertise and intended recipient. Use Luna max for additional long-context reading and Astra low for implementation; increase Astra effort only after two documented failed low-effort attempts on the same task. If a named worker is unavailable, notify the coordinator rather than silently selecting a replacement.
- Preserve useful partial work and identify whether it is tested and safe to continue. Do not discard another agent's changes, hide failures, or mark unfinished work complete.
- Notify the coordinator or receiving agent through the available communication channel and link the handoff note. A saved note alone does not dispatch another agent. If dispatch is unavailable, explicitly report that the handoff is awaiting assignment.
- Stop changes that depend on the unresolved decision; continue only independent work within your owned scope. Transfer file ownership explicitly before another agent resumes edits.

## At completion or transfer

- Update your task note with changed files, verification results, remaining risks, and useful discoveries. Report unrun checks honestly.
- Update the shared status, or send the update to its coordinator, with completion/blocker state, handoff link, next owner/action, and any branch or remote session reference.
- Distinguish local work, remote session output, and merged changes. Do not assume another agent can access uncommitted or unpushed files; communicate the missing context without pushing or pulling unless authorized.
- Release your ownership when work is complete or the handoff is accepted. Keep the status concise; retain reusable findings in the task notes.

---

# Verification Policy

Every implementation must pass the cheapest appropriate verification.

Local change:
    dart format
    dart analyze

Logic change:
    dart analyze
    relevant tests

Repository-wide change:
    dart analyze
    flutter test

Architecture-sensitive change:
    tests
    analyze
    Astra review

A successful automated verification does not automatically
require Astra review.
