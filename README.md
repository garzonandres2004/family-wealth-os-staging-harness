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
