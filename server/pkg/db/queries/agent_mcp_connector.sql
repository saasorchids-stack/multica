-- name: CreateAgentMcpConnector :one
INSERT INTO agent_mcp_connector (
    workspace_id, agent_id, registry_id, name, server_url,
    transport, command, args, env_config,
    auth_type, vault_credential_id, enabled
) VALUES (
    $1, $2, $3, $4, $5,
    $6, $7, $8, $9,
    $10, $11, $12
)
RETURNING *;

-- name: GetAgentMcpConnector :one
SELECT * FROM agent_mcp_connector WHERE id = $1 AND workspace_id = $2;

-- name: ListAgentMcpConnectors :many
SELECT * FROM agent_mcp_connector
WHERE agent_id = $1 AND workspace_id = $2
ORDER BY name ASC;

-- name: ListEnabledAgentMcpConnectors :many
SELECT * FROM agent_mcp_connector
WHERE agent_id = $1 AND workspace_id = $2 AND enabled = TRUE
ORDER BY name ASC;

-- name: UpdateAgentMcpConnector :one
UPDATE agent_mcp_connector SET
    name = COALESCE($3, name),
    server_url = COALESCE($4, server_url),
    transport = COALESCE($5, transport),
    command = COALESCE($6, command),
    args = COALESCE($7, args),
    env_config = COALESCE($8, env_config),
    auth_type = COALESCE($9, auth_type),
    vault_credential_id = $10,
    enabled = COALESCE($11, enabled),
    updated_at = now()
WHERE id = $1 AND workspace_id = $2
RETURNING *;

-- name: UpdateAgentMcpConnectorStatus :exec
UPDATE agent_mcp_connector SET
    status = $2,
    status_message = $3,
    last_validated_at = now(),
    updated_at = now()
WHERE id = $1;

-- name: UpdateAgentMcpConnectorTools :exec
UPDATE agent_mcp_connector SET
    discovered_tools = $2,
    tools_discovered_at = now(),
    updated_at = now()
WHERE id = $1;

-- name: DeleteAgentMcpConnector :exec
DELETE FROM agent_mcp_connector WHERE id = $1 AND workspace_id = $2;

-- name: CountAgentMcpConnectors :one
SELECT count(*) FROM agent_mcp_connector WHERE agent_id = $1 AND workspace_id = $2;
