# Gate C Activation Package

## Status

**Gate C is PENDING.** This package is an activation candidate only.
It authorizes nothing by itself.

A consolidated run may be dispatched only when **all** of the following hold:

1. A fresh, full Codex review ACCEPTs the **exact commit SHA** of this package
   (see "Codex review" below). Any commit after that SHA voids the review.
2. The founder gives explicit Gate C approval **naming that exact SHA**,
   the account method (Option A, below), and the single run.
3. The pending run's SHA is verified to equal the Codex-ACCEPTED SHA before
   the reviewer approves that run in the environment gate.

If any condition fails, the run is denied and this package is not activated.

## What this package contains

| File | Contents |
|---|---|
| `.github/workflows/staging-http-checks.yml` | The consolidated harness: T00 OIDC self-check, T01–T10 (including T08b count-function call), Summary, Cleanup. `workflow_dispatch` only. Job permissions `contents: read` + `id-token: write` only. Environment `staging-http-checks` only. |
| `docs/count-function-t08b.sql` | The T08b count-function body, **design only, for Codex review**. It is NOT applied by this package. Creation belongs to Gate C activation, on the staging database only. |
| `docs/activation.md` (this file) | Secret inventory/lifecycle, activation order, rollback plan, limitations, disclosure inventory. |
| `README.md` | Repository statement (staging-only, no credentials, no production identifiers). Updated to point at this activation document. |

No other workflow in this repository is part of the activation package.
The `oidc-check-*` enforcement workflows are separate, secret-free
pre-checks; they are not the consolidated harness and must not be confused
with it.

## Target and non-targets

- **Target:** the staging Preview deployment only, at the canonical Preview
  origin asserted exactly by T00:
  `https://family-wealth-os-git-6df994-andres-felipe-garzon-diazs-projects.vercel.app`
- **Never targeted:** Production, any production domain/host/database, any
  real user data, any real bank credential/record, any payment/trade.
- **App under test:** Family Wealth OS PR #6 head `edd0a7a` (secure auth),
  as served by the staging Preview deployment. This package does not merge
  PR #6, does not deploy anything, and does not change the app.

## Secret inventory and lifecycle

No secret value appears in this repository, in any commit, log, or
ChatGPT message. Secrets exist only as **GitHub environment secrets** in
the `staging-http-checks` environment of this public repository, and only
during the Gate C activation window, in this order:

| Secret name | Purpose | Created | Deleted |
|---|---|---|---|
| `STAGING_USER_A_EMAIL` | Option A pre-confirmed synthetic staging account A (address only) | At activation, after Codex ACCEPT + founder Gate C approval | Immediately after the single run, pass or fail |
| `STAGING_USER_A_PASSWORD` | Temporary password for account A | At activation, after Codex ACCEPT + founder Gate C approval | Immediately after the single run, pass or fail |
| `STAGING_USER_B_EMAIL` | Option A pre-confirmed synthetic staging account B (address only) | At activation, after Codex ACCEPT + founder Gate C approval | Immediately after the single run, pass or fail |
| `STAGING_USER_B_PASSWORD` | Temporary password for account B | At activation, after Codex ACCEPT + founder Gate C approval | Immediately after the single run, pass or fail |
| `STAGING_COUNT_DATABASE_URL` | Count-function database URL for the harness role (EXECUTE on `fwos_harness_t08b_counts` only; NO SELECT on `fwos_state`) | At activation, after Codex ACCEPT + founder Gate C approval, after the read-only/count-role negative tests pass | Immediately after the single run, pass or fail |

Rules:

- Secrets are **environment secrets only**, never repository secrets, never
  committed, never printed, never pasted into ChatGPT, never put in a URL.
- The OIDC token is minted fresh in-job by T00, marked secret, never
  printed or logged, and never passed as a URL query parameter. It IS
  stored runner-locally for the duration of the single job only
  (exported via `core.exportVariable`, masked in logs); the
  runner-managed environment file holding it is outside the workflow
  Cleanup deletion list and is discarded with the ephemeral runner.
  It is never committed, copied, or sent anywhere else.
- The invitation code is runner-local only (T08) and deleted in the
  always-run Cleanup step.
