# General Project Rules

## Working Language
Use the language in the canonical memory file → Key Conventions and `.ai-eng-kit` → `language`
for replies and generated documents, including headings and ACs. Code, paths, commits and
kit-authored files stay English. Explicit user overrides win; never bulk-translate old documents.
If the language is unrecorded, ask once.

## Start and route
Read `.ai-eng-kit` and `features/INDEX.md`. An unfilled PRD/empty feature map needs `/init` before
implementation (`mode: existing`: `/map` then `/init`). Use `/write-spec` for independent new
capabilities, `/refine` for an existing feature's changes/extensions, `/build` then scoped `/qa`
for bugs against its contract. Behavior-neutral fixes may be direct. Follow skill checkpoints;
handoffs to the next phase need the user's confirmation, including authorization already given.

## Layers
Existing code/tooling wins. Read the owning layer's `packs` before stack packs; use its `root`,
`commands` and `probe`. Otherwise use the primary registry values. Null means unknown: propose
from files, then `/init` confirms; never invent a stack or skip an unknown check. All `PROJ-`
examples mean `.ai-eng-kit` → `featurePrefix` (default `PROJ`). Stay on the user's feature branch;
only `/deploy` merges/removes branches, with approval.

## Contracts and tracking
Keep AC → Task → Test intact; `spec.md` is read-only during `/build`. INDEX is the sole status
record: change only the Status cell; a new row gets name, one sentence and link. Notes/decisions
belong in `design.md`, QA findings in `qa-report.md`, internal work in `docs/tech-debt.md`.
Read files before editing, write actual tracking updates, then re-read to verify them.

## Test Runs
Full suites: build's main agent once per completed level and at closing; QA's owner once per
runtime before lanes. Tasks, fixes, lanes and red proofs run single files. Read
`docs/kit/guides/checks.md` only at build/deploy closing; an aggregate is never an inner-loop test.
QA verification uses a fresh context; its own skill defines re-verification and Deferred bugs.
