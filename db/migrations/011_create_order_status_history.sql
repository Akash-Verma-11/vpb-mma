-- Owned by: order-service. Powers the customer-facing tracking view.
CREATE TABLE order_status_history (
    history_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id   UUID NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    status     VARCHAR(20) NOT NULL,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_order_status_history_order ON order_status_history(order_id);
