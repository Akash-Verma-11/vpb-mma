-- Owned by: catalog-service
CREATE TABLE products (
    product_id  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES categories(category_id),
    name        VARCHAR(200) NOT NULL,
    description TEXT,
    author      VARCHAR(150),                  -- nullable; only relevant for books
    sku         VARCHAR(50)  NOT NULL UNIQUE,
    price       NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_products_category ON products(category_id);
