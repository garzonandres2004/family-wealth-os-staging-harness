# Gate C Run 3 preparation note

## Why Run 3 exists
Run 2 (41801377621, SHA f4cfb649) failed at T02: a valid OIDC token was
denied by Vercel and fell through to SSO (root 302 vercel_sso, API 302
vercel_sso, ASSERT_FAIL t02_api_status). T03–T10 were skipped, not failed.
Run 2 cleanup is verified complete.

## Diagnosis (agreed by GPT, not yet proven at the claim level)
The Run 2 re-added Vercel Trusted Sources rule saved a different `sub` than
the successful Gate B rule, and left the identity id fields blank:
- Run 2 rule sub: repo:garzonandres2004/family-wealth-os-staging-harness:environment:staging-http-checks
- Gate B rule sub: repo:garzonandres2004@150756751/family-wealth-os-staging-harness@1445264408:environment:staging-http-checks
- Gate B repository_id: 1445264408, repository_owner_id: 150756751, repository_owner: garzonandres2004

## Run 3 prerequisite (binding, no loosening)
1. Re-add exactly one Vercel Trusted Sources rule restoring the Gate B
   configuration EXACTLY: issuer https://token.actions.githubusercontent.com,
   aud https://github.com/garzonandres2004,
   repository garzonandres2004/family-wealth-os-staging-harness,
   repository_id 1445264408, repository_owner garzonandres2004,
   repository_owner_id 150756751,
   sub repo:garzonandres2004@150756751/family-wealth-os-staging-harness@1445264408:environment:staging-http-checks,
   ref refs/heads/main, environment staging-http-checks, Applies-to Preview
   ONLY (no Production, no Development).
2. Read the rule back in full, including the exact `sub` string and every id
   field, and compare it character-for-character against the list above.
   Dispatch is FORBIDDEN until the read-back matches exactly.
3. BEFORE provisioning any test account or secret, run the secret-free
   positive control already on main, workflow `oidc-check-valid.yml`
   (environment staging-http-checks, main only): a valid OIDC token must
   reach the app (http 200, classification app, expected_app yes). If it
   does not, STOP: no accounts, no secrets, no full run. This control is
   what would have caught Run 2's problem without consuming a full run.
4. Only after steps 1–3 pass, provision fresh Option A accounts, the
   count function/role with negative tests, and the same five environment
   secrets, then dispatch the consolidated workflow in this package once,
   under a fresh SHA-named founder approval for that SHA. Run 3 is a
   completely new test: all T00–T10 must pass independently.

## Workflow in this package
`.github/workflows/staging-http-checks.yml` is restored byte-identical to
the Run 2 activation SHA f4cfb649 (T00–T10 including T03b/T07b in-harness
family/account setup). No claim, audience, repository, environment, branch,
or Preview-only restriction is loosened by this package. The fix is in the
Vercel rule configuration and the positive-control gate, not in the harness.
