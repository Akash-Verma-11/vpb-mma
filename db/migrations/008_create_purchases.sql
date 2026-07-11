-- Owned by: catalog-service (supplier restocks)
CREATE TABLE purchases (
    purchase_id   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id    UUID NOT NULL REFERENCES products(product_id),
    supplier_name VARCHAR(150),
    quantity      INTEGER NOT NULL CHECK (quantity > 0),
    unit_cost     NUMERIC(10,2) NOT NULL CHECK (unit_cost >= 0),
    purchased_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
