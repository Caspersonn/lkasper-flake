\set ON_ERROR_STOP on

BEGIN;

CREATE TEMP TABLE retained_user ON COMMIT DROP AS
SELECT id FROM users WHERE email = 'luca.kasper@technative.eu';

CREATE TEMP TABLE retained_organization ON COMMIT DROP AS
SELECT id FROM organizations WHERE user_id IN (SELECT id FROM retained_user);

DO $$
BEGIN
  IF (SELECT count(*) FROM retained_user) <> 1
    OR (SELECT count(*) FROM retained_organization) <> 1 THEN
    RAISE EXCEPTION 'Expected one Luca user and one owned organization';
  END IF;
  IF EXISTS (
    SELECT 1 FROM members
    WHERE organization_id IN (SELECT id FROM retained_organization)
      AND user_id NOT IN (SELECT id FROM retained_user)
  ) THEN
    RAISE EXCEPTION 'The retained organization has other members';
  END IF;
END;
$$;

DELETE FROM sessions;
DELETE FROM cache;
DELETE FROM cache_locks;
DELETE FROM jobs;
DELETE FROM failed_jobs;
DELETE FROM password_reset_tokens;
DELETE FROM oauth_refresh_tokens;
DELETE FROM oauth_access_tokens;
DELETE FROM oauth_auth_codes;
DELETE FROM oauth_device_codes;
DELETE FROM oauth_clients;
DELETE FROM personal_access_tokens;

UPDATE users SET current_team_id = NULL
WHERE id NOT IN (SELECT id FROM retained_user);

DELETE FROM audits
WHERE owner_organization_id NOT IN (SELECT id FROM retained_organization)
   OR owner_user_id NOT IN (SELECT id FROM retained_user)
   OR owner_organization_id IS NULL
   OR owner_user_id IS NULL;
DELETE FROM time_entries
WHERE organization_id NOT IN (SELECT id FROM retained_organization)
   OR user_id NOT IN (SELECT id FROM retained_user);
DELETE FROM goals
WHERE organization_id NOT IN (SELECT id FROM retained_organization);
DELETE FROM project_members
WHERE project_id IN (
  SELECT id FROM projects
  WHERE organization_id NOT IN (SELECT id FROM retained_organization)
) OR user_id NOT IN (SELECT id FROM retained_user);
DELETE FROM tasks
WHERE organization_id NOT IN (SELECT id FROM retained_organization);
DELETE FROM projects
WHERE organization_id NOT IN (SELECT id FROM retained_organization);
DELETE FROM clients
WHERE organization_id NOT IN (SELECT id FROM retained_organization);
DELETE FROM tags
WHERE organization_id NOT IN (SELECT id FROM retained_organization);
DELETE FROM reports
WHERE organization_id NOT IN (SELECT id FROM retained_organization);
DELETE FROM organization_invitations;
DELETE FROM members
WHERE organization_id NOT IN (SELECT id FROM retained_organization)
   OR user_id NOT IN (SELECT id FROM retained_user);
DELETE FROM organizations
WHERE id NOT IN (SELECT id FROM retained_organization);
DELETE FROM users
WHERE id NOT IN (SELECT id FROM retained_user);

COMMIT;
