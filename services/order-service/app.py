import os
import requests
from flask import Flask, jsonify, request
from prometheus_flask_exporter import PrometheusMetrics
from db import db_cursor

app = Flask(__name__)
metrics = PrometheusMetrics(app)

CATALOG_URL = os.environ.get("CATALOG_SERVICE_URL", "http://catalog-service:5001")
VALID_STATUSES = {"Placed", "Packed", "Shipped", "Delivered", "Cancelled"}


@app.get("/healthz")
def healthz():
    return {"status": "ok"}, 200


@app.get("/readyz")
def readyz():
    try:
        with db_cursor() as cur:
            cur.execute("SELECT 1;")
        return {"status": "ready"}, 200
    except Exception as e:
        return {"status": "not ready", "error": str(e)}, 503


@app.post("/orders")
def create_order():
    """Converts a cart into an order. Checks live price + stock against
    catalog-service, writes orders + order_items in one transaction, then
    records the sale stock movement.

    Known v1 simplification: the order write and the stock-movement call
    are two separate steps against two services, not one distributed
    transaction. If the stock-movement call fails after the order commits,
    the order exists but stock isn't decremented yet — acceptable for a
    portfolio project; a production system would use an outbox/saga
    pattern here instead.
    """
    body = request.get_json(force=True)
    customer_id = body.get("customer_id")
    items = body.get("items") or []

    if not customer_id or not items:
        return {"error": "customer_id and a non-empty items list are required"}, 400

    order_items = []
    total = 0
    for item in items:
        pid = item.get("product_id")
        qty = item.get("quantity")
        if not pid or not qty or qty <= 0:
            return {"error": "each item needs product_id and a positive quantity"}, 400

        resp = requests.get(f"{CATALOG_URL}/products/{pid}", timeout=5)
        if resp.status_code != 200:
            return {"error": f"product {pid} not found in catalog"}, 400
        product = resp.json()

        if product["quantity_on_hand"] < qty:
            return {
                "error": f"insufficient stock for '{product['name']}'",
                "available": product["quantity_on_hand"],
            }, 409

        order_items.append({"product_id": pid, "quantity": qty, "unit_price": product["price"]})
        total += product["price"] * qty

    with db_cursor(commit=True) as cur:
        cur.execute("""
            INSERT INTO orders (customer_id, status, total_amount)
            VALUES (%s, 'Placed', %s)
            RETURNING order_id, status, total_amount, created_at;
        """, (customer_id, total))
        order = cur.fetchone()
        order_id = order["order_id"]

        for oi in order_items:
            cur.execute("""
                INSERT INTO order_items (order_id, product_id, quantity, unit_price)
                VALUES (%s, %s, %s, %s);
            """, (order_id, oi["product_id"], oi["quantity"], oi["unit_price"]))

    # Record the sale in the stock ledger now that the order row exists
    # (reference_order_id is a foreign key).
    for oi in order_items:
        try:
            requests.post(f"{CATALOG_URL}/stock-movements", json={
                "product_id": oi["product_id"],
                "movement_type": "sale",
                "quantity": -oi["quantity"],
                "reference_order_id": str(order_id),
                "note": "Sale from order",
            }, timeout=5)
        except requests.RequestException as e:
            app.logger.error(f"Stock movement failed for order {order_id}: {e}")

    return jsonify({
        "order_id": str(order_id),
        "status": order["status"],
        "total_amount": float(order["total_amount"]),
        "created_at": order["created_at"].isoformat(),
    }), 201


