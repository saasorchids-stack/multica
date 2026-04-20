-- 052_session_store_harness: Anthropic Managed Agents architecture parity.
-- Adds: event_index for positional slicing, cost_events for granular tracking,
--        session metadata columns for wake/recovery, context_strategy support.

BEGIN;

-- ===========================================================================
-- 1. SESSION EVENTS — Add event_index for positional slicing (getEvents)
-- ===========================================================================
-- The session event log must support positional queries:
--   getEvents(sessionId, from?, to?) → slice
-- event_index is an immutable, monotonically increasing counter per session.

ALTER TABLE session_event
    ADD COLUMN IF NOT EXISTS event_index INT;

-- Backfill existing events with row_number
WITH numbered AS (
    SELECT id, ROW_NUMBER() OVER (PARTITION BY session_id ORDER BY created_at) - 1 AS idx
    FROM session_event
)
UPDATE session_event SET event_index = numbered.idx
FROM numbered WHERE session_event.id = numbered.id;

-- Make NOT NULL after backfill
ALTER TABLE session_event ALTER COLUMN event_index SET NOT NULL;

-- Unique index for positional queries: getEvents(sessionId, from, to)
CREATE UNIQUE INDEX IF NOT EXISTS idx_session_event_index
    ON session_event(session_id, event_index);

-- Add metadata column for token/cost per event
ALTER TABLE session_event
    ADD COLUMN IF NOT EXISTS metadata JSONB;

-- ===========================================================================
-- 2. COST EVENTS — Granular cost tracking (Multica differentiator)
-- ===========================================================================

CREATE TABLE IF NOT EXISTS cost_event (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES managed_session(id) ON DELETE CASCADE,
    workspace_id UUID NOT NULL REFERENCES workspace(id) ON DELETE CASCADE,
    provider TEXT NOT NULL,
    model TEXT NOT NULL,
    operation TEXT NOT NULL CHECK (operation IN (
        'inference', 'tool_call', 'web_search', 'sandbox_runtime',
        'mcp_call', 'context_reset', 'delegation'
    )),
    tokens_input BIGINT DEFAULT 0,
    tokens_output BIGINT DEFAULT 0,
    tokens_cached BIGINT DEFAULT 0,
    cost_usd NUMERIC(12, 8) NOT NULL DEFAULT 0,
    duration_ms INT,
    tool_name TEXT,
    event_index INT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_cost_event_session ON cost_event(session_id, created_at);
CREATE INDEX idx_cost_event_workspace ON cost_event(workspace_id, created_at);
CREATE INDEX idx_cost_event_provider ON cost_event(workspace_id, provider);

-- ===========================================================================
-- 3. MANAGED SESSION — Add columns for wake/recovery + context strategy
-- ===========================================================================

-- last_event_index: the harness writes this on each event to enable fast resume
ALTER TABLE managed_session
    ADD COLUMN IF NOT EXISTS last_event_index INT NOT NULL DEFAULT 0;

-- context_strategy: how the harness builds the context window
ALTER TABLE managed_session
    ADD COLUMN IF NOT EXISTS context_strategy JSONB NOT NULL DEFAULT '{"type":"sliding_window","max_tokens":180000}';

-- total_cost_usd: aggregated cost for display
ALTER TABLE managed_session
    ADD COLUMN IF NOT EXISTS total_cost_usd NUMERIC(12, 8) NOT NULL DEFAULT 0;

-- wake_count: how many times this session has been woken (crash recovery metric)
ALTER TABLE managed_session
    ADD COLUMN IF NOT EXISTS wake_count INT NOT NULL DEFAULT 0;

-- last_wake_at: when the last wake happened
ALTER TABLE managed_session
    ADD COLUMN IF NOT EXISTS last_wake_at TIMESTAMPTZ;

-- ===========================================================================
-- 4. WORKSPACE — Budget tracking columns
-- ===========================================================================

ALTER TABLE workspace
    ADD COLUMN IF NOT EXISTS daily_budget_usd NUMERIC(12, 2),
    ADD COLUMN IF NOT EXISTS monthly_budget_usd NUMERIC(12, 2);

COMMIT;
