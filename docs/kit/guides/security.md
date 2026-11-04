# Security controls — load by capability

This is shared guidance, not an always-imported rule file. Read the applicable sections before
designing, implementing or verifying affected code, including work outside a named skill.
Select per affected runtime from `.ai-eng-kit` → `platform`, `stack`, `layers`, `probe`, then the
feature's operations. Registry null means unknown; inspect the real entry points and ask through
`/init` where needed. A missing pack never waives a control.

| Capability in the affected runtime | Read controls |
| --- | --- |
| Any code, including local native/CLI apps | SEC-01, SEC-02, SEC-08 |
| Protected operations, shared/remote data or user accounts | SEC-03 |
| Real login, signup, reset, OTP, magic link or invite credential | SEC-04 |
| HTTP endpoints or browser/webview forms | SEC-05 |
| Browser-facing HTTP documents | SEC-06 |
| Model/LLM integration | SEC-07 and `docs/kit/guides/design.md` → Model integrations |

A local macOS/iOS/Android/Flutter utility needs no HTTP headers or web forms merely because the
kit ships their guides. A native app with accounts still needs SEC-03/04; a native app plus an
HTTP API layer needs SEC-05/06 for that API where applicable. Local OS unlock/biometrics use the
platform's protection; do not bolt web CAPTCHAs or per-IP throttles onto them. Capture applicability
and the reason in design/QA, not the always-loaded memory file.

## SEC-01 — Secrets and client exposure

Never read, create or edit real env/credential files, or recover them through another tool after
a denial. Document every new env-variable name in the example file, with a placeholder only. State the variable name and provider
location so the user enters the value privately; never ask them to paste it into the conversation.
Never commit keys, tokens or credentials or put them in logs. Check the framework's public-env
convention before naming a variable. Native binaries and client bundles cannot protect a service
secret; privileged provider calls belong behind a trusted service when one is required.

## SEC-02 — Validate at the trusted entry point

Validate external input against the project's schema/validation mechanism before acting on it.
For remote operations the server validates independently of client checks. For a local-only tool,
validate at its own file/IPC/command entry point; do not invent a server. Use parameterized database
operations and context-appropriate encoding, not a vague instruction to "sanitize everything".

## SEC-03 — Identity and data access

Verify authentication/authorization in the protected operation, not just its UI. Enforce ownership
at the data layer too: row-level policies, scoped queries or the store's access mechanism. Local
storage needs the OS/file protection appropriate to its sensitivity; a private local utility does
not require a hosted multi-user database. Explicit user approval covers changes to auth flows or
access rules.

## SEC-04 — Credential abuse

For remotely checked credentials, throttle login/signup/reset/magic-link/OTP/invite attempts from
the start. Provider limits are a floor: per-IP protection alone does not stop distributed attacks
or credential stuffing and covers no custom routes. Use per-account and per-source protection,
plus bot protection on public credential forms; use a native-compatible mechanism when no browser
form exists. Do not reveal account existence: consistent errors and comparable timing where it
matters. Read `docs/production/rate-limiting.md` and the applicable backend/framework pack for the
mechanism. Settings outside code become `[user]` tasks, or `[user go-live]` only when a production
URL is genuinely required. Missing protection on real remote credentials remains a High QA bug.

## SEC-05 — HTTP and sensitive URLs

Credential forms submit by POST, never native GET. Keep credentials, session IDs and PII out of
query strings, logs, history and referrers. Necessary protocol callback tokens (OAuth/code links)
must follow the provider's documented short-lived flow, with no extra disclosure or logging.
Use the framework's request/auth mechanism, parameterized queries and output encoding.

## SEC-06 — Browser HTTP headers

Read `docs/production/security-headers.md` and the framework/deploy pack. Configure clickjacking
protection (CSP frame-ancestors or X-Frame-Options), nosniff, a suitable Referrer-Policy and HTTPS/HSTS
with its subdomain/preload consequences assessed. Verify actual served responses: a host may
strip/override configuration. These are not requirements for a CLI/stdio/simulator runtime.

## SEC-07 — Model output

Model replies and tool arguments are external input: validate shape and permitted values, then
encode for the destination. A valid JSON schema does not make HTML, SQL or shell text safe. Never
let a generated instruction bypass the user's permissions or execute arbitrary operations.
Keep provider secrets and sensitive prompts out of client bundles/logs; define data sharing and
failure/cost limits in design. Ordinary tests use deterministic fake adapters, not paid live calls.

## SEC-08 — Verification and exceptions

Do not skip checks by changing discovery, assertions, severities, ignores, suppressions, baselines
or CI. A legitimate correction needs evidence, an exact proposed diff and explicit review (prior
approval for that exact correction counts). Report verification changes in the handoff. Claude's
Edit ask rules cover its built-in edits/writes; they are review gates, not OS isolation for arbitrary
subprocesses. Other agents have their own permission models.

Use these stable IDs in design decisions and QA findings. An exception records control ID, scope,
reason, approving user, compensating measure and review trigger in `docs/decisions.md` (feature-only:
`design.md`). An exception stays visible; it does not turn an unverified control into a pass or
override the skill's release/quality gates. Never renumber IDs when reorganizing this guide.

Sources checked 2026-10-22: [Claude permissions](https://code.claude.com/docs/en/permissions#read-and-edit),
[OWASP model output handling](https://genai.owasp.org/llmrisk/llm052025-improper-output-handling/).