- Cookie values, session tokens, response bodies, raw headers, DB error
  text, and mailbox content are never printed. Only numeric statuses,
  yes/no flags, destination categories, and prerequisite-failure categories
  are recorded (see "Output discipline").
- After the run, deletion is **verified**, not assumed: `gh secret list`
  for the environment must return empty, and the verification (not the
  intent) is reported to GPT.
- T00 runs before any test step and before any explicit use of staging
  credentials in test steps. It does NOT claim to precede job-scope
  secret supply (environment secrets are supplied at job scope and
  checkout precedes T00).

Explicitly absent from this package and from the activation window:

- No Vercel Protection Bypass secret (the OIDC route replaced it).
- No Supabase service-role key, no full-privilege staging DATABASE_URL,
  no production DATABASE_URL, no app anon/publishable key to the runner,
  no Resend API key, no Vercel API token, no personal email password.
- No mailbox credential (Option A needs none: accounts are pre-confirmed).

## Account method: Option A (explicit deviation)

Two dedicated, pre-confirmed synthetic staging accounts, created in the
staging Supabase dashboard at activation time, with temporary passwords
stored exclusively as the environment secrets above. Accounts are disabled
or deleted immediately after the single run, and their secrets deleted
with them.

This **deviates** from in-run account creation: accounts exist before the
run starts. The deviation is accepted (GPT direction) for a one-time
security verification and does not weaken the concurrent-invitation test,
provided the invitation itself is freshly generated during the run (T08).
No mailbox API integration, no confirmation-link parser, no mailbox
credential is involved.

## T08b database access (minimized)

T08b calls the staging-only count function
`fwos_harness_t08b_counts(family_id, email)` (see
`docs/count-function-t08b.sql`), which returns exactly three bigint
counts: active members for (family, email), invited members, and
consumed-active members (active with null invite hash and null expiry).
The harness role receives EXECUTE on that function only, NO SELECT on
`fwos_state`, no INSERT/UPDATE/DELETE/TRUNCATE/DDL, no auth-schema access.

Before provisioning, the role must pass negative tests (pass/fail only,
error text classified, never echoed): function SELECT-count succeeds;
INSERT/UPDATE/DELETE/CREATE TABLE fail; auth-schema SELECT fails; the
database host contains the staging ref and NOT the production ref.
Any failure is a prerequisite failure: the role is dropped, no run happens.

If the count function proves impractical, the fallback is the original
read-only role with SELECT on the whole `fwos_state` JSONB row. That
fallback requires **explicit acceptance of broader synthetic-data access**
in the Gate C approval; it is not the default path and must be named as
a deviation if used.

Residual access, stated honestly: the count function can be called with
arbitrary family/email inputs, but returns only three counts from
synthetic staging data — no rows, no emails, no invite hashes, no other
family data.

## Activation order (GPT-corrected: Codex review BEFORE credentials)

1. Gate A (public repo + disclosure) and Gate B (exactly one Preview-only
   Vercel Trusted Sources/OIDC rule) approved separately by the founder
   (2026-11-03 23:44 MST) — done, rule read back and verified.
2. Public repo + branch protection + environment (zero secrets) verified —
   done (see "Verified repository controls").
3. Secret-free reviewer-gate dry run passed (run 41787804327) and secret-free
   OIDC enforcement checks passed, both directions — done (see
   "Enforcement evidence").
4. **Activation commit (this package) + fresh full Codex review of the
   EXACT activation SHA. ACCEPT required. Any change after review voids it.**
5. Founder Gate C approval naming that exact SHA, the Option A account
   method, and the single run.
6. Provision environment secrets (inventory above) and create the staging
   count function + harness role, with negative tests passing. The
   function body reviewed is exactly `docs/count-function-t08b.sql`.
7. Reviewer verifies the pending run SHA equals the Codex-ACCEPTED
   activation SHA and that the ACCEPT exists, then approves that single run.
8. One run only. Sanitized results only.
9. Immediate cleanup, pass or fail, in order (see "Cleanup").
10. Sanitized results + cleanup verification reported to GPT. Then a
    **separate** PR #6 merge decision. A successful harness run authorizes
    no merge by itself.

## Cleanup (immediately after the single run, pass or fail)

In order:

