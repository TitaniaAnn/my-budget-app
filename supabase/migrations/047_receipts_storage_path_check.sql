-- ============================================================
-- Constrain receipts.storage_path to the row's household prefix.
--
-- Pre-fix: nothing stopped a member from inserting a `receipts`
-- row in THEIR household pointing at another household's
-- `storage.objects.name`. The storage DELETE policy (migration
-- 016) authorises by looking up `receipts.storage_path =
-- storage.objects.name` and checking the uploader / owner — so
-- a crafted row in the attacker's own household, pointing at a
-- victim's image path, satisfies the policy and the attacker can
-- delete the victim's image. Requires knowing the path (former
-- member / log leak), but the consequence — silent loss of
-- another household's receipt — is bad enough to close.
--
-- Fix: a row-level CHECK requiring `storage_path` to live under
-- the household's own folder. The upload code in
-- ReceiptsRepository.uploadAndCreateReceipt already builds the
-- path as `'$householdId/$fileName'`, so every existing row
-- satisfies this naturally. The DO block at the top of this
-- migration raises loudly if that assumption is ever wrong — a
-- failed migration is much better than a silent CHECK creation
-- that the next INSERT trips on.
--
-- thumbnail_path is nullable; the CHECK allows NULL OR matching
-- prefix so future code that populates it stays under the same
-- constraint without changing the data model.
--
-- Audit reference: H5.
-- ============================================================

DO $$
DECLARE
  v_bad INTEGER;
BEGIN
  SELECT count(*) INTO v_bad
    FROM receipts
   WHERE storage_path NOT LIKE household_id::text || '/%';
  IF v_bad > 0 THEN
    RAISE EXCEPTION
      'receipts.storage_path constraint pre-check failed: % rows do NOT '
      'start with their household_id prefix. Fix these before applying '
      'the CHECK (rename in storage + update the column, or delete the '
      'orphan rows + their storage objects).', v_bad;
  END IF;

  SELECT count(*) INTO v_bad
    FROM receipts
   WHERE thumbnail_path IS NOT NULL
     AND thumbnail_path NOT LIKE household_id::text || '/%';
  IF v_bad > 0 THEN
    RAISE EXCEPTION
      'receipts.thumbnail_path constraint pre-check failed: % rows do '
      'NOT start with their household_id prefix.', v_bad;
  END IF;
END $$;

ALTER TABLE receipts
  ADD CONSTRAINT receipts_storage_path_household_prefix
  CHECK (storage_path LIKE household_id::text || '/%');

ALTER TABLE receipts
  ADD CONSTRAINT receipts_thumbnail_path_household_prefix
  CHECK (
    thumbnail_path IS NULL
    OR thumbnail_path LIKE household_id::text || '/%'
  );