@app.get("/orders/<order_id>")
def get_order(order_id):
    with db_cursor() as cur:
        cur.execute("""
            SELECT order_id, customer_id, status, total_amount, created_at, updated_at
            FROM orders WHERE order_id = %s;
        """, (order_id,))
        order = cur.fetchone()
        if not order:
            return {"error": "not found"}, 404

        cur.execute("""
            SELECT order_item_id, product_id, quantity, unit_price
            FROM order_items WHERE order_id = %s;
        """, (order_id,))
        items = cur.fetchall()

        cur.execute("""
            SELECT status, changed_at FROM order_status_history
            WHERE order_id = %s ORDER BY changed_at;
        """, (order_id,))
        history = cur.fetchall()

    return jsonify({
        "order_id": str(order["order_id"]),
        "customer_id": str(order["customer_id"]),
        "status": order["status"],
        "total_amount": float(order["total_amount"]),
        "created_at": order["created_at"].isoformat(),
        "items": [
            {
                "order_item_id": str(i["order_item_id"]),
                "product_id": str(i["product_id"]),
                "quantity": i["quantity"],
                "unit_price": float(i["unit_price"]),
            }
            for i in items
        ],
        "status_history": [
            {"status": h["status"], "changed_at": h["changed_at"].isoformat()} for h in history
        ],
    })


@app.get("/orders/track")
def track_order():
    """No-login tracking: phone number + order ID is the lookup key,
    matching the low-friction checkout requirement."""
    phone = request.args.get("phone_number")
    order_id = request.args.get("order_id")
    if not phone or not order_id:
        return {"error": "phone_number and order_id query params are required"}, 400

    with db_cursor() as cur:
        cur.execute("""
            SELECT o.order_id, o.status, o.total_amount, o.created_at
            FROM orders o
            JOIN customers c ON c.customer_id = o.customer_id
            WHERE o.order_id = %s AND c.phone_number = %s;
        """, (order_id, phone))
        order = cur.fetchone()
        if not order:
            return {"error": "no matching order for that phone number"}, 404

        cur.execute("""
            SELECT status, changed_at FROM order_status_history
            WHERE order_id = %s ORDER BY changed_at;
        """, (order_id,))
        history = cur.fetchall()

    return jsonify({
        "order_id": str(order["order_id"]),
        "status": order["status"],
        "total_amount": float(order["total_amount"]),
        "status_history": [
            {"status": h["status"], "changed_at": h["changed_at"].isoformat()} for h in history
        ],
    })


@app.patch("/orders/<order_id>/status")
def update_status(order_id):
    """Admin/operational action — e.g. marking an order Shipped."""
    body = request.get_json(force=True)
    new_status = body.get("status")
    if new_status not in VALID_STATUSES:
        return {"error": f"status must be one of {sorted(VALID_STATUSES)}"}, 400

    with db_cursor(commit=True) as cur:
        cur.execute(
            "UPDATE orders SET status = %s WHERE order_id = %s RETURNING order_id;",
            (new_status, order_id),
        )
        row = cur.fetchone()

    if not row:
        return {"error": "not found"}, 404
    return {"order_id": str(row["order_id"]), "status": new_status}


@app.post("/orders/<order_id>/returns")
def create_return(order_id):
    body = request.get_json(force=True)
    order_item_id = body.get("order_item_id")
    quantity = body.get("quantity")
    reason = body.get("reason", "")

    if not order_item_id or not quantity or quantity <= 0:
        return {"error": "order_item_id and a positive quantity are required"}, 400

    with db_cursor() as cur:
        cur.execute("""
            SELECT product_id, quantity AS ordered_qty
            FROM order_items WHERE order_item_id = %s AND order_id = %s;
        """, (order_item_id, order_id))
        item = cur.fetchone()

    if not item:
        return {"error": "order item not found on this order"}, 404
    if quantity > item["ordered_qty"]:
        return {"error": "return quantity exceeds ordered quantity"}, 400

    with db_cursor(commit=True) as cur:
        cur.execute("""
            INSERT INTO returns (order_item_id, quantity, reason)
            VALUES (%s, %s, %s)
            RETURNING return_id;
        """, (order_item_id, quantity, reason))
        return_row = cur.fetchone()

    try:
        requests.post(f"{CATALOG_URL}/stock-movements", json={
            "product_id": str(item["product_id"]),
            "movement_type": "return",
            "quantity": quantity,
            "reference_order_id": order_id,
            "note": f"Return: {reason}",
        }, timeout=5)
    except requests.RequestException as e:
        app.logger.error(f"Stock movement failed for return on order {order_id}: {e}")

    return {"return_id": str(return_row["return_id"])}, 201


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5003)))
