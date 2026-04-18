package mcpclient

import (
	"context"
	"log/slog"

	"github.com/multica-ai/multica/server/pkg/agent"
)

// Pool manages multiple MCP client connections for a single session.
type Pool struct {
	clients map[string]*Client // server name → client
	// toolMap maps "server_name.tool_name" → client for routing
	toolMap map[string]*Client
	logger  *slog.Logger
}

// NewPool creates a pool and connects to all configured MCP servers.
func NewPool(ctx context.Context, configs []Config, logger *slog.Logger) (*Pool, error) {
	if logger == nil {
		logger = slog.Default()
	}
	pool := &Pool{
		clients: make(map[string]*Client),
		toolMap: make(map[string]*Client),
		logger:  logger,
	}

	for _, cfg := range configs {
		client, err := New(ctx, cfg, logger)
		if err != nil {
			logger.Warn("failed to connect MCP server, skipping", "server", cfg.Name, "error", err)
			continue
		}
		pool.clients[cfg.Name] = client

		// Register tools with namespaced names
		for _, t := range client.Tools() {
			toolKey := cfg.Name + "." + t.Name
			pool.toolMap[toolKey] = client
		}
	}

	return pool, nil
}

// Tools returns all MCP tools across all connected servers as Anthropic tool definitions.
func (p *Pool) Tools() []agent.McpToolDef {
	var tools []agent.McpToolDef
	for name, client := range p.clients {
		for _, t := range client.Tools() {
			tools = append(tools, agent.McpToolDef{
				Name:        name + "." + t.Name,
				ServerName:  name,
				ToolName:    t.Name,
				Description: t.Description,
				InputSchema: t.InputSchema,
			})
		}
	}
	return tools
}

// Execute calls an MCP tool. toolName must be "server_name.tool_name".
func (p *Pool) Execute(ctx context.Context, toolName string, args map[string]any) (string, error) {
	client, ok := p.toolMap[toolName]
	if !ok {
		return "", nil
	}
	// Extract just the tool name (after the server prefix)
	for _, c := range p.clients {
		if c == client {
			for _, t := range c.Tools() {
				if c.Name()+"."+t.Name == toolName {
					return c.CallTool(ctx, t.Name, args)
				}
			}
		}
	}
	return client.CallTool(ctx, toolName, args)
}

// HasTool checks if a tool name is an MCP tool.
func (p *Pool) HasTool(toolName string) bool {
	_, ok := p.toolMap[toolName]
	return ok
}

// Close disconnects all MCP servers.
func (p *Pool) Close() {
	for _, c := range p.clients {
		c.Close()
	}
}
