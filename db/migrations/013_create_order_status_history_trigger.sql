-- Automatically logs a row to order_status_history whenever orders.status
-- changes, so order-service doesn't have to write to two tables manually.
CREATE OR REPLACE FUNCTION log_order_status_change() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') OR (NEW.status IS DISTINCT FROM OLD.status) THEN
        INSERT INTO order_status_history (order_id, status, changed_at)
        VALUES (NEW.order_id, NEW.status, now());
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_order_status_insert
    AFTER INSERT ON orders
    FOR EACH ROW EXECUTE FUNCTION log_order_status_change();

CREATE TRIGGER trg_log_order_status_update
    AFTER UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION log_order_status_change();
