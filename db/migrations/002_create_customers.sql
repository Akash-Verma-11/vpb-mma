-- Owned by: customer-service
CREATE TABLE customers (
    customer_id  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name         VARCHAR(150) NOT NULL,
    phone_number VARCHAR(20)  NOT NULL UNIQUE,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX idx_customers_phone ON customers(phone_number);
