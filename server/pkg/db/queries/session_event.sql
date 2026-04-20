-- name: CreateSessionEvent :one
INSERT INTO session_event (session_id, thread_id, type, payload)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: CreateSessionEventWithIndex :one
INSERT INTO session_event (session_id, thread_id, type, payload, event_index, metadata)
VALUES ($1, $2, $3, $4, $5, $6)
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

-- name: GetSessionEventsSlice :many
-- Positional slice: getEvents(sessionId, fromIndex, toIndex)
-- Implements the core Managed Agents session interface.
SELECT * FROM session_event
WHERE session_id = $1
  AND event_index >= $2
  AND event_index < $3
ORDER BY event_index ASC;

-- name: GetSessionEventsByType :many
-- Filter events by type within an index range.
SELECT * FROM session_event
WHERE session_id = $1
  AND event_index >= $2
  AND event_index < $3
  AND type = ANY($4::TEXT[])
ORDER BY event_index ASC;

-- name: GetSessionMaxEventIndex :one
-- Returns the highest event_index for a session (used for wake/recovery).
SELECT COALESCE(MAX(event_index), -1)::INT AS max_index
FROM session_event
WHERE session_id = $1;

-- name: GetSessionEventCount :one
SELECT COUNT(*)::INT AS count FROM session_event WHERE session_id = $1;

-- name: GetLastContextReset :one
-- Find the most recent context_reset event (for resume after compaction).
SELECT * FROM session_event
WHERE session_id = $1 AND type = 'context_reset'
ORDER BY event_index DESC
LIMIT 1;

-- name: MarkSessionEventProcessed :exec
UPDATE session_event SET processed_at = now() WHERE id = $1;
