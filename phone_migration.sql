-- Phone Number Migration Script
-- This script migrates existing phone number data to the new optimized schema

-- Step 1: Install pg_libphonenumber extension (run this manually in Supabase)
-- This needs to be done by a database administrator
-- SELECT * FROM pg_available_extensions WHERE name = 'pg_libphonenumber';
-- CREATE EXTENSION IF NOT EXISTS pg_libphonenumber;

-- Step 2: Add new phone_normalized column to users table
-- (This is already included in the main schema, but adding here for clarity)
-- ALTER TABLE public.users ADD COLUMN phone_normalized TEXT GENERATED ALWAYS AS (
--     CASE
--         WHEN phone IS NULL THEN NULL
--         ELSE normalize_phone_number(phone)
--     END
-- ) STORED;

-- Step 3: Create phone number functions (already in main schema)
-- These functions are defined in the main schema file

-- Step 4: Validate existing phone numbers and create migration report
CREATE TEMP TABLE phone_validation_report AS
SELECT
    id,
    name,
    phone,
    CASE
        WHEN phone IS NULL THEN 'NULL - OK'
        WHEN validate_phone_number(phone) THEN 'VALID'
        ELSE 'INVALID - NEEDS CORRECTION'
    END as validation_status,
    normalize_phone_number(phone) as normalized_version
FROM public.users
WHERE phone IS NOT NULL;

-- Step 5: Show validation report
SELECT
    validation_status,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM phone_validation_report
GROUP BY validation_status
ORDER BY count DESC;

-- Step 6: Show invalid phone numbers that need correction
SELECT
    id,
    name,
    phone,
    normalized_version
FROM phone_validation_report
WHERE validation_status = 'INVALID - NEEDS CORRECTION'
ORDER BY id;

-- Step 7: Update invalid phone numbers (manual intervention required)
-- For each invalid phone number, you need to either:
-- 1. Correct the phone number format
-- 2. Set it to NULL if the number is not recoverable

-- Example corrections (uncomment and modify as needed):
-- UPDATE public.users SET phone = '+212612345678' WHERE id = 'user-id-1' AND phone = '0612345678';
-- UPDATE public.users SET phone = NULL WHERE id = 'user-id-2' AND phone = 'invalid-number';

-- Step 8: Add check constraint after data is clean
-- This is already in the main schema, but ensuring it's applied:
-- ALTER TABLE public.users ADD CONSTRAINT check_phone_format
--     CHECK (validate_phone_number(phone));

-- Step 9: Create indexes for phone number searches
-- These are already in the main schema

-- Step 10: Test the phone number functions
SELECT
    phone,
    phone_normalized,
    format_phone_number(phone) as display_format
FROM public.users
WHERE phone IS NOT NULL
LIMIT 10;

-- Step 11: Clean up temporary table
DROP TABLE phone_validation_report;

-- Migration completed!
-- Remember to:
-- 1. Install pg_libphonenumber extension in Supabase dashboard
-- 2. Run this migration script
-- 3. Manually correct any invalid phone numbers
-- 4. Test phone number validation in your application