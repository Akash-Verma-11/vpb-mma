import os
import re
from flask import Flask, jsonify, request
from prometheus_flask_exporter import PrometheusMetrics
from db import db_cursor

app = Flask(__name__)
metrics = PrometheusMetrics(app)

PHONE_RE = re.compile(r"^\+?[0-9]{7,15}$")


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


@app.post("/customers/identify")
def identify_customer():
    """Get-or-create by phone number — this is the checkout identification
    gate. No password, no session login, per the confirmed v1 requirement."""
    body = request.get_json(force=True)
    name = (body.get("name") or "").strip()
    phone = (body.get("phone_number") or "").strip()

    if not name:
        return {"error": "name is required"}, 400
    if not PHONE_RE.match(phone):
        return {"error": "phone_number must be 7-15 digits, optional leading +"}, 400

    with db_cursor(commit=True) as cur:
        cur.execute(
            "SELECT customer_id, name, phone_number FROM customers WHERE phone_number = %s;",
            (phone,),
        )
        customer = cur.fetchone()
        if not customer:
            cur.execute("""
                INSERT INTO customers (name, phone_number)
                VALUES (%s, %s)
                RETURNING customer_id, name, phone_number;
            """, (name, phone))
            customer = cur.fetchone()

    return jsonify({
        "customer_id": str(customer["customer_id"]),
        "name": customer["name"],
        "phone_number": customer["phone_number"],
    })


@app.get("/customers/<customer_id>")
def get_customer(customer_id):
    with db_cursor() as cur:
        cur.execute(
            "SELECT customer_id, name, phone_number, created_at FROM customers WHERE customer_id = %s;",
            (customer_id,),
        )
        row = cur.fetchone()
    if not row:
        return {"error": "not found"}, 404
    return jsonify({
        "customer_id": str(row["customer_id"]),
        "name": row["name"],
        "phone_number": row["phone_number"],
        "created_at": row["created_at"].isoformat(),
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5002)))
