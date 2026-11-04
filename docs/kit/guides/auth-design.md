# Designing remote account protection

Read only when the affected feature checks real remote credentials, on web or native platforms.
Local OS unlock/biometrics follows the platform control; it needs no web CAPTCHA or IP throttle.
For native account forms use a supported bot-protection mechanism instead of assuming a browser.
See SEC-03/04 in `docs/kit/guides/security.md`.

## Design Brute-Force Protection into Auth Features
If the feature checks a credential — login, signup, password reset, magic link, OTP, or a custom API route that verifies anything — the design must say **how** attempts are limited, with numbers. The spec states the behavior; you pick the mechanism and write it into `design.md` like any other decision. Never leave this to `/build`: unstated, it gets skipped, and a login that silently accepts unlimited guesses looks exactly like a working one.

**Find out what the platform already gives you, and say so instead of rebuilding it.** Most auth providers throttle their own endpoints; `docs/stacks/backend-<value>.md` records what this project's does, down to which limits are customizable and where. No pack for this backend → ask the user what their auth layer already enforces. Designing a throttle on top of one that exists is waste; assuming one exists when it doesn't is the expensive direction.

**What a platform limit does not cover** — and therefore what your design has to decide, in every stack:
- **A patient or distributed attack on one account.** Per-IP limits don't stop an attacker rotating IPs, and they don't stop credential stuffing (one common password against many accounts).
- **Anything you wrote yourself.** A custom login route, a server action checking an invite code or a password-protected share link gets no platform limit at all — it needs an app-level throttle keyed per IP **and** per account (`docs/production/rate-limiting.md` for when and how much, the framework pack for the wiring).

**Decide and record these, with values:**
- **CAPTCHA** on sign-in / sign-up / password-reset forms — the strongest available lever against automated guessing, and worth recommending for any public signup. Whether the auth provider offers one built in, or it has to be added, is in the backend pack.
- **The throttle values** the spec's ACs promised (e.g. 5 failed attempts per account per 15 minutes → locked for 15 minutes), and **where** they are enforced.
- **Password policy** — minimum length (≥ 8, longer is better), required character classes, and **leaked-password protection** (a check against known-breached passwords). Whether the provider has it built in, and at what price, is in the backend pack — name the cost so the user decides rather than discovering it later.
- **No account enumeration** — the same message for "unknown email" and "wrong password", and the same response time where it matters.
- **MFA** if the product holds anything worth stealing — name it as an option with its cost, don't silently skip it.

**Decide — never ask the user how to configure it — and split *built* from *configured*.** You choose the values and the mechanism; the user approves the design, not a questionnaire. Then sort every measure into one of two bins:

- **Built** — app code: the throttle on a custom route, the identical error messages, the CAPTCHA widget in the form. Normal tasks for `/build`.
- **Configured by the user** — settings that live in a provider's dashboard and that no code can make (Supabase's *Authentication → Rate Limits* and *Attack Protection*, a host's WAF rule, a mail provider's sending limit). These go into `design.md` → **Settings the user makes**: the exact path, the value you propose, why, and the AC they serve. `/tasks` turns each into a `[user]` task, `/build` hands it over instead of building it, `/deploy` refuses to ship while one is unticked. **Mark each row `now` or `go-live`.** `now`: the test environment can already hold it (a rate limit, a CAPTCHA), so it is made before `/qa`. `go-live`: it needs the production URL or the host itself — a payment webhook endpoint and its signing secret, an OAuth redirect URI, an allowed origin, a DNS record — so nobody can make it before `/deploy` Step 2. A go-live row never blocks `/qa` or Approved: the feature is verified against its test-environment twin (a CLI forwarding test events to the local endpoint, a test secret in the example env file), and name that twin in the design so `/build` and `/qa` know what to use. Getting this wrong is a feature that can never be Approved, because the only thing keeping it out is a step that needs the deploy it is blocking. The backend pack (`docs/stacks/backend-<value>.md`) lists which settings exist and, where the provider can push them from a config file, how to make the setting a built task after all.

Log the choice in **Technical Decisions** with its trade-off (e.g. "CAPTCHA on signup — small friction for real users, removes the entire automated-signup class"). If the user declines a measure, that is their call: record it as a decision with the risk stated, don't quietly drop it.

