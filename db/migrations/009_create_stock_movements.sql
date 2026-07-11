-- Owned by: catalog-service. Central ledger — every sale, purchase, and
-- return is one row here. quantity is negative for sales, positive for
-- purchases and returns.
CREATE TABLE stock_movements (
    movement_id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id             UUID NOT NULL REFERENCES products(product_id),
    movement_type          VARCHAR(10) NOT NULL CHECK (movement_type IN ('sale', 'purchase', 'return')),
    quantity               INTEGER NOT NULL,
    reference_order_id     UUID REFERENCES orders(order_id),
    reference_purchase_id  UUID REFERENCES purchases(purchase_id),
    note                   TEXT,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_stock_movements_product ON stock_movements(product_id);
