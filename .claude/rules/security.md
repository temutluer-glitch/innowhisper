# Security Rules

- **SEC-01 Secrets:** never read/write real env or credential files, expose keys in code/logs,
  commit them, or bypass a denial. Edit only dummy examples; tell the user where to enter real values.
- **SEC-02 Trust:** validate external input at its trusted entry point; model output is untrusted.
- **SEC-03 Access:** enforce identity and ownership where protected operations/data are accessed.
- **SEC-08 Verification:** never weaken checks, suppressions or baselines to reach green; show a
  legitimate check change for review. Auth/access changes require explicit user approval; existing
  approval for that exact change suffices. Record exceptions, never silently waive a control.

Before designing, building, testing or releasing affected code, select the applicable sections in
`docs/kit/guides/security.md` using the registry's platform/stack, **each affected layer** and the
actual feature. Load auth guidance whenever real credentials are checked, including native apps;
HTTP/browser guidance only for the runtime that serves them. Unknown is not absent; clarify it.
A missing stack pack changes the mechanism, never the security requirement.
