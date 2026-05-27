-- Agents table
CREATE TABLE IF NOT EXISTS agents (
    id VARCHAR(100) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    agentic_framework VARCHAR(100),
    skills JSONB DEFAULT '[]'::jsonb,
    tools JSONB DEFAULT '[]'::jsonb,
    sub_agents JSONB DEFAULT '[]'::jsonb,
    external_agents JSONB DEFAULT '[]'::jsonb,
    models JSONB DEFAULT '[]'::jsonb,
    main_prompt TEXT
);

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id VARCHAR(100) PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    description TEXT,
    status VARCHAR(50) NOT NULL CHECK (status IN ('waiting_for_action', 'completed', 'partial')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    priority VARCHAR(20) NOT NULL CHECK (priority IN ('high', 'medium', 'low')),
    agent_id VARCHAR(100) NOT NULL REFERENCES agents(id),
    user_id VARCHAR(100),
    reasoning TEXT NOT NULL,
    outcome VARCHAR(20) CHECK (outcome IN ('accepted', 'rejected')),
    tokens_used INTEGER DEFAULT 0,
    request_count INTEGER DEFAULT 1,
    metadata JSONB
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_agent_id ON tasks(agent_id);
CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);