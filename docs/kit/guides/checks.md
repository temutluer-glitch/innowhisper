# Closing checks

Read for the final `/build` check and `/deploy` pre-flight, once for the whole feature or launch
set. Full tests still belong only to the main build agent per completed level and at the end,
and to the QA owner once before its lanes. Tasks, fixes, red proofs and QA lanes run single files.
E2E keeps its own workflow. No aggregate after every edit; no cross-phase result cache.

## Confirmed coverage

`/init checks` records actual commands from the project's scripts/build/CI files, confirmed by
the user. A command name alone proves no coverage. Compare the actual definition with the recorded
coverage before using it; a changed definition needs `/init checks`, not stale metadata. In `.ai-eng-kit`:

- `commands.check` is optional. Without it, use the individual commands.
- `checkLayers` names the additional runtimes included by the primary aggregate; `[]` means
  primary only, `null` means unknown.
- `checkCoverage` records the **stages** that aggregate covers in each runtime:

```json
{
  "checkLayers": ["worker"],
  "checkCoverage": {
    "primary": ["lint", "typecheck"],
    "layers": { "worker": ["test"] }
  }
}
```

This is a partial aggregate. Its primary tests/build and the worker's other required stages
still run, exactly once each. Do not follow it with another aggregate that repeats covered stages.
Every covered layer must appear in both scope and coverage; unknown names or missing lists need
`/init checks`, not a guess. Existing aggregates need their stage coverage confirmed once after
upgrading; update never rewrites their definitions.
Layer names are unique, non-empty and cannot use the reserved primary-runtime name `primary`.

A layer may have its own `commands.check` and `checkCoverage` (a stage array, e.g.
`["lint", "test", "build"]`), executed from its `root`. These cover that runtime only.
When a root aggregate covers any part of a layer, append that layer's missing individual stages
instead of invoking its overlapping aggregate.

Stages are `lint`, `typecheck`, `structure`, `test`, `build`, in that order. Keep the individual
`commands` accurate, especially `test` for QA. Record `commands.typecheck` and `commands.structure`
when separately required by that runtime; do not create Next.js tooling in another stack. For a
stage absent by design, `false` needs a reason in the memory file's **How This Project Runs**.
Tests cannot be false. Missing/null lint/test/build commands are unknown, not permission to skip.
Unrecorded typecheck/structure stages are optional; an explicitly null one is unresolved.
All five stages apply to the current Next.js scaffold.

### A runtime without a linter

Installation detects `lint` only from `package.json` scripts, so a Python, PHP, Swift, Kotlin,
Flutter, Go or Rust runtime usually arrives with `null`. Before a `null` becomes `false`, look for
what the detection cannot see: `[tool.ruff]` or `[tool.pylint]` in `pyproject.toml`, `phpstan.neon`,
`.swiftlint.yml`, `analysis_options.yaml`, ktlint/detekt in the Gradle build, `.golangci.yml`, a
lint step in CI. Found → propose that command for confirmation.

None found → recommend the usual one for that language **once**, with one sentence on what it
catches (unused code, likely bugs, inconsistent style, before a reviewer or user does):

| Language | Built in — propose as the command | Needs installing — hand off |
|---|---|---|
| Python | — | `ruff check .` |
| PHP | — | PHPStan (`vendor/bin/phpstan analyse`) |
| Swift | — | SwiftLint (`swiftlint`) |
| Kotlin / Android | Android Lint (`./gradlew lint`) | ktlint or detekt |
| Dart / Flutter | `dart analyze` / `flutter analyze` | — |
| Go | `go vet ./...` | golangci-lint |
| Rust | `cargo clippy` | — |

A built-in command needs nothing installed: record it once the user confirms. Anything that needs
installing is a dependency decision — **never install or configure it in `mode: existing`**; name
the tool and its setup page, and the user adds it. If they decline, record `false` with the reason
and the date in **How This Project Runs**; a recorded reason is answered and is not raised again.

## Resolve and run

Run `node docs/kit/checks/plan.cjs` from the project root. It only reads the registry and prints
`steps` (root, command, covered stages/runtimes); it never executes commands or edits files.
An error produces no executable partial plan. Resolve it with `/init checks` before running.
Without Node, resolve the same rules manually and show the plan; Node is not a new dependency for
a native project. Read runtime packs for any additional checks the project's owner requires.

Execute the plan sequentially; stop at the first failure. Record command/root/result. A passing
aggregate is evidence only for its confirmed stages: never repeat those tests/builds or layers.
If a stage fails, fix the cause using that stage or affected test files. Group related repairs,
then repeat the closing plan once after the group changed code. An unchanged failure is a hand-off,
not an instruction to keep rerunning. Never narrow the plan to get green.

QA retains its own independent `commands.test` run once per runtime, diff-scoped re-verification
and Deferred stop condition. Do not substitute this aggregate into QA's pre-fan-out or its lanes.
Deploy uses the same complete plan before release mutations; a later change to the release tree
invalidates that evidence. Where CI is configured, `docs/stacks/ci-github-actions.md` describes how
to verify the exact candidate commit and avoid repeating checks already proved there.

## Changes to verification

A failed check calls for a code fix. If the check is wrong, show the failure and the exact proposed
change with its reason, then obtain review; existing authorization for that exact change suffices.
Never add/expand suppression lists, baselines, ignores, skipped tests, relaxed assertions or rule
severities merely to get green. Legitimate corrections need explicit review and remain visible in
the handoff. This includes coverage metadata, test discovery, CI and what an aggregate invokes.
New regression tests and dependencies remain ordinary work; not every test edit needs a question.
