import os
from flask import Flask, jsonify, request
from prometheus_flask_exporter import PrometheusMetrics
from db import db_cursor

app = Flask(__name__)
metrics = PrometheusMetrics(app)


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


@app.get("/categories")
def list_categories():
    with db_cursor() as cur:
        cur.execute("SELECT category_id, name, type FROM categories ORDER BY name;")
        rows = cur.fetchall()
    return jsonify([{**r, "category_id": str(r["category_id"])} for r in rows])


@app.get("/products")
def list_products():
    category_id = request.args.get("category_id")
    query = """
        SELECT p.product_id, p.name, p.author, p.sku, p.price, p.category_id,
               COALESCE(s.quantity_on_hand, 0) AS quantity_on_hand
        FROM products p
        LEFT JOIN stock_levels s ON s.product_id = p.product_id
        WHERE p.is_active = true
    """
    params = ()
    if category_id:
        query += " AND p.category_id = %s"
        params = (category_id,)
    query += " ORDER BY p.name;"

    with db_cursor() as cur:
        cur.execute(query, params)
        rows = cur.fetchall()

    result = []
    for r in rows:
        d = dict(r)
        d["product_id"] = str(d["product_id"])
        d["category_id"] = str(d["category_id"])
        d["price"] = float(d["price"])
        result.append(d)
    return jsonify(result)


@app.get("/products/<product_id>")
def get_product(product_id):
    with db_cursor() as cur:
        cur.execute("""
            SELECT p.product_id, p.name, p.description, p.author, p.sku, p.price, p.category_id,
                   COALESCE(s.quantity_on_hand, 0) AS quantity_on_hand
            FROM products p
            LEFT JOIN stock_levels s ON s.product_id = p.product_id
            WHERE p.product_id = %s;
        """, (product_id,))
        row = cur.fetchone()
    if not row:
        return {"error": "product not found"}, 404
    d = dict(row)
    d["product_id"] = str(d["product_id"])
    d["category_id"] = str(d["category_id"])
    d["price"] = float(d["price"])
    return jsonify(d)


@app.post("/stock-movements")
def create_stock_movement():
    """Internal endpoint. Body: product_id, movement_type (sale|purchase|return),
    quantity (negative for sale, positive for purchase/return),
    reference_order_id (optional), reference_purchase_id (optional), note (optional).
    """
    body = request.get_json(force=True)
    required = {"product_id", "movement_type", "quantity"}
    if not required.issubset(body):
        return {"error": f"missing fields, need {sorted(required)}"}, 400
    if body["movement_type"] not in ("sale", "purchase", "return"):
        return {"error": "invalid movement_type"}, 400

    with db_cursor(commit=True) as cur:
        if body["movement_type"] == "sale":
            cur.execute(
                "SELECT quantity_on_hand FROM stock_levels WHERE product_id = %s FOR UPDATE;",
                (body["product_id"],),
            )
            row = cur.fetchone()
            available = row["quantity_on_hand"] if row else 0
            if available + body["quantity"] < 0:
                return {"error": "insufficient stock", "available": available}, 409

        cur.execute("""
            INSERT INTO stock_movements
                (product_id, movement_type, quantity, reference_order_id, reference_purchase_id, note)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING movement_id;
        """, (
            body["product_id"], body["movement_type"], body["quantity"],
            body.get("reference_order_id"), body.get("reference_purchase_id"), body.get("note"),
        ))
        movement_id = cur.fetchone()["movement_id"]

    return {"movement_id": str(movement_id)}, 201


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5001)))
