# GitHub Actions — optional quality gate

> **Applies when `.ai-eng-kit` → `stack.ci` is `github-actions`.** Never install a workflow merely
> because this pack ships. `/init` records the user's choice; `/verify-setup ci` prepares setup
> only on request. Existing CI and repository settings win.

## Prepare a concrete workflow

1. Read `docs/kit/guides/checks.md` and resolve the complete closing plan, including all runtimes
   and required type/structure checks. Unknown coverage is `/init checks` first. Inspect existing
   `.github/workflows/` before proposing changes; extend the relevant job instead of adding a
   second suite. Give the quality job a unique, stable name.
2. Choose runners/runtime installs from the project: native Xcode needs macOS; a worker may need
   Python; a CLI need not use npm. Use the lockfile's installer and the recorded plan's roots.
   No production credentials or production-data access. Service tests use isolated test services
   or the approved fake adapters. Missing prerequisites are a named hand-off, not a skipped check.
3. **For an npm project only**, `assets/ci/quality.yml` in the `/verify-setup` skill is a concrete
   example. Copy it to `.github/workflows/quality.yml` only after reviewing the proposed diff.
   Its single `npm run check` is valid only when that is the actual aggregate and its confirmed
   coverage contains **every required stage in every runtime**. Otherwise replace that run step
   with the resolved sequential plan, preserving fail-fast behavior; do not append a covered
   build/test again. Adapt the runner, Node version, branch, timeout and extra-runtime setup.
   The example's checkout/setup-node SHAs were verified against their official tags on 2026-10-22;
   recheck compatibility/current versions at adoption, especially self-hosted runner requirements.
4. Keep `permissions: contents: read`, checkout credentials disabled, a bounded job timeout and
   cancellation of superseded runs. Use `pull_request` for untrusted PR code, never a privileged
   `pull_request_target` job executing it. Check out the PR's head SHA explicitly; for push/manual
   runs use that run's SHA. Record `git rev-parse HEAD` in logs so the tested commit is unambiguous.
5. Show the exact workflow diff and required repository settings; existing authorization for that
   exact setup counts. Validate syntax and the resolved plan locally without repeatedly running
   suites. Installing the file is not proof of a green hosted run or branch protection.

## Verify the candidate before release

At `/deploy`, identify the exact candidate SHA and required workflow/job names. Read its GitHub
checks/runs using the available connector/CLI, e.g. `gh run list --commit <sha>` and
`gh run view <run-id> --json headSha,event,status,conclusion,url`. Confirm the run and checkout log
refer to that SHA, completed successfully, and execute the full current closing plan. Green on
an older commit, a different event/workflow, a skipped/cancelled job or an unrelated check is no
evidence. If visibility is unavailable, name the exact run/job/SHA the user must confirm; do not
claim to have checked it. An unchanged failed run is a hand-off, not a poll/retry loop.

The verified CI result can satisfy those **same** pre-flight stages; do not run them locally again
merely to produce another green result. QA remains independent. A changed candidate needs new
evidence. A PR-head run proves that head, not a later merge/squash candidate: if integration changes
the release tree, verify the integrated candidate before pushing auto-deployed `main`. Use the
project's staging branch/manual workflow or merge-queue process; required checks must apply to
the actual release candidate. If no pre-release CI path exists, run the full closing plan locally
on the integrated candidate, and report the CI gap honestly. Never push just to discover whether
an auto-deployed release will pass.

## Enforcement is a separate repository setting

Recommend requiring the named quality check for the protected release branch through GitHub
branch protection/rulesets, including the up-to-date/merge-queue policy the project uses. Also
recommend review/CODEOWNERS for workflow/check definitions where a team wants it. Show the exact
setting and let the authorized owner apply/confirm it. Do not silently change GitHub settings.
Until verified, report **workflow present; enforcement not verified**. Even configured protection
may allow administrator/bypass paths; never describe a YAML file alone as a non-bypassable gate.

Sources checked 2026-10-22: [workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax),
[PR event semantics](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#pull_request),
[protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches),
[checkout](https://github.com/actions/checkout), [setup-node](https://github.com/actions/setup-node).
