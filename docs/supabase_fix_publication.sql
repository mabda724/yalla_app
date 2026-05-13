-- =============================================================
-- Fix: Ensure all required tables are in Realtime Publication
-- Safe to run multiple times (no errors if already exists)
-- =============================================================

DO $$
DECLARE
  tables_to_add TEXT[] := ARRAY['orders', 'order_tracking', 'riders', 'notifications'];
  tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY tables_to_add
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime' AND tablename = tbl
    ) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE %I;', tbl);
      RAISE NOTICE 'Added % to publication', tbl;
    ELSE
      RAISE NOTICE '% is already in publication, skipping', tbl;
    END IF;
  END LOOP;
END;
$$;

-- Verify
SELECT tablename FROM pg_publication_tables WHERE pubname = 'supabase_realtime' ORDER BY tablename;
