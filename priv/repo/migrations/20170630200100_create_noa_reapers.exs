defmodule Noa.Repo.Migrations.CreateNoaReapers do
  use Ecto.Migration

  def up do
    execute """
    CREATE OR REPLACE FUNCTION reap_authz_codes(
      expired_on_or_before timestamp,
      delete_atmost integer)
        RETURNS TABLE (id uuid)
        LANGUAGE 'plpgsql'
    AS $$
    DECLARE
      count integer;
    BEGIN
      IF (delete_atmost <= 0) THEN
        count = 25;
      ELSE
        count = delete_atmost;
      END IF;

      RETURN QUERY
      DELETE FROM authz_codes AS t
      WHERE t.id IN (
        SELECT t.id FROM authz_codes AS t
        WHERE t.expires_on <= expired_on_or_before
        LIMIT count
      )
      RETURNING t.id;
    END;
    $$;
    """

    execute """
    CREATE OR REPLACE FUNCTION reap_acc_tokens(
      expired_on_or_before timestamp,
      delete_atmost integer)
        RETURNS TABLE (id uuid)
        LANGUAGE 'plpgsql'
    AS $$
    DECLARE
      count integer;
    BEGIN
      IF (delete_atmost <= 0) THEN
        count = 25;
      ELSE
        count = delete_atmost;
      END IF;

      RETURN QUERY
      DELETE FROM acc_tokens AS t
      WHERE t.id IN (
        SELECT t.id FROM acc_tokens AS t
        WHERE t.expires_on <= expired_on_or_before
        LIMIT count
      )
      RETURNING t.id;
    END;
    $$;
    """

    execute """
    CREATE OR REPLACE FUNCTION reap_ref_tokens(
      expired_on_or_before timestamp,
      delete_atmost integer)
        RETURNS TABLE (id uuid)
        LANGUAGE 'plpgsql'
    AS $$
    DECLARE
      count integer;
    BEGIN
      IF (delete_atmost <= 0) THEN
        count = 25;
      ELSE
        count = delete_atmost;
      END IF;

      RETURN QUERY
      DELETE FROM ref_tokens AS t
      WHERE t.id IN (
        SELECT t.id FROM ref_tokens AS t
        WHERE t.expires_on <= expired_on_or_before
        LIMIT count
      )
      RETURNING t.id;
    END;
    $$;
    """
  end

  def down do
    execute "DROP FUNCTION reap_authz_codes(timestamp, integer);"
    execute "DROP FUNCTION reap_acc_tokens(timestamp, integer);"
    execute "DROP FUNCTION reap_ref_tokens(timestamp, integer);"
  end
end
