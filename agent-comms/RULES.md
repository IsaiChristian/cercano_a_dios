# Collaboration Rules

These rules apply to every agent working in this repository.

## 1. Establish the baseline

- Read `CURRENT_STATUS.md`, then inspect `git status --short --branch` before editing.
- Treat existing uncommitted changes as user-owned. Do not reset, discard, or overwrite them.
- If the task requests a baseline commit, create it before making task changes and record its hash in the handoff.
- Keep later commits atomic and descriptive. Do not amend another agent's commit unless explicitly asked.

## 2. Claim scope before editing

- Write the task, owner, files or directories in scope, and the next action in `CURRENT_STATUS.md`.
- Avoid editing files another active agent owns. If scopes overlap, coordinate in the status file before proceeding.
- Prefer small, reviewable patches. Use `apply_patch` for source and documentation edits.
- Do not create parallel implementations of the same behavior just to avoid coordination.

## 3. Respect project and tool boundaries

- Read any relevant skill instructions completely before using that skill.
- Follow the repository's existing architecture and naming conventions unless the task explicitly changes them.
- Ask for elevated access only when a required command is blocked by a real permission boundary; state what access is needed and why.
- Never use destructive commands such as hard resets or broad recursive deletion without explicit authorization and a verified target.
- Do not place generated caches, build output, credentials, or machine-specific paths in coordination files.

## 4. State management and framework-first design

- BLoC is the default for application state, feature state, business logic, asynchronous workflows, and side effects. Prefer `Bloc` for event-driven flows and `Cubit` only for genuinely simple state transitions.
- Do not introduce `ChangeNotifier`, `ValueNotifier`, ad-hoc callback state, service-locator state, or new `Provider`-managed feature state. `setState` is reserved for small, private, ephemeral widget state; it must not replace a BLoC for shared or business state.
- `BlocProvider` and `RepositoryProvider` are the preferred wiring mechanisms for BLoCs and repositories. A plain `Provider` may be used only for a dependency that is not stateful and does not belong in a BLoC.
- Before adding a package, facade, adapter, helper, or custom framework layer, check whether Flutter or `flutter_bloc` already provides the capability. Prefer the Flutter SDK and its official generated tooling whenever they do.
- Never recreate a Flutter capability with a project-specific abstraction when an official solution exists. This includes localization, delegates, locale lookup, pluralization, navigation primitives, theming, accessibility semantics, and platform integration patterns.
- Do not reintroduce the removed translation facade, generic `t(key, params)` lookup, string maps, handwritten locale delegates, or another custom localization wrapper. Use ARB source files, Flutter's generated `AppLocalizations`, and `AppLocalizations.localizationsDelegates`.
- If a custom abstraction or a non-BLoC state mechanism is unavoidable, document the reason, scope, owner, and removal condition in `CURRENT_STATUS.md` and the handoff. “Convenience” alone is not sufficient justification.

## 5. Generated and source-of-truth files

- Edit the source inputs, then regenerate derived files with the project tool.
- Do not hand-edit generated files unless the generator is unavailable and the exception is documented.
- For localization, update the ARB source files, regenerate Flutter localization classes, and use generated getters or methods at call sites. Do not reintroduce a dynamic string-key facade.
- When a generated file changes, mention the generator command in the handoff.

## 6. Verify proportionally

- Run formatting, static analysis, and the narrowest relevant tests before broader tests.
- Report the exact commands and their outcomes; do not claim success from an unrun check.
- If a test hangs or fails outside the changed scope, isolate it, capture the last observable step, and distinguish that blocker from code failures.
- Re-check `git diff --check` and `git status` before handing work off.

## 7. Communicate useful state

Every handoff or status update should answer:

- What was requested?
- What changed, and where?
- What was verified?
- What remains or is blocked?
- What should the next agent do first?

Use `HANDOFF_TEMPLATE.md` for repeatable handoffs. Keep `CURRENT_STATUS.md` concise and current; it is not a transcript.

## 8. Close the loop

- Remove stale ownership claims when work is complete.
- Leave the working tree state and commit hashes explicit.
- If work is incomplete, leave a reproducible next step instead of an ambiguous note.
