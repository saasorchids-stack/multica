-- name: GetMemoryStore :one
SELECT * FROM memory_store WHERE id = $1;

-- name: GetMemoryStoreInWorkspace :one
SELECT * FROM memory_store WHERE id = $1 AND workspace_id = $2;

-- name: ListMemoryStores :many
SELECT * FROM memory_store
WHERE workspace_id = $1 AND archived_at IS NULL
ORDER BY created_at DESC;

-- name: CreateMemoryStore :one
INSERT INTO memory_store (workspace_id, name, description)
VALUES ($1, $2, $3)
RETURNING *;

-- name: UpdateMemoryStore :one
UPDATE memory_store SET
    name = COALESCE(NULLIF($2, ''), name),
    description = COALESCE($3, description)
WHERE id = $1
RETURNING *;

-- name: ArchiveMemoryStore :exec
UPDATE memory_store SET archived_at = now() WHERE id = $1;

-- name: GetMemory :one
SELECT * FROM memory WHERE id = $1;

-- name: GetMemoryByPath :one
SELECT * FROM memory WHERE store_id = $1 AND path = $2;

-- name: ListMemories :many
SELECT * FROM memory
WHERE store_id = $1
ORDER BY path ASC
LIMIT $2 OFFSET $3;

-- name: CreateMemory :one
INSERT INTO memory (store_id, path, content, content_sha256, content_size_bytes)
VALUES ($1, $2, $3, $4, $5)
RETURNING *;

-- name: UpdateMemory :one
UPDATE memory SET
    content = $2,
    content_sha256 = $3,
    content_size_bytes = $4,
    updated_at = now()
WHERE id = $1
RETURNING *;

-- name: DeleteMemory :exec
DELETE FROM memory WHERE id = $1;

-- name: CreateMemoryVersion :one
INSERT INTO memory_version (memory_id, store_id, operation, content, content_sha256, content_size_bytes, path, session_id)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
RETURNING *;

-- name: ListMemoryVersions :many
SELECT * FROM memory_version
WHERE store_id = $1
ORDER BY created_at DESC
LIMIT $2 OFFSET $3;

-- name: ListMemoryVersionsByPath :many
SELECT * FROM memory_version
WHERE store_id = $1 AND path = $2
ORDER BY created_at DESC
LIMIT $3 OFFSET $4;

-- name: RedactMemoryVersion :exec
UPDATE memory_version SET
    content = NULL,
    redacted_at = now()
WHERE id = $1;
