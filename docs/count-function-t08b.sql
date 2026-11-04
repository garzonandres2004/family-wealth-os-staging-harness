-- ============================================================================
-- T08b COUNT FUNCTION — DESIGN ONLY, FOR CODEX REVIEW AT ACTIVATION SHA
-- DO NOT APPLY THIS FILE YET. Creation belongs to Gate C activation,
-- AFTER the Codex ACCEPT for the activation SHA and AFTER founder Gate C
-- approval of that exact SHA. Applying it now would be a database change
-- before Gate C, which is forbidden.
-- Target: STAGING database ONLY (project family-wealth-os-staging).
-- Never apply to Production. Verify the target database identity (host
-- contains the staging project ref, NOT the production ref) before any
-- application, and verify it again in the activation run report.
-- ============================================================================
-- Store shape (private app repo, PR #6 head edd0a7a, lib/store.ts,
-- lib/service.ts, verified by reading the code, not assumed):
--   table fwos_state (id INTEGER PRIMARY KEY, data JSONB NOT NULL),
--   exactly one row, id = 1, data = { members: [...] }.
--   member fields used here: familyId (string), email (string),
--   status ('active' | 'invited'), inviteTokenHash (string | null),
--   inviteExpiresAt (ISO string | null).
--   On acceptance (service.acceptInvite): status becomes 'active',
--   inviteTokenHash becomes null, inviteExpiresAt becomes null.
-- Hence "consumed-active" = status 'active' AND inviteTokenHash IS NULL
-- AND inviteExpiresAt IS NULL. A member who was created active directly
-- (e.g. a family creator) also satisfies that predicate; T08b therefore
-- asserts consumed = 1 for the INVITEE email only, in the family the
-- invitee was invited into, which is exactly one member by construction
-- (T08 asserts the API membership count for the invitee is 1 active,
-- 0 invited, before T08b runs).
-- Email comparison: lower() on both sides. The app compares the
-- verified session email (trimmed, lowercased) against the stored
-- member email; lower() in SQL matches that comparison and is safe
-- against case differences in the provisioned test addresses.
-- familyId comparison: exact equality (UUID string, case-sensitive
-- in practice; no lower() applied, so a mismatched case fails rather
-- than silently matching a different family).
-- No dynamic SQL: p_family_id and p_email appear only in comparisons,
-- never in a constructed query string. No injection path.
-- SECURITY DEFINER is required and deliberate: the harness role has
-- NO SELECT on fwos_state, so only a definer-rights function owned by
-- a role WITH SELECT can answer the counts. The function returns
-- ONLY three bigint counts — no rows, no emails, no hashes, no other
-- family data. Residual access: callable with arbitrary family/email
-- inputs, returning only counts from synthetic staging data.
-- search_path is pinned to public, pg_temp (pg_temp LAST, explicitly
-- listed, so it is searched last, not first as PostgreSQL's implicit
-- default would do). AND the relation is schema-qualified as
-- public.fwos_state below, so even a temporary table named fwos_state
-- created by a caller with TEMP privilege cannot shadow it (Codex
-- finding B2: pinning search_path alone does not exclude the implicit
-- temporary-schema precedence for unqualified relation lookup).
-- ============================================================================

CREATE OR REPLACE FUNCTION public.fwos_harness_t08b_counts(
    p_family_id text,
    p_email text
)
RETURNS TABLE (
    active_count bigint,
    invited_count bigint,
    consumed_active_count bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT
        count(*) FILTER (
            WHERE (m->>'familyId') = p_family_id
              AND lower(m->>'email') = lower(p_email)
              AND (m->>'status') = 'active'
        ),
        count(*) FILTER (
            WHERE (m->>'familyId') = p_family_id
              AND lower(m->>'email') = lower(p_email)
              AND (m->>'status') = 'invited'
        ),
        count(*) FILTER (
            WHERE (m->>'familyId') = p_family_id
              AND lower(m->>'email') = lower(p_email)
              AND (m->>'status') = 'active'
              AND (m->>'inviteTokenHash') IS NULL
              AND (m->>'inviteExpiresAt') IS NULL
        )
    FROM public.fwos_state,
         LATERAL jsonb_array_elements(
             COALESCE(data -> 'members', '[]'::jsonb)
         ) AS m
    WHERE id = 1;
$$;

-- Activation-only grants (DO NOT RUN NOW; run only at Gate C activation,
-- after Codex ACCEPT + founder Gate C approval, on the STAGING database):
--   REVOKE ALL ON FUNCTION public.fwos_harness_t08b_counts(text, text)
--     FROM PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.fwos_harness_t08b_counts(text, text)
--     TO fwos_harness_readonly;  -- name fixed at activation
-- The harness role must receive NO SELECT on fwos_state, NO INSERT /
-- UPDATE / DELETE / TRUNCATE / DDL, and NO access to any auth schema.
-- Pre-use negative tests (pass/fail only, error text classified,
-- never echoed): SELECT count via the function succeeds; INSERT /
-- UPDATE / DELETE / CREATE TABLE fail; CREATE TEMP TABLE fails (the
-- harness role must have NO TEMP privilege, so no temporary fwos_state
-- can shadow the qualified relation); auth.* SELECT fails; the
-- database host contains the staging ref and NOT the production ref.
-- Any failure = prerequisite failure, role dropped, no run.
-- Cleanup (immediately after the single run, pass or fail):
--   DROP FUNCTION IF EXISTS public.fwos_harness_t08b_counts(text, text);
--   DROP ROLE IF EXISTS fwos_harness_readonly;
-- Fallback, only with explicit acceptance of broader synthetic-data
-- access: a read-only role with SELECT on fwos_state only (the whole
-- JSONB row, id 1). That fallback is NOT in this package's default
-- path and must be named as a deviation in the Gate C approval if used.
