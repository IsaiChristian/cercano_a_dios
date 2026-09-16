# Agent Roles & Delegation Policy

## Primary Goal

Optimize for:
1. Correctness
2. Minimal Codex quota consumption
3. Small, independently verifiable changes
4. Minimal duplicated context between agents

Use the cheapest capable worker for each task.
Escalate upward only when complexity or uncertainty requires it.

---

## Tier 0 — Root Orchestrator: Astra (GPT-6 Astra)

### Role
Architect, escalation target, and final reviewer for high-impact changes.

### Use Astra for
- Architecture and cross-feature design decisions.
- Public/domain interface contracts.
- Ambiguous requirements.
- Difficult debugging after lower-tier attempts fail.
- Security-sensitive or data-integrity-sensitive changes.
- Reviewing changes that affect multiple architectural layers.
- Resolving conflicts between worker implementations.

### Do NOT use Astra for
- Boilerplate.
- DTO generation.
- Simple widgets.
- Routine tests.
- Formatting.
- Mechanical refactors.
- Dependency bumps.
- Straightforward implementations with established patterns.

### Verification
Astra does not need to review every generated line.

Require Astra review when:
- Domain contracts changed.
- Architecture changed.
- Multiple features/layers are affected.
- A worker reports uncertainty.
- Tests fail after implementation.

Otherwise automated verification is sufficient.

---

## Tier 1 — Domain Worker: Terra (GPT-5.6 Terra)

### Role
Primary implementation model for non-trivial application logic.

### Use Terra for
- Business logic.
- Use cases.
- Repository implementations.
- Caching strategies.
- State machines.
- BLoC/Cubit/Riverpod controllers.
- API/domain mapping involving business rules.
- Medium-complexity debugging.

### Escalation

Escalate to Astra only when:
- Architectural decisions are required.
- Existing contracts appear incorrect.
- Requirements are ambiguous.
- Two implementation attempts fail.
- The change crosses multiple bounded contexts/features.

Do not escalate merely for code review.

---

## Tier 2 — Fast Worker: Gemini Flash

### Role
Cheap, high-throughput implementation worker.

### Use Flash for
- DTOs.
- JSON serialization.
- `fromJson` / `toJson`.
- `copyWith`.
- Entity/model mappers.
- Dart sealed event/state declarations.
- Simple immutable classes.
- Repetitive Flutter widgets.
- UI scaffolding.
- Form fields.
- Straightforward extensions/helpers.
- Test fixtures and mocks.
- Documentation.
- Mechanical code transformations.

### Constraints

Flash must receive narrowly scoped tasks.

Provide:
- Relevant interfaces.
- Existing project conventions.
- Target file(s).
- Expected output.
- Constraints.

Avoid sending the entire repository context.

Flash must not independently change:
- Domain contracts.
- Architecture.
- Public APIs.
- Dependency strategy.

If such a change appears necessary, return the problem to the orchestrator.

---

## Tier 3 — Async Worker: Google Jules

### Role
Long-running autonomous repository worker.

### Use Jules when work is:
- Large.
- Mechanical.
- Test-heavy.
- Repository-wide.
- Independent from current interactive development.
- Suitable for execution on an isolated branch.

Examples:
- Generate test suites.
- Increase coverage.
- Repository-wide migrations.
- Dependency upgrades.
- Fix CI failures.
- Large mechanical refactors.
- Analyze and fix lint violations.
- Update deprecated Flutter APIs.

### Workflow

1. Create an isolated Jules task.
2. Jules works on its own branch.
3. Jules runs:

   flutter pub get
   dart format .
   dart analyze
   flutter test

4. Jules produces a commit/PR.
5. CI validates the result.
6. Astra reviews only when the change meets Astra-review criteria.

---

# Routing Algorithm

Before implementing a task, classify it.

## Step 1 — Can Flash do it safely?

If the task is:
- deterministic,
- repetitive,
- local,
- pattern-based,
- and does not require architectural reasoning,

delegate to Gemini Flash.

Otherwise continue.

## Step 2 — Is it long-running and isolated?

If the task:
- touches many files,
- requires extensive tests,
- is mechanical,
- or can run independently,

delegate to Jules.

Otherwise continue.

## Step 3 — Does it require application reasoning?

Use Terra.

Examples:
- business logic,
- state management,
- repositories,
- non-trivial feature implementation.

## Step 4 — Does it require architectural reasoning?

Use Astra only if:
- contracts must change,
- architecture must change,
- requirements are ambiguous,
- lower-tier agents cannot resolve the problem,
- or the change has high architectural impact.

---

# Escalation Policy

Flash
  ↓ if insufficient
Terra
  ↓ if insufficient
Astra

Jules
  ↓ if implementation/logic issue
Terra
  ↓ if architectural issue
Astra

Never escalate directly because a task is large.
Large but mechanical work belongs to Jules.

Never use Astra simply because it is available.

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
- State the required decision or expertise and the intended recipient: Flash to Terra; Terra to Astra for architectural issues; Jules to Terra for implementation issues or Astra for architectural issues. If a named worker is unavailable, notify the coordinator rather than silently choosing an expensive replacement.
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
