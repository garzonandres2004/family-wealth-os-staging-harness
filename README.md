# Family Wealth OS — staging HTTP test harness

Staging-only test harness for Family Wealth OS. This repository contains ONLY
test-harness workflow code.

It contains NO application source, NO credentials, NO secrets, NO private
configuration, and NO real data. All test data is synthetic, staging-only.

The harness targets the staging Preview deployment only. It never targets
production, and no production identifier, domain, host, or database URL appears
in this repository (grep-audited at every commit).

Runs are gated by a GitHub environment (`staging-http-checks`) with required
reviewers: a run cannot access environment secrets before a reviewer approves
that exact run, and the reviewer verifies the run SHA matches the independently
reviewed activation SHA before approving.

Trigger: `workflow_dispatch` only. No push, pull_request, pull_request_target,
workflow_run, or schedule trigger exists in this repository.

## Gate C activation package (credential-free, pending)

`.github/workflows/staging-http-checks.yml` is the consolidated staging
HTTP harness (T00 OIDC self-check, T01–T10 including T08b count-function
verification, Summary, Cleanup), with its full activation procedure,
secret inventory/lifecycle, and rollback plan in `docs/activation.md`
and the T08b count-function body (design only, not applied) in
`docs/count-function-t08b.sql`.

**Gate C is PENDING.** Do not dispatch the consolidated workflow until a
fresh Codex review ACCEPTs its exact commit SHA **and** the founder gives
explicit Gate C approval naming that exact SHA. Any commit after the
reviewed SHA voids the review. No credential, password, database URL,
token, or secret value appears in this repository.
