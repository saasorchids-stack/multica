-- name: CreateSessionThread :one
INSERT INTO session_thread (session_id, agent_id, agent_name, status)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: ListSessionThreads :many
SELECT * FROM session_thread
WHERE session_id = $1
ORDER BY created_at ASC;

-- name: UpdateSessionThreadStatus :exec
UPDATE session_thread SET status = $2 WHERE id = $1;
