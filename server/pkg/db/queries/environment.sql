-- name: GetEnvironment :one
SELECT * FROM environment WHERE id = $1;

-- name: GetEnvironmentInWorkspace :one
SELECT * FROM environment WHERE id = $1 AND workspace_id = $2;

-- name: ListEnvironments :many
SELECT * FROM environment
WHERE workspace_id = $1 AND archived_at IS NULL
ORDER BY created_at DESC;

-- name: CreateEnvironment :one
INSERT INTO environment (workspace_id, name, config)
VALUES ($1, $2, $3)
RETURNING *;

-- name: UpdateEnvironment :one
UPDATE environment SET
    name = COALESCE(NULLIF($2, ''), name),
    config = COALESCE($3, config)
WHERE id = $1
RETURNING *;

-- name: ArchiveEnvironment :exec
UPDATE environment SET archived_at = now() WHERE id = $1;

-- name: DeleteEnvironment :exec
DELETE FROM environment WHERE id = $1;
