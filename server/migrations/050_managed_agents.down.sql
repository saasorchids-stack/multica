-- 050_managed_agents: Rollback all Managed Agents tables.

BEGIN;

DROP TABLE IF EXISTS session_thread;
DROP TABLE IF EXISTS vault_credential;
DROP TABLE IF EXISTS vault;
DROP TABLE IF EXISTS memory_version;
DROP TABLE IF EXISTS memory;
DROP TABLE IF EXISTS memory_store;
DROP TABLE IF EXISTS session_event;
DROP TABLE IF EXISTS managed_session;
DROP TABLE IF EXISTS environment;
DROP TABLE IF EXISTS managed_agent_version;
DROP TABLE IF EXISTS managed_agent;

COMMIT;