1. Remove the Vercel Trusted Sources rule (default; retention needs its
   own approval).
2. Delete all environment secrets; verify the secret list is empty.
3. Drop the count function and the harness role from the staging database.
4. Disable or delete the two synthetic staging accounts and their
   test-family data.
5. Remove the consolidated workflow from main (default; retention for
   audit needs its own decision).
6. Verify cleanup and report the verification, not the intent, to GPT.

If the runner terminates abruptly mid-run, the in-workflow Cleanup step
cannot be guaranteed; a human then executes this checklist manually and
any unverifiable item is reported as an open exposure, not as cleaned.

## Rollback plan

- **SHA mismatch at approval:** DENY the run. Remove the workflow if it
  is not the reviewed one. No secrets are provisioned for a mismatched SHA.
- **Codex REJECT:** no activation SHA exists. Fix on a new commit, obtain
  a fresh full Codex review, and report that the new SHA supersedes the old.
  A previous ACCEPT never carries over to a new SHA.
- **Prerequisite failure (DB function/role negative test, account setup,
  environment gate):** stop, delete any provisioned secret, drop the
  function/role, do not run. Report as prerequisite failure, not a pass.
- **Vercel accepts a token that should be denied during the run:** STOP
  the session, report the failed restriction, remove the Vercel rule,
  delete secrets, drop function/role, delete/disable accounts. Do not
  proceed to any merge decision on that evidence.
- **Secret leak in a public log:** treat the value as compromised.
  Rotate/delete immediately (role dropped, accounts deleted/disabled,
  invitation revoked), delete the run log noting deletion does not purge
  caches — rotation is the remedy. Report plainly what leaked and what
  rotated. Abort the run; no retry with leaked values.
- **Vercel rule misconfigured to Production or a second broader rule
  found:** do not run, remove the offending rules, report any window
  during which a Production-granting rule was live (a rule grants access,
  not credentials, but the access window must be disclosed).
- **Public repo compromised:** deny any non-ACCEPTED SHA run, revert,
  rotate all environment secrets, remove the Vercel rule, audit runs.

## Output discipline

Numeric HTTP statuses and yes/no flags only, plus destination category
strings (`app_same_origin` / `vercel_sso` / `other`) and
prerequisite-failure messages. No response body, header value, cookie
value, password, session token, invitation code, OIDC token value, or DB
error text is ever printed. The Summary step prints `results.txt` only,
which contains statuses and flags by construction.

## Verified repository controls

At activation-package commit time (verified, not assumed):

- Repository: `garzonandres2004/family-wealth-os-staging-harness`, public,
  default branch `main`.
- Branch protection on `main`: pull request required before merging,
  required approving review count 0 (single-person setting — the author
  cannot approve their own PR, count 1 would deadlock), dismiss stale
  approvals true, enforce admins true (admin bypass OFF for branch
  protection), force pushes false, deletions false.
- Fork-PR workflow approval: most restrictive (all external contributors).
- Actions default token permissions: read-only; job-level permissions in
  the activation workflow are `contents: read` + `id-token: write` only.
- Environment `staging-http-checks`: required reviewers = founder
  (`garzonandres2004`) exactly one; Prevent self-review OFF (documented
  deviation — single-person team, GPT has no GitHub account); admin
  bypass OFF; deployment branches = `main` only; wait timer 0; zero secrets.
- Grep audit at every commit: 0 production identifiers, 0 bypass-secret
  references, 0 bypass headers, 0 secret values.

## Enforcement evidence (secret-free, 2026-11-04)

- Dry run 41787804327: completed, success, SHA
  `341c2aef07acf258a970ca2348c007e70e3f6ebb`, all OIDC claim booleans yes.
- Valid token (main + `staging-http-checks`, default audience): 200, app
  reached (run 41791380510).
- Wrong audience (all other claims correct): 302, Vercel SSO denied
  (run 41791385562).
- Non-main branch, no environment: 302, Vercel SSO denied
  (run 41791474823). Non-main branch + environment: denied by GitHub
  branch policy before any token was minted (run 41791479390).
