-- Keeps stock_levels.quantity_on_hand automatically in sync whenever a
-- row is inserted into stock_movements — no service has to remember to
-- update both tables itself.
CREATE OR REPLACE FUNCTION apply_stock_movement() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO stock_levels (product_id, quantity_on_hand, updated_at)
    VALUES (NEW.product_id, GREATEST(NEW.quantity, 0), now())
    ON CONFLICT (product_id) DO UPDATE
        SET quantity_on_hand = stock_levels.quantity_on_hand + NEW.quantity,
            updated_at       = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_apply_stock_movement
    AFTER INSERT ON stock_movements
    FOR EACH ROW EXECUTE FUNCTION apply_stock_movement();

-- Generic updated_at bump, reused on products/orders.
CREATE OR REPLACE FUNCTION bump_updated_at() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION bump_updated_at();

CREATE TRIGGER trg_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION bump_updated_at();
