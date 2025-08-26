-- Migration to add 'deleted' status to client_status enum
-- This allows soft deletion of user accounts

-- Add 'deleted' value to the existing client_status enum
ALTER TYPE client_status ADD VALUE IF NOT EXISTS 'deleted';

-- Optional: Add a comment to document the change
COMMENT ON TYPE client_status IS 'User status: active (normal access), inactive (limited access), blocked (no access), deleted (soft deleted - no access, hidden from admin view)';
