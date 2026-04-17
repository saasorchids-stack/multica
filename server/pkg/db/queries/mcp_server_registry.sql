-- name: CreateMcpServerRegistry :one
INSERT INTO mcp_server_registry (
    workspace_id, is_builtin, slug, name, description, category,
    icon_url, repo_url, server_url, transport, command, args,
    env_vars, auth_type, oauth_config, tags
) VALUES (
    $1, $2, $3, $4, $5, $6,
    $7, $8, $9, $10, $11, $12,
    $13, $14, $15, $16
)
RETURNING *;

-- name: GetMcpServerRegistry :one
SELECT * FROM mcp_server_registry WHERE id = $1 AND workspace_id = $2;

-- name: GetMcpServerRegistryBySlug :one
SELECT * FROM mcp_server_registry WHERE slug = $1 AND workspace_id = $2;

-- name: ListMcpServerRegistry :many
SELECT * FROM mcp_server_registry
WHERE workspace_id = $1
ORDER BY category ASC, name ASC;

-- name: ListMcpServerRegistryByCategory :many
SELECT * FROM mcp_server_registry
WHERE workspace_id = $1 AND category = $2
ORDER BY name ASC;

-- name: UpdateMcpServerRegistry :one
UPDATE mcp_server_registry SET
    name = COALESCE($3, name),
    description = COALESCE($4, description),
    server_url = COALESCE($5, server_url),
    transport = COALESCE($6, transport),
    command = COALESCE($7, command),
    args = COALESCE($8, args),
    env_vars = COALESCE($9, env_vars),
    auth_type = COALESCE($10, auth_type),
    oauth_config = COALESCE($11, oauth_config),
    updated_at = now()
WHERE id = $1 AND workspace_id = $2
RETURNING *;

-- name: DeleteMcpServerRegistry :exec
DELETE FROM mcp_server_registry WHERE id = $1 AND workspace_id = $2;

-- name: CountMcpServerRegistry :one
SELECT count(*) FROM mcp_server_registry WHERE workspace_id = $1;
