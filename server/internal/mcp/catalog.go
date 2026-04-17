package mcp

// BuiltinServer defines a pre-configured MCP server entry for the registry catalog.
type BuiltinServer struct {
	Slug        string   `json:"slug"`
	Name        string   `json:"name"`
	Description string   `json:"description"`
	Category    string   `json:"category"`
	RepoURL     string   `json:"repo_url"`
	Transport   string   `json:"transport"`  // "stdio" | "sse" | "streamable-http"
	Command     string   `json:"command"`     // npx command for stdio
	AuthType    string   `json:"auth_type"`   // "none" | "bearer" | "api_key" | "mcp_oauth" | "env_var"
	EnvVars     []EnvVar `json:"env_vars"`    // Required environment variables
	Tags        []string `json:"tags"`
}

// EnvVar describes a required environment variable for an MCP server.
type EnvVar struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	Required    bool   `json:"required"`
}

// Catalog returns the full list of built-in MCP servers.
// This is the 1-click registry — users pick a server and provide credentials.
func Catalog() []BuiltinServer {
	return []BuiltinServer{
		// ============ VERSION CONTROL ============
		{
			Slug: "github", Name: "GitHub", Category: "version_control",
			Description: "Access GitHub repos, issues, PRs, actions, and code search",
			RepoURL: "https://github.com/github/github-mcp-server", Transport: "stdio",
			Command: "npx -y @github/mcp-server", AuthType: "env_var",
			EnvVars: []EnvVar{{Name: "GITHUB_PERSONAL_ACCESS_TOKEN", Description: "GitHub PAT with repo scope", Required: true}},
			Tags:    []string{"git", "code", "pr", "issues"},
		},
		{
			Slug: "gitlab", Name: "GitLab", Category: "version_control",
			Description: "Manage GitLab projects, merge requests, and pipelines",
			RepoURL: "https://github.com/modelcontextprotocol/servers/tree/main/src/gitlab", Transport: "stdio",
			Command: "npx -y @modelcontextprotocol/server-gitlab", AuthType: "env_var",
			EnvVars: []EnvVar{
				{Name: "GITLAB_PERSONAL_ACCESS_TOKEN", Description: "GitLab PAT", Required: true},
				{Name: "GITLAB_API_URL", Description: "GitLab API URL (default: https://gitlab.com/api/v4)", Required: false},
			},
			Tags: []string{"git", "merge-request", "ci"},
		},
		{
			Slug: "git", Name: "Git", Category: "version_control",
			Description: "Local git operations — clone, commit, diff, log, branch",
			RepoURL: "https://github.com/modelcontextprotocol/servers/tree/main/src/git", Transport: "stdio",
			Command: "npx -y @modelcontextprotocol/server-git", AuthType: "none",
			Tags: []string{"git", "local", "diff"},
		},
		{
			Slug: "linear", Name: "Linear", Category: "version_control",
			Description: "Create and manage Linear issues, projects, and cycles",
			RepoURL: "https://github.com/linear/linear-mcp-server", Transport: "stdio",
			Command: "npx -y @linear/mcp-server", AuthType: "env_var",
			EnvVars: []EnvVar{{Name: "LINEAR_API_KEY", Description: "Linear API key", Required: true}},
			Tags:    []string{"issues", "project-management"},
		},

		// ============ DATABASES ============
		{
			Slug: "postgres", Name: "PostgreSQL", Category: "database",
			Description: "Query and manage PostgreSQL databases",
			RepoURL: "https://github.com/modelcontextprotocol/servers/tree/main/src/postgres", Transport: "stdio",
			Command: "npx -y @modelcontextprotocol/server-postgres", AuthType: "env_var",
			EnvVars: []EnvVar{{Name: "DATABASE_URL", Description: "PostgreSQL connection string", Required: true}},
			Tags:    []string{"sql", "relational"},
		},
		{
			Slug: "sqlite", Name: "SQLite", Category: "database",
			Description: "Read and query SQLite databases",
			RepoURL: "https://github.com/modelcontextprotocol/servers/tree/main/src/sqlite", Transport: "stdio",
			Command: "npx -y @modelcontextprotocol/server-sqlite", AuthType: "none",
			Tags: []string{"sql", "embedded", "local"},
		},
		{
			Slug: "mysql", Name: "MySQL", Category: "database",
			Description: "Query and manage MySQL databases",
			RepoURL: "https://github.com/designcomputer/mysql_mcp_server", Transport: "stdio",
			Command: "npx -y mysql-mcp-server", AuthType: "env_var",
			EnvVars: []EnvVar{
				{Name: "MYSQL_HOST", Description: "MySQL host", Required: true},
				{Name: "MYSQL_USER", Description: "MySQL user", Required: true},
				{Name: "MYSQL_PASSWORD", Description: "MySQL password", Required: true},
				{Name: "MYSQL_DATABASE", Description: "MySQL database name", Required: true},
			},
			Tags: []string{"sql", "relational"},
		},
		{
			Slug: "mongodb", Name: "MongoDB", Category: "database",
			Description: "Query and manage MongoDB collections",
			RepoURL: "https://github.com/kiliczsh/mcp-mongo-server", Transport: "stdio",
			Command: "npx -y mcp-mongo-server", AuthType: "env_var",
			EnvVars: []EnvVar{{Name: "MONGODB_URI", Description: "MongoDB connection URI", Required: true}},
			Tags:    []string{"nosql", "document"},
		},
		{
			Slug: "redis", Name: "Redis", Category: "database",
			Description: "Interact with Redis key-value stores",
			RepoURL: "https://github.com/redis/mcp-redis", Transport: "stdio",
			Command: "npx -y @redis/mcp-server", AuthType: "env_var",
			EnvVars: []EnvVar{{Name: "REDIS_URL", Description: "Redis connection URL", Required: true}},
			Tags:    []string{"cache", "key-value"},
		},
		{
			Slug: "qdrant", Name: "Qdrant", Category: "database",
			Description: "Vector search and semantic retrieval with Qdrant",
			RepoURL: "https://github.com/qdrant/mcp-server-qdrant", Transport: "stdio",
			Command: "npx -y @qdrant/mcp-server-qdrant", AuthType: "env_var",
			EnvVars: []EnvVar{
				{Name: "QDRANT_URL", Description: "Qdrant server URL", Required: true},
				{Name: "QDRANT_API_KEY", Description: "Qdrant API key", Required: false},
			},
			Tags: []string{"vector", "embeddings", "search"},
		},
		{
			Slug: "supabase", Name: "Supabase", Category: "database",
			Description: "Manage Supabase projects, tables, edge functions, and auth",
			RepoURL: "https://github.com/supabase-community/supabase-mcp", Transport: "stdio",
			Command: "npx -y supabase-mcp-server", AuthType: "env_var",
			EnvVars: []EnvVar{
				{Name: "SUPABASE_URL", Description: "Supabase project URL", Required: true},
				{Name: "SUPABASE_SERVICE_ROLE_KEY", Description: "Supabase service role key", Required: true},
			},
			Tags: []string{"postgres", "auth", "storage", "edge-functions"},
		},
		{
			Slug: "neon", Name: "Neon", Category: "database",
			Description: "Manage Neon serverless Postgres — branches, queries, schemas",
			RepoURL: "https://github.com/neondatabase/mcp-server-neon", Transport: "stdio",
			Command: "npx -y @neondatabase/mcp-server-neon", AuthType: "env_var",
			EnvVars: []EnvVar{{Name: "NEON_API_KEY", Description: "Neon API key", Required: true}},
			Tags:    []string{"postgres", "serverless", "branching"},
		},

		// ============ COMMUNICATION ============
		{
			Slug: "slack", Name: "Slack", Category: "communication",
			Description: "Send messages, read channels, search Slack workspace",
			RepoURL: "https://github.com/modelcontextprotocol/servers/tree/main/src/slack", Transport: "stdio",
			Command: "npx -y @modelcontextprotocol/server-slack", AuthType: "env_var",
			EnvVars: []EnvVar{{Name: "SLACK_BOT_TOKEN", Description: "Slack Bot OAuth token (xoxb-...)", Required: true}},
			Tags:    []string{"chat", "messaging", "team"},
		},
		{
			Slug: "gmail", Name: "Gmail", Category: "communication",
			Description: "Read, search, send, and manage Gmail messages",
			RepoURL: "https://github.com/googleworkspace/mcp-servers", Transport: "stdio",
			Command: "npx -y @google/gmail-mcp-server", AuthType: "mcp_oauth",
			Tags: []string{"email", "google"},
		},
		{
			Slug: "notion", Name: "Notion", Category: "communication",
			Description: "Search, read, and update Notion pages and databases",
			RepoURL: "https://github.com/makenotion/notion-mcp-server", Transport: "stdio",
			Command: "npx -y @notionhq/notion-mcp-server", AuthType: "env_var",
			EnvVars: []EnvVar{{Name: "NOTION_API_KEY", Description: "Notion integration token", Required: true}},
			Tags:    []string{"wiki", "docs", "knowledge-base"},
		},
		{
			Slug: "discord", Name: "Discord", Category: "communication",
			Description: "Send messages, manage channels and servers on Discord",
			RepoURL: "https://github.com/v-3/discordmcp", Transport: "stdio",
			Command: "npx -y discord-mcp", AuthType: "env_var",
			EnvVars: []EnvVar{{Name: "DISCORD_BOT_TOKEN", Description: "Discord bot token", Required: true}},
			Tags:    []string{"chat", "community"},
		},

		// ============ SEARCH & WEB ============
		{
			Slug: "brave-search", Name: "Brave Search", Category: "search",
			Description: "Web and local search using Brave Search API",
			RepoURL: "https://github.com/modelcontextprotocol/servers/tree/main/src/brave-search", Transport: "stdio",
			Command: "npx -y @modelcontextprotocol/server-brave-search", AuthType: "env_var",
			EnvVars: []EnvVar{{Name: "BRAVE_API_KEY", Description: "Brave Search API key", Required: true}},
			Tags:    []string{"web", "search"},
		},
		{
			Slug: "fetch", Name: "Fetch", Category: "search",
			Description: "Fetch and convert web pages to markdown for LLM consumption",
			RepoURL: "https://github.com/modelcontextprotocol/servers/tree/main/src/fetch", Transport: "stdio",
			Command: "npx -y @modelcontextprotocol/server-fetch", AuthType: "none",
			Tags: []string{"web", "scraping", "markdown"},
		},
		{
			Slug: "exa", Name: "Exa", Category: "search",
			Description: "Neural search engine — semantic web search and content retrieval",
			RepoURL: "https://github.com/exa-labs/exa-mcp-server", Transport: "stdio",
			Command: "npx -y exa-mcp-server", AuthType: "env_var",
			EnvVars: []EnvVar{{Name: "EXA_API_KEY", Description: "Exa API key", Required: true}},
			Tags:    []string{"search", "semantic", "ai"},
		},
		{
			Slug: "firecrawl", Name: "Firecrawl", Category: "search",
			Description: "Crawl websites and extract structured data",
			RepoURL: "https://github.com/mendableai/firecrawl-mcp-server", Transport: "stdio",
			Command: "npx -y firecrawl-mcp-server", AuthType: "env_var",
			EnvVars: []EnvVar{{Name: "FIRECRAWL_API_KEY", Description: "Firecrawl API key", Required: true}},
			Tags:    []string{"crawl", "scraping", "extraction"},
		},

		// ============ SANDBOX & EXECUTION ============
		{
			Slug: "e2b", Name: "E2B", Category: "sandbox",
			Description: "Run code in cloud sandboxes — Python, JS, shell, file I/O",
			RepoURL: "https://github.com/e2b-dev/mcp-server", Transport: "stdio",
			Command: "npx -y @e2b/mcp-server", AuthType: "env_var",
			EnvVars: []EnvVar{{Name: "E2B_API_KEY", Description: "E2B API key", Required: true}},
			Tags:    []string{"sandbox", "code-execution", "cloud"},
		},
		{
			Slug: "microsandbox", Name: "Microsandbox", Category: "sandbox",
			Description: "Self-hosted sandboxed code execution environment",
			RepoURL: "https://github.com/microsandbox/microsandbox", Transport: "stdio",
			Command: "npx -y microsandbox-mcp", AuthType: "none",
			Tags: []string{"sandbox", "self-hosted", "code-execution"},
		},
		{
			Slug: "docker", Name: "Docker", Category: "sandbox",
			Description: "Manage Docker containers, images, and volumes",
			RepoURL: "https://github.com/QuantGeekDev/docker-mcp", Transport: "stdio",
			Command: "npx -y docker-mcp-server", AuthType: "none",
			Tags: []string{"containers", "devops"},
		},

		// ============ CLOUD & DEVOPS ============
		{
			Slug: "aws", Name: "AWS", Category: "cloud",
			Description: "Manage AWS resources — S3, Lambda, EC2, CloudFormation",
			RepoURL: "https://github.com/awslabs/mcp", Transport: "stdio",
			Command: "npx -y @awslabs/mcp-server-aws", AuthType: "env_var",
			EnvVars: []EnvVar{
				{Name: "AWS_ACCESS_KEY_ID", Description: "AWS access key", Required: true},
				{Name: "AWS_SECRET_ACCESS_KEY", Description: "AWS secret key", Required: true},
				{Name: "AWS_REGION", Description: "AWS region (default: us-east-1)", Required: false},
			},
			Tags: []string{"cloud", "infrastructure"},
		},
		{
			Slug: "cloudflare", Name: "Cloudflare", Category: "cloud",
			Description: "Manage Cloudflare Workers, KV, R2, D1, and DNS",
			RepoURL: "https://github.com/cloudflare/mcp-server-cloudflare", Transport: "stdio",
			Command: "npx -y @cloudflare/mcp-server-cloudflare", AuthType: "env_var",
			EnvVars: []EnvVar{{Name: "CLOUDFLARE_API_TOKEN", Description: "Cloudflare API token", Required: true}},
			Tags:    []string{"cdn", "workers", "edge"},
		},
		{
			Slug: "vercel", Name: "Vercel", Category: "cloud",
			Description: "Manage Vercel deployments, domains, and environment variables",
			RepoURL: "https://github.com/vercel/vercel-mcp-server", Transport: "stdio",
			Command: "npx -y @vercel/mcp-server", AuthType: "env_var",
			EnvVars: []EnvVar{{Name: "VERCEL_API_TOKEN", Description: "Vercel API token", Required: true}},
			Tags:    []string{"deployment", "serverless", "frontend"},
		},
		{
			Slug: "kubernetes", Name: "Kubernetes", Category: "cloud",
			Description: "Manage Kubernetes clusters, pods, services, and deployments",
			RepoURL: "https://github.com/strowk/mcp-k8s-go", Transport: "stdio",
			Command: "npx -y mcp-k8s", AuthType: "none",
			Tags: []string{"k8s", "containers", "orchestration"},
		},
		{
			Slug: "terraform", Name: "Terraform", Category: "cloud",
			Description: "Plan, apply, and manage Terraform infrastructure",
			RepoURL: "https://github.com/hashicorp/terraform-mcp-server", Transport: "stdio",
			Command: "npx -y @hashicorp/terraform-mcp-server", AuthType: "none",
			Tags: []string{"iac", "infrastructure"},
		},
		{
			Slug: "pulumi", Name: "Pulumi", Category: "cloud",
			Description: "Manage Pulumi stacks, resources, and deployments",
			RepoURL: "https://github.com/pulumi/mcp-server", Transport: "stdio",
			Command: "npx -y @pulumi/mcp-server", AuthType: "env_var",
			EnvVars: []EnvVar{{Name: "PULUMI_ACCESS_TOKEN", Description: "Pulumi access token", Required: true}},
			Tags:    []string{"iac", "infrastructure"},
		},

		// ============ MONITORING ============
		{
			Slug: "sentry", Name: "Sentry", Category: "monitoring",
			Description: "Query errors, performance data, and releases in Sentry",
			RepoURL: "https://github.com/getsentry/sentry-mcp", Transport: "stdio",
			Command: "npx -y @sentry/mcp-server", AuthType: "env_var",
			EnvVars: []EnvVar{{Name: "SENTRY_AUTH_TOKEN", Description: "Sentry auth token", Required: true}},
			Tags:    []string{"errors", "performance", "observability"},
		},
		{
			Slug: "datadog", Name: "Datadog", Category: "monitoring",
			Description: "Query metrics, logs, traces, and monitors in Datadog",
			RepoURL: "https://github.com/DataDog/datadog-mcp-server", Transport: "stdio",
			Command: "npx -y @datadog/mcp-server", AuthType: "env_var",
			EnvVars: []EnvVar{
				{Name: "DD_API_KEY", Description: "Datadog API key", Required: true},
				{Name: "DD_APP_KEY", Description: "Datadog application key", Required: true},
			},
			Tags: []string{"metrics", "logs", "apm"},
		},
		{
			Slug: "grafana", Name: "Grafana", Category: "monitoring",
			Description: "Query dashboards, datasources, and alerts in Grafana",
			RepoURL: "https://github.com/grafana/mcp-grafana", Transport: "stdio",
			Command: "npx -y @grafana/mcp-server", AuthType: "env_var",
			EnvVars: []EnvVar{
				{Name: "GRAFANA_URL", Description: "Grafana instance URL", Required: true},
				{Name: "GRAFANA_API_KEY", Description: "Grafana API key or service account token", Required: true},
			},
			Tags: []string{"dashboards", "visualization", "alerting"},
		},

		// ============ PRODUCTIVITY ============
		{
			Slug: "jira", Name: "Jira", Category: "productivity",
			Description: "Create and manage Jira issues, boards, and sprints",
			RepoURL: "https://github.com/atlassian/jira-mcp-server", Transport: "stdio",
			Command: "npx -y @atlassian/jira-mcp-server", AuthType: "env_var",
			EnvVars: []EnvVar{
				{Name: "JIRA_URL", Description: "Jira instance URL", Required: true},
				{Name: "JIRA_EMAIL", Description: "Jira email", Required: true},
				{Name: "JIRA_API_TOKEN", Description: "Jira API token", Required: true},
			},
			Tags: []string{"issues", "agile", "project-management"},
		},
		{
			Slug: "asana", Name: "Asana", Category: "productivity",
			Description: "Manage Asana tasks, projects, and workspaces",
			RepoURL: "https://github.com/Asana/asana-mcp-server", Transport: "stdio",
			Command: "npx -y @asana/mcp-server", AuthType: "env_var",
			EnvVars: []EnvVar{{Name: "ASANA_ACCESS_TOKEN", Description: "Asana personal access token", Required: true}},
			Tags:    []string{"tasks", "project-management"},
		},
		{
			Slug: "google-calendar", Name: "Google Calendar", Category: "productivity",
			Description: "Read and manage Google Calendar events",
			RepoURL: "https://github.com/googleworkspace/mcp-servers", Transport: "stdio",
			Command: "npx -y @google/calendar-mcp-server", AuthType: "mcp_oauth",
			Tags: []string{"calendar", "scheduling", "google"},
		},
		{
			Slug: "todoist", Name: "Todoist", Category: "productivity",
			Description: "Manage Todoist tasks, projects, and labels",
			RepoURL: "https://github.com/doist/todoist-mcp", Transport: "stdio",
			Command: "npx -y @doist/todoist-mcp-server", AuthType: "env_var",
			EnvVars: []EnvVar{{Name: "TODOIST_API_TOKEN", Description: "Todoist API token", Required: true}},
			Tags:    []string{"tasks", "todo"},
		},

		// ============ BROWSER & AUTOMATION ============
		{
			Slug: "playwright", Name: "Playwright", Category: "browser",
			Description: "Browser automation — navigate, click, fill forms, screenshot",
			RepoURL: "https://github.com/microsoft/playwright-mcp", Transport: "stdio",
			Command: "npx -y @playwright/mcp-server", AuthType: "none",
			Tags: []string{"browser", "testing", "automation"},
		},
		{
			Slug: "browser-use", Name: "Browser Use", Category: "browser",
			Description: "AI-driven browser automation with visual understanding",
			RepoURL: "https://github.com/browser-use/browser-use", Transport: "stdio",
			Command: "npx -y browser-use-mcp", AuthType: "none",
			Tags: []string{"browser", "ai", "vision"},
		},
		{
			Slug: "puppeteer", Name: "Puppeteer", Category: "browser",
			Description: "Headless Chrome automation — scrape, screenshot, PDF",
			RepoURL: "https://github.com/modelcontextprotocol/servers/tree/main/src/puppeteer", Transport: "stdio",
			Command: "npx -y @modelcontextprotocol/server-puppeteer", AuthType: "none",
			Tags: []string{"browser", "headless", "scraping"},
		},

		// ============ MEMORY & KNOWLEDGE ============
		{
			Slug: "memory", Name: "Memory", Category: "memory",
			Description: "Persistent memory via knowledge graph — entities and relations",
			RepoURL: "https://github.com/modelcontextprotocol/servers/tree/main/src/memory", Transport: "stdio",
			Command: "npx -y @modelcontextprotocol/server-memory", AuthType: "none",
			Tags: []string{"knowledge-graph", "persistence"},
		},
		{
			Slug: "graphiti", Name: "Graphiti (Zep)", Category: "memory",
			Description: "Temporal knowledge graphs for agent memory and retrieval",
			RepoURL: "https://github.com/getzep/graphiti", Transport: "stdio",
			Command: "npx -y graphiti-mcp-server", AuthType: "env_var",
			EnvVars: []EnvVar{{Name: "ZEP_API_KEY", Description: "Zep API key", Required: true}},
			Tags:    []string{"knowledge-graph", "temporal", "rag"},
		},
		{
			Slug: "context7", Name: "Context7", Category: "memory",
			Description: "Up-to-date library docs and code examples for any package",
			RepoURL: "https://github.com/upstash/context7", Transport: "stdio",
			Command: "npx -y context7-mcp-server", AuthType: "none",
			Tags: []string{"docs", "libraries", "knowledge"},
		},

		// ============ FINANCE ============
		{
			Slug: "stripe", Name: "Stripe", Category: "finance",
			Description: "Manage Stripe payments, customers, subscriptions, and invoices",
			RepoURL: "https://github.com/stripe/agent-toolkit", Transport: "stdio",
			Command: "npx -y @stripe/mcp-server", AuthType: "env_var",
			EnvVars: []EnvVar{{Name: "STRIPE_SECRET_KEY", Description: "Stripe secret key (sk_...)", Required: true}},
			Tags:    []string{"payments", "billing", "subscriptions"},
		},
	}
}
