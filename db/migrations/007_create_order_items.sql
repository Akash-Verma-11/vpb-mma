-- Owned by: order-service
CREATE TABLE order_items (
    order_item_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id      UUID NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id    UUID NOT NULL REFERENCES products(product_id),
    quantity      INTEGER NOT NULL CHECK (quantity > 0),
    unit_price    NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0)
);

CREATE INDEX idx_order_items_order ON order_items(order_id);
