-- 051_mcp_servers.up.sql
-- MCP server registry, agent connectors, and connection status tracking
BEGIN;

-- ===== MCP Server Registry (pre-configured + custom) =====
CREATE TABLE IF NOT EXISTS mcp_server_registry (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspace(id) ON DELETE CASCADE,
    -- Catalog entry fields (NULL workspace_id for global/built-in would need a separate table; we use a flag)
    is_builtin  BOOLEAN NOT NULL DEFAULT FALSE,
    slug        TEXT NOT NULL,                 -- e.g. "github", "slack", "postgres"
    name        TEXT NOT NULL,                 -- Display name: "GitHub MCP Server"
    description TEXT NOT NULL DEFAULT '',
    category    TEXT NOT NULL DEFAULT 'other', -- version_control, database, communication, search, sandbox, cloud, monitoring, productivity, browser, memory, finance
    icon_url    TEXT NOT NULL DEFAULT '',
    repo_url    TEXT NOT NULL DEFAULT '',      -- GitHub repo URL
    -- Connection config
    server_url  TEXT NOT NULL DEFAULT '',      -- Default URL / base URL
    transport   TEXT NOT NULL DEFAULT 'stdio' CHECK (transport IN ('stdio', 'sse', 'streamable-http')),
    command     TEXT NOT NULL DEFAULT '',      -- CLI command for stdio transport (e.g. "npx -y @modelcontextprotocol/server-github")
    args        JSONB NOT NULL DEFAULT '[]',   -- CLI arguments
    env_vars    JSONB NOT NULL DEFAULT '[]',   -- Required env vars: [{"name": "GITHUB_TOKEN", "description": "...", "required": true}]
    -- Auth
    auth_type   TEXT NOT NULL DEFAULT 'none' CHECK (auth_type IN ('none', 'bearer', 'mcp_oauth', 'api_key', 'env_var')),
    oauth_config JSONB,                        -- OAuth endpoints if auth_type = 'mcp_oauth'
    -- Metadata
    tags        TEXT[] NOT NULL DEFAULT '{}',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_mcp_registry_workspace_slug
    ON mcp_server_registry(workspace_id, slug);

-- ===== Agent MCP Connectors (which MCP servers are attached to which agents) =====
CREATE TABLE IF NOT EXISTS agent_mcp_connector (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspace(id) ON DELETE CASCADE,
    agent_id    UUID NOT NULL REFERENCES managed_agent(id) ON DELETE CASCADE,
    registry_id UUID REFERENCES mcp_server_registry(id) ON DELETE SET NULL, -- NULL = custom server not in registry
    -- Connection override (takes precedence over registry defaults)
    name        TEXT NOT NULL,
    server_url  TEXT NOT NULL DEFAULT '',
    transport   TEXT NOT NULL DEFAULT 'stdio' CHECK (transport IN ('stdio', 'sse', 'streamable-http')),
    command     TEXT NOT NULL DEFAULT '',
    args        JSONB NOT NULL DEFAULT '[]',
    env_config  JSONB NOT NULL DEFAULT '{}',  -- Resolved env vars (encrypted values via vault)
    -- Auth
    auth_type   TEXT NOT NULL DEFAULT 'none' CHECK (auth_type IN ('none', 'bearer', 'mcp_oauth', 'api_key', 'env_var')),
    vault_credential_id UUID REFERENCES vault_credential(id) ON DELETE SET NULL,
    -- Status
    enabled     BOOLEAN NOT NULL DEFAULT TRUE,
    status      TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'connected', 'error', 'disabled')),
    status_message TEXT,
    last_validated_at TIMESTAMPTZ,
    -- Tool discovery cache
    discovered_tools JSONB NOT NULL DEFAULT '[]', -- Cached tool list from last discovery
    tools_discovered_at TIMESTAMPTZ,
    -- Metadata
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_agent_mcp_connector_agent
    ON agent_mcp_connector(agent_id) WHERE enabled = TRUE;

CREATE INDEX IF NOT EXISTS idx_agent_mcp_connector_workspace
    ON agent_mcp_connector(workspace_id);

COMMIT;
