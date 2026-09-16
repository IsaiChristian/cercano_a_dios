# DELEGATION-POLICY

Status: complete locally, not committed or pushed; ownership released.
Owner: root coordinator. Base: `3aa07c7` on `main`.

User requested Luna max for long-context reading, Astra light for implementation,
and increased effort only after two failed light attempts. Light maps to `low`.

Changed `agents.md` to replace automatic Flash/Terra/Jules routing with Luna max
read-only context gathering and Astra low implementation. Documented the two-failure
threshold, concise handoffs, and treatment of external blockers. Updated local status.
`agent-comms/RULES.md` was inspected and needs no change.

Verification: routing references inspected and `git diff --check` passed.
Documentation only; application tests were not needed.

The prior recording fix remains pending. Its Terra worker was interrupted before
source edits. Resume implementation with Astra low; the coordinator has already
read the relevant AppBloc, SessionBloc, session tests, and lifecycle callers.
The defect is in the moved `lib/src/` files, not the old `lib/ui/` paths.
Check the shared board before resuming, preserve the boolean API, distinguish
committed persistence from refresh errors, and test audio cleanup during close.
