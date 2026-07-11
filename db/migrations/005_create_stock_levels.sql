-- Owned by: catalog-service. One row per product, kept in sync by a
-- trigger on stock_movements (see 012_create_stock_triggers.sql).
CREATE TABLE stock_levels (
    product_id        UUID PRIMARY KEY REFERENCES products(product_id),
    quantity_on_hand  INTEGER NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0),
    reorder_threshold INTEGER NOT NULL DEFAULT 5,
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
