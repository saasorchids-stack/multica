-- 051_mcp_servers.down.sql
BEGIN;
DROP TABLE IF EXISTS agent_mcp_connector;
DROP TABLE IF EXISTS mcp_server_registry;
COMMIT;
