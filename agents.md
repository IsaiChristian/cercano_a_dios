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