-- name: CreateSessionEvent :one
INSERT INTO session_event (session_id, thread_id, type, payload)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: ListSessionEvents :many
SELECT * FROM session_event
WHERE session_id = $1
ORDER BY created_at ASC
LIMIT $2 OFFSET $3;

-- name: ListSessionEventsSince :many
SELECT * FROM session_event
WHERE session_id = $1 AND created_at > $2
ORDER BY created_at ASC
LIMIT $3;

-- name: ListSessionEventsByThread :many
SELECT * FROM session_event
WHERE session_id = $1 AND thread_id = $2
ORDER BY created_at ASC;

-- name: MarkSessionEventProcessed :exec
UPDATE session_event SET processed_at = now() WHERE id = $1;
