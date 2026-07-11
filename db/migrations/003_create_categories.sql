-- Owned by: catalog-service
CREATE TABLE categories (
    category_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        VARCHAR(100) NOT NULL UNIQUE,
    type        VARCHAR(20)  NOT NULL CHECK (type IN ('book', 'stationery')),
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);
