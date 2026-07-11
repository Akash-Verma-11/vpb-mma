-- Owned by: order-service
CREATE TABLE orders (
    order_id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id    UUID NOT NULL REFERENCES customers(customer_id),
    status         VARCHAR(20) NOT NULL DEFAULT 'Placed'
                   CHECK (status IN ('Placed', 'Packed', 'Shipped', 'Delivered', 'Cancelled')),
    total_amount   NUMERIC(10,2) NOT NULL DEFAULT 0,
    payment_method VARCHAR(20) NOT NULL DEFAULT 'COD'
                   CHECK (payment_method IN ('COD', 'MOCK_GATEWAY')),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_orders_customer ON orders(customer_id);
