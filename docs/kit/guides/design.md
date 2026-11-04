# Design guidance — read the relevant sections

Use while creating/revising a PRD, spec or technical design. Scale detail to decisions the feature
actually needs; reuse the project's conventions. These records live outside always-loaded memory.

## Operating conditions and quality

`/init` separates **constraints** (confirmed budget, platform, law, deadlines) from **assumptions**
(expected load, growth, connectivity, availability). For assumptions record source/owner and when
to revisit them. Capture ranges when precision is unknown: concurrent users/jobs, records/files
and size/growth, acceptable downtime/data loss, offline needs and external-service limits. A local
single-user tool may need only file size and offline behavior. Do not invent enterprise targets.
For an existing product, propose from its map/measurements; unknown targets stay open.

`/write-spec` turns a material quality goal into an ordinary AC/EC with stable ID: **stimulus,
environment/load, observable response, measurable bound and measurement method**. For example,
an operation over an agreed data volume completes within a bound under a named device/network
condition. A bare "fast", "secure" or "<200ms" without conditions is not testable. Confirm the
bound with the user; do not invent an SLA. Put the requirement once in the AC/EC; optional
Technical Requirements link it, rather than creating a parallel quality-ID system.

`/architecture` maps each such AC to its mechanism, operating assumptions, failure behavior and
planned evidence. `/tasks` includes the implementation/verification work with the same AC-ID.
`/qa` reports the actual measurement, environment/load and result against that ID, or NOT VERIFIED
with the missing prerequisite. Unit tests do not prove a latency/load/availability promise.
Use a targeted check appropriate to the promise; do not add a full benchmark/toolchain by default
or repeat whole suites in an inner loop.

## Product vocabulary

When a domain term is ambiguous, or several features use conflicting names for one thing, ask
the user to settle its meaning. Read/update `docs/glossary.md` if it exists; otherwise create it
only once there is a real term to record. Each entry gives term, meaning, relevant distinction
and accepted synonyms. Reuse the confirmed terms in specs, designs, code and messages. Never
rename an established concept merely to fit the kit. No generic prefilled glossary and no import
of it from the memory file; load only the terms needed for the feature.

## Project-wide decisions

Feature-only choices stay in `design.md` → Technical Decisions, with rationale, alternatives and
trade-offs. For a decision governing several features/runtimes, use the project's existing ADR
convention or create `docs/decisions.md` at its first real entry. Use stable sequential IDs
(`ADR-001`, ...), and record context, decision, alternatives/rejection reasons, consequences,
date, scope/owning features and status (`Proposed`, `Accepted`, `Superseded`). A superseded entry
links its replacement; retain its original reasoning. Feature designs link the ID, not duplicate
the body. Read relevant accepted decisions before proposing a conflicting design.

Call out **load-bearing decisions**: hard-to-reverse data/ownership changes, trust/security models,
external provider lock-in, costly migrations or infrastructure commitments. State the impact,
reversal cost, uncertainty and smallest way to test the assumption. Offer a developer review
when specialist uncertainty warrants it; the user decides whether to obtain it, accept the
documented trade-off or change direction. No compulsory expert review for every feature.
An accepted design and existing authorization count; never manufacture a second approval loop.
If a required fact remains unknown, record the gap and continue independent work, without
declaring the dependent design/build/release gate satisfied.

## Errors and recovery

Define errors at each meaningful interface, using existing project types/conventions:

| Kind | Propagation and handling |
| --- | --- |
| Expected domain/validation rejection | Typed result/value with stable code and safe user message; callers handle it explicitly. No generic exception for a normal rejected operation. |
| Authentication/authorization denial | Fail closed; reveal no secret/account details; use the auth convention and SEC-03/04. |
| External/temporary failure (network, timeout, quota) | Translate provider details at the adapter; define timeout, cancellation, bounded retry only when safe/idempotent, and user recovery. |
| Unexpected defect | Throw/propagate to the runtime's error boundary/top-level handler; show a safe fallback and record one useful diagnostic with correlation context. |

Keep validation/domain logic independent of HTTP/UI response types. Translate at the entry point,
never return raw provider/DB stack traces. Log once at the responsible handler without credentials,
PII or full prompts; preserve the cause for diagnostics without duplicating logs at every layer.
Never swallow a failure or silently return a success-shaped empty value. Tests cover observable
error/recovery behavior at the interface. Do not create a universal error framework for one function.

## Model integrations

When a feature calls a model, define a small use-case interface with validated input and explicit
success/failure output. Keep provider SDK, credentials, model/version parameters and mapping inside
an adapter. Specify timeout/cancellation, bounded retries, token/cost limits, rate-limit handling,
data sent to the provider and what may be logged. Use the existing project's integration seam;
do not build a generic multi-provider platform without a real need.

Treat model text, structured replies and tool arguments as external input (SEC-07): validate shape,
permitted values and semantics, then encode at its destination. Schema-valid text is not safe HTML,
SQL or shell. Privileged operations still need authorization and allowlisted arguments.

Ordinary tests inject a deterministic fake adapter: success, malformed/unsafe reply, refusal,
timeout and provider failure. No paid/network model call in a unit suite. A deliberately requested
live integration/evaluation is separate, with its owner/budget and evidence recorded; a fake does
not prove provider quality. Keep the interface testable without a key or a live service.
