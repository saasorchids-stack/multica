-- name: CreateCostEvent :one
INSERT INTO cost_event (
    session_id, workspace_id, provider, model, operation,
    tokens_input, tokens_output, tokens_cached,
    cost_usd, duration_ms, tool_name, event_index
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
RETURNING *;

-- name: GetSessionCost :one
SELECT
    COALESCE(SUM(cost_usd), 0)::NUMERIC(12,8) AS total_cost,
    COALESCE(SUM(tokens_input), 0)::BIGINT AS total_input,
    COALESCE(SUM(tokens_output), 0)::BIGINT AS total_output,
    COALESCE(SUM(tokens_cached), 0)::BIGINT AS total_cached,
    COUNT(*)::INT AS event_count
FROM cost_event
WHERE session_id = $1;

-- name: GetSessionCostByOperation :many
SELECT
    operation,
    COALESCE(SUM(cost_usd), 0)::NUMERIC(12,8) AS total_cost,
    COUNT(*)::INT AS call_count,
    COALESCE(SUM(tokens_input), 0)::BIGINT AS total_input,
    COALESCE(SUM(tokens_output), 0)::BIGINT AS total_output
FROM cost_event
WHERE session_id = $1
GROUP BY operation
ORDER BY total_cost DESC;

-- name: GetSessionCostByTool :many
SELECT
    tool_name,
    COALESCE(SUM(cost_usd), 0)::NUMERIC(12,8) AS total_cost,
    COUNT(*)::INT AS call_count,
    COALESCE(SUM(duration_ms), 0)::INT AS total_duration_ms
FROM cost_event
WHERE session_id = $1 AND tool_name IS NOT NULL
GROUP BY tool_name
ORDER BY total_cost DESC;

-- name: GetWorkspaceCostPeriod :one
SELECT
    COALESCE(SUM(cost_usd), 0)::NUMERIC(12,8) AS total_cost,
    COALESCE(SUM(tokens_input), 0)::BIGINT AS total_input,
    COALESCE(SUM(tokens_output), 0)::BIGINT AS total_output,
    COUNT(DISTINCT session_id)::INT AS session_count,
    COUNT(*)::INT AS event_count
FROM cost_event
WHERE workspace_id = $1
  AND created_at >= $2
  AND created_at < $3;

-- name: GetWorkspaceCostByProvider :many
SELECT
    provider,
    model,
    COALESCE(SUM(cost_usd), 0)::NUMERIC(12,8) AS total_cost,
    COALESCE(SUM(tokens_input), 0)::BIGINT AS total_input,
    COALESCE(SUM(tokens_output), 0)::BIGINT AS total_output,
    COUNT(*)::INT AS event_count
FROM cost_event
WHERE workspace_id = $1
  AND created_at >= $2
  AND created_at < $3
GROUP BY provider, model
ORDER BY total_cost DESC;

-- name: GetWorkspaceDailyCost :many
SELECT
    DATE(created_at) AS day,
    COALESCE(SUM(cost_usd), 0)::NUMERIC(12,8) AS total_cost,
    COUNT(DISTINCT session_id)::INT AS session_count
FROM cost_event
WHERE workspace_id = $1
  AND created_at >= $2
  AND created_at < $3
GROUP BY DATE(created_at)
ORDER BY day;

-- name: ListCostEvents :many
SELECT * FROM cost_event
WHERE session_id = $1
ORDER BY created_at ASC
LIMIT $2 OFFSET $3;
