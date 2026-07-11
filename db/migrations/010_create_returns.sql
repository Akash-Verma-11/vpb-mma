-- Owned by: order-service
CREATE TABLE returns (
    return_id     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_item_id UUID NOT NULL REFERENCES order_items(order_item_id),
    quantity      INTEGER NOT NULL CHECK (quantity > 0),
    reason        TEXT,
    refund_status VARCHAR(20) NOT NULL DEFAULT 'Pending'
                  CHECK (refund_status IN ('Pending', 'Approved', 'Rejected', 'Refunded')),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
