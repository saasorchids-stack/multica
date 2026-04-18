-- name: GetManagedSession :one
SELECT * FROM managed_session WHERE id = $1;

-- name: GetManagedSessionInWorkspace :one
SELECT * FROM managed_session WHERE id = $1 AND workspace_id = $2;

-- name: ListManagedSessions :many
SELECT * FROM managed_session
WHERE workspace_id = $1 AND archived_at IS NULL
ORDER BY created_at DESC
LIMIT $2 OFFSET $3;

-- name: ListManagedSessionsByAgent :many
SELECT * FROM managed_session
WHERE agent_id = $1 AND archived_at IS NULL
ORDER BY created_at DESC
LIMIT $2 OFFSET $3;

-- name: CreateManagedSession :one
INSERT INTO managed_session (workspace_id, agent_id, agent_version, environment_id, vault_ids, title)
VALUES ($1, $2, $3, $4, $5, $6)
RETURNING *;

-- name: UpdateManagedSessionStatus :one
UPDATE managed_session SET
    status = $2,
    updated_at = now()
WHERE id = $1
RETURNING *;

-- name: UpdateManagedSessionUsage :exec
UPDATE managed_session SET
    usage_input_tokens = usage_input_tokens + $2,
    usage_output_tokens = usage_output_tokens + $3,
    usage_cache_creation_tokens = usage_cache_creation_tokens + $4,
    usage_cache_read_tokens = usage_cache_read_tokens + $5,
    updated_at = now()
WHERE id = $1;

-- name: SetManagedSessionStopReason :exec
UPDATE managed_session SET
    stop_reason = $2,
    updated_at = now()
WHERE id = $1;

-- name: ArchiveManagedSession :exec
UPDATE managed_session SET
    archived_at = now(),
    updated_at = now()
WHERE id = $1;

-- name: SetManagedSessionTitle :exec
UPDATE managed_session SET
    title = $2,
    updated_at = now()
WHERE id = $1;

-- name: AddManagedSessionResource :one
UPDATE managed_session SET
    resources = resources || $2::jsonb,
    updated_at = now()
WHERE id = $1
RETURNING *;

-- name: SetManagedSessionResources :one
UPDATE managed_session SET
    resources = $2::jsonb,
    updated_at = now()
WHERE id = $1
RETURNING *;

-- name: DeleteManagedSession :exec
DELETE FROM managed_session WHERE id = $1;

-- name: TerminateManagedSession :exec
UPDATE managed_session SET
    status = 'terminated',
    stop_reason = $2,
    updated_at = now()
WHERE id = $1;