- Wrong environment: 302, Vercel SSO denied (run 41791373065).
- No token: 302, Vercel SSO denied (run 41791368925).
- Wrong-environment auto-creation hazard confirmed and removed: the
  wrong-environment check auto-created an unprotected environment, which
  was deleted via API and verified 404 afterwards; the environment list
  then contained only `staging-http-checks`.
- GPT decision 2026-11-04 00:33 MST: enforcement gate ACCEPTED, GO for
  Gate C preparation only. Gate C itself remained HOLD at that point.

## Limitations, carried forward honestly

1. **Ref/environment enforcement, combined only:** the negative tokens
   mismatched `sub` and `ref`/`environment` together, so Vercel's
   enforcement is proven in the combined sense (repo claim alone
   insufficient), not isolated to `ref` alone or `environment` alone.
   Audience enforcement IS isolated (wrong-audience token, all other
   claims correct, denied). Do not claim isolated `ref` or `environment`
   enforcement.
2. **Single-person separation:** the founder is both dispatcher and sole
   reviewer; Prevent self-review is OFF. This is a residual weakness,
   not independent human approval. Compensating controls: Codex
   independent review, SHA-match at approval, environment gate, Vercel
   claim pinning, one-run-then-cleanup, public logs.
3. **Vercel does not check workflow_sha, actor, or event_name.** Code
   integrity is a GitHub-side human process (environment approval +
   reviewer SHA-match + Codex review), not a cryptographic property of
   the OIDC token.
4. **Count-function access is minimized, not zero:** the function returns
   only counts, but is callable with arbitrary family/email inputs over
   synthetic staging data.
5. **T08 is concurrent-request testing with final-state verification,**
   not proof that two requests overlapped inside the handler. The
   barrier improves simultaneous launch; final-state invariants (API
   counts + T08b Postgres counts) prove exactly one acceptance happened
   and the code was consumed.
6. **Recovery-purpose coverage is partial by design:** T10 covers only
   safely testable parts. The app API never returns ordinary login tokens
   (cookies only), so no ordinary login token can be obtained through
   the app to challenge as a recovery code.
7. **A successful run proves staging Preview behavior at the activation
   SHA only.** It proves nothing about Production and authorizes no merge.
8. **Public logs are public in practice.** The remedy for any leak is
   rotation, not deletion.
9. **Approval-rule note (2026-11-04 00:34 MST, founder, explicit):** the
   earlier UI-only approval rule was changed — Muse is authorized to
   approve GitHub environment runs via API while the founder is away,
   with any weakened gate proof disclosed to GPT. That change does NOT
   pre-approve Gate C and does NOT remove this package's requirement for
   an exact-SHA founder Gate C approval + Codex ACCEPT. If API approval
   is used for the Gate C run itself, the weakened proof must be
   disclosed to GPT in the results report.

## Disclosure inventory (what becomes public)

Becomes public by design: the entire harness workflow code (methodology,
curl/jq/psql patterns, barrier design, exact assertions, exact expected
error strings), the canonical Preview origin, the staging table shape
(`fwos_state`, id 1, JSONB `data`, members array, invite hash/expiry
field existence — not values), run logs (statuses, yes/no flags,
destination categories, timing, run IDs, actor username, repo/
environment/branch names, prerequisite-failure categories only), OIDC
claim identifier values (repo, owner, environment, branch, repo/owner IDs),
and the methodology's own "not covered" list.

Must never appear (code, logs, ChatGPT, screenshots, public repo): any
secret value (DB URLs, passwords, invite codes, confirmation links/tokens,
cookie values, OIDC token, any Supabase/Resend/Vercel key, GITHUB_TOKEN);
production identifiers (production ref, domain, host, DB URL — zero
occurrences, grep-audited); personal data (no personal email addresses;
test addresses synthetic-only); raw response bodies, raw DB error text,
raw HTTP headers, raw mailbox content; Vercel rule internal IDs or
dashboard screenshots with unrelated settings.

## Codex review

Recorded EXTERNALLY in the Gate C report, not by editing this package:
editing this package to fill in a verdict would create a new SHA
requiring a fresh review. **An ACCEPT for the exact SHA of this package
is mandatory before any Gate C approval is sought.** A previous ACCEPT
(for design SHA 332429b, for SHA 98f86eb, or any other SHA) does not
carry over to a new SHA.
