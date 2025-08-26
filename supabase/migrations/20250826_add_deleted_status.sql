-- Migration to add 'deleted' status to client_status column
-- This allows soft deletion of user accounts
-- Note: client_status is a TEXT column with CHECK constraint, not an enum

-- Drop the existing CHECK constraint
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_client_status_check;

-- Add new CHECK constraint that includes 'deleted' status
ALTER TABLE public.profiles ADD CONSTRAINT profiles_client_status_check 
    CHECK (client_status IN ('active', 'inactive', 'blocked', 'deleted'));

-- Add a comment to document the change
COMMENT ON COLUMN public.profiles.client_status IS 'User status: active (normal access), inactive (limited access), blocked (no access), deleted (soft deleted - no access, hidden from admin view)';
