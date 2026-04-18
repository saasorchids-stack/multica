-- 050_managed_agents: Add all tables for Claude Managed Agents API compatibility.
-- Adds: managed_agent, managed_agent_version, environment, managed_session,
--        session_event, memory_store, memory, memory_version, vault,
--        vault_credential, session_thread

BEGIN;

-- ===========================================================================
-- 1. MANAGED AGENTS (versioned, Managed Agents API compatible)
-- ===========================================================================
-- Separate from existing `agent` table to avoid breaking existing daemon flow.

CREATE TABLE managed_agent (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspace(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    model JSONB NOT NULL DEFAULT '{"id":"claude-sonnet-4-20250514","speed":"standard"}',
    system_prompt TEXT,
    tools JSONB NOT NULL DEFAULT '[]',
    mcp_servers JSONB NOT NULL DEFAULT '[]',
    skills JSONB NOT NULL DEFAULT '[]',
    callable_agents JSONB NOT NULL DEFAULT '[]',
    metadata JSONB NOT NULL DEFAULT '{}',
    version INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    archived_at TIMESTAMPTZ
);

CREATE INDEX idx_managed_agent_workspace ON managed_agent(workspace_id);
CREATE UNIQUE INDEX idx_managed_agent_unique_name
    ON managed_agent(workspace_id, name) WHERE archived_at IS NULL;

CREATE TABLE managed_agent_version (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID NOT NULL REFERENCES managed_agent(id) ON DELETE CASCADE,
    version INT NOT NULL,
    snapshot JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(agent_id, version)
);

-- ===========================================================================
-- 2. ENVIRONMENTS (container templates)
-- ===========================================================================

CREATE TABLE environment (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspace(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    config JSONB NOT NULL DEFAULT '{"type":"cloud","packages":{},"networking":{"type":"unrestricted"}}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    archived_at TIMESTAMPTZ
);

CREATE INDEX idx_environment_workspace ON environment(workspace_id);
CREATE UNIQUE INDEX idx_environment_unique_name
    ON environment(name, workspace_id) WHERE archived_at IS NULL;

-- ===========================================================================
-- 3. MANAGED SESSIONS (full state machine, usage tracking)
-- ===========================================================================

CREATE TABLE managed_session (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspace(id) ON DELETE CASCADE,
    agent_id UUID NOT NULL REFERENCES managed_agent(id),
    agent_version INT NOT NULL,
    environment_id UUID REFERENCES environment(id),
    status TEXT NOT NULL DEFAULT 'idle' CHECK (status IN ('idle', 'running', 'rescheduling', 'terminated')),
    vault_ids UUID[] NOT NULL DEFAULT '{}',
    resources JSONB NOT NULL DEFAULT '[]',
    usage_input_tokens BIGINT NOT NULL DEFAULT 0,
    usage_output_tokens BIGINT NOT NULL DEFAULT 0,
    usage_cache_creation_tokens BIGINT NOT NULL DEFAULT 0,
    usage_cache_read_tokens BIGINT NOT NULL DEFAULT 0,
    title TEXT,
    stop_reason JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    archived_at TIMESTAMPTZ
);

CREATE INDEX idx_managed_session_workspace ON managed_session(workspace_id);
CREATE INDEX idx_managed_session_agent ON managed_session(agent_id);
CREATE INDEX idx_managed_session_status ON managed_session(status) WHERE status IN ('idle', 'running');

-- ===========================================================================
-- 4. SESSION EVENTS (event sourcing)
-- ===========================================================================

CREATE TABLE session_event (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES managed_session(id) ON DELETE CASCADE,
    thread_id UUID,
    type TEXT NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}',
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_session_event_session ON session_event(session_id, created_at);
CREATE INDEX idx_session_event_thread ON session_event(thread_id, created_at) WHERE thread_id IS NOT NULL;

-- ===========================================================================
-- 5. MEMORY STORES
-- ===========================================================================

CREATE TABLE memory_store (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspace(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    archived_at TIMESTAMPTZ
);

CREATE INDEX idx_memory_store_workspace ON memory_store(workspace_id);

CREATE TABLE memory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES memory_store(id) ON DELETE CASCADE,
    path TEXT NOT NULL,
    content TEXT NOT NULL,
    content_sha256 TEXT NOT NULL,
    content_size_bytes INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(store_id, path)
);

CREATE INDEX idx_memory_store_path ON memory(store_id);

CREATE TABLE memory_version (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    memory_id UUID REFERENCES memory(id) ON DELETE SET NULL,
    store_id UUID NOT NULL REFERENCES memory_store(id) ON DELETE CASCADE,
    operation TEXT NOT NULL CHECK (operation IN ('created', 'modified', 'deleted')),
    content TEXT,
    content_sha256 TEXT,
    content_size_bytes INT,
    path TEXT NOT NULL,
    session_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    redacted_at TIMESTAMPTZ
);

CREATE INDEX idx_memory_version_store ON memory_version(store_id, created_at);
CREATE INDEX idx_memory_version_memory ON memory_version(memory_id) WHERE memory_id IS NOT NULL;

-- ===========================================================================
-- 6. VAULTS (credential management)
-- ===========================================================================

CREATE TABLE vault (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspace(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    archived_at TIMESTAMPTZ
);

CREATE INDEX idx_vault_workspace ON vault(workspace_id);

CREATE TABLE vault_credential (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID NOT NULL REFERENCES vault(id) ON DELETE CASCADE,
    mcp_server_url TEXT NOT NULL,
    auth_type TEXT NOT NULL CHECK (auth_type IN ('mcp_oauth', 'bearer')),
    encrypted_payload BYTEA NOT NULL,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    archived_at TIMESTAMPTZ
);

-- Partial unique: only one active credential per (vault, mcp_server_url)
CREATE UNIQUE INDEX idx_vault_credential_active
    ON vault_credential(vault_id, mcp_server_url) WHERE archived_at IS NULL;

-- ===========================================================================
-- 7. SESSION THREADS (multi-agent)
-- ===========================================================================

CREATE TABLE session_thread (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES managed_session(id) ON DELETE CASCADE,
    agent_id UUID NOT NULL REFERENCES managed_agent(id),
    agent_name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'idle' CHECK (status IN ('idle', 'running')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_session_thread_session ON session_thread(session_id);

COMMIT;
