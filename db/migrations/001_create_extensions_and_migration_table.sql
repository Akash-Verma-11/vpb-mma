-- Enables gen_random_uuid()-style unique IDs and tracks which migrations
-- have already been applied (the runner checks this table before applying).
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS schema_migrations (
    filename    VARCHAR(255) PRIMARY KEY,
    applied_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
