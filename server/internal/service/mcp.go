package service

import (
	"context"
	"encoding/json"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/multica-ai/multica/server/pkg/agent"
	db "github.com/multica-ai/multica/server/pkg/db/generated"
)

// LoadMcpServersForAgent fetches enabled MCP connectors from the DB and converts
// them into McpServerSpec entries suitable for agent.ExecOptions.
func LoadMcpServersForAgent(ctx context.Context, q *db.Queries, agentID, workspaceID pgtype.UUID) ([]agent.McpServerSpec, error) {
	connectors, err := q.ListEnabledAgentMcpConnectors(ctx, agentID, workspaceID)
	if err != nil {
		return nil, err
	}

	specs := make([]agent.McpServerSpec, 0, len(connectors))
	for _, c := range connectors {
		spec := agent.McpServerSpec{
			Name:      c.Name,
			Transport: c.Transport,
			Command:   c.Command,
			URL:       c.ServerUrl,
		}

		// Parse args from JSONB
		if c.Args != nil {
			var args []string
			if err := json.Unmarshal(c.Args, &args); err == nil {
				spec.Args = args
			}
		}

		// Parse env config from JSONB
		if c.EnvConfig != nil {
			var env map[string]string
			if err := json.Unmarshal(c.EnvConfig, &env); err == nil {
				spec.Env = env
			}
		}

		specs = append(specs, spec)
	}

	return specs, nil
}
