import os
import requests
from flask import Flask, render_template, request, redirect, url_for, session, flash
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)
app.secret_key = os.environ.get("SECRET_KEY", "dev-secret-change-me")
metrics = PrometheusMetrics(app)

CATALOG_URL = os.environ.get("CATALOG_SERVICE_URL", "http://catalog-service:5001")
CUSTOMER_URL = os.environ.get("CUSTOMER_SERVICE_URL", "http://customer-service:5002")
ORDER_URL = os.environ.get("ORDER_SERVICE_URL", "http://order-service:5003")


@app.get("/healthz")
def healthz():
    return {"status": "ok"}, 200


@app.get("/readyz")
def readyz():
    return {"status": "ready"}, 200


@app.get("/")
def home():
    try:
        categories = requests.get(f"{CATALOG_URL}/categories", timeout=5).json()
        products = requests.get(f"{CATALOG_URL}/products", timeout=5).json()
    except requests.RequestException:
        categories, products = [], []
        flash("Catalog is temporarily unavailable — please try again shortly.")
    return render_template("index.html", categories=categories, products=products)


@app.post("/cart/add")
def cart_add():
    product_id = request.form["product_id"]
    name = request.form["name"]
    price = float(request.form["price"])
    qty = int(request.form.get("quantity", 1))

    cart = session.get("cart", {})
    if product_id in cart:
        cart[product_id]["quantity"] += qty
    else:
        cart[product_id] = {"name": name, "price": price, "quantity": qty}
    session["cart"] = cart
    flash(f"Added '{name}' to cart.")
    return redirect(url_for("home"))


@app.get("/cart")
def cart_view():
    cart = session.get("cart", {})
    total = sum(item["price"] * item["quantity"] for item in cart.values())
    return render_template("cart.html", cart=cart, total=total)


@app.post("/cart/remove")
def cart_remove():
    product_id = request.form["product_id"]
    cart = session.get("cart", {})
    cart.pop(product_id, None)
    session["cart"] = cart
    return redirect(url_for("cart_view"))


@app.get("/checkout")
def checkout_form():
    cart = session.get("cart", {})
    if not cart:
        flash("Your cart is empty.")
        return redirect(url_for("home"))
    total = sum(item["price"] * item["quantity"] for item in cart.values())
    return render_template("checkout.html", cart=cart, total=total)


@app.post("/checkout")
def checkout_submit():
    cart = session.get("cart", {})
    if not cart:
        flash("Your cart is empty.")
        return redirect(url_for("home"))

    name = request.form.get("name", "").strip()
    phone = request.form.get("phone_number", "").strip()
    if not name or not phone:
        flash("Name and contact number are required to check out.")
        return redirect(url_for("checkout_form"))

    # Step 1: identify (get-or-create) the customer
    try:
        cust_resp = requests.post(f"{CUSTOMER_URL}/customers/identify",
                                   json={"name": name, "phone_number": phone}, timeout=5)
        if cust_resp.status_code != 200:
            flash(f"Could not identify customer: {cust_resp.json().get('error')}")
            return redirect(url_for("checkout_form"))
        customer = cust_resp.json()
    except requests.RequestException:
        flash("Customer service is temporarily unavailable.")
        return redirect(url_for("checkout_form"))

    # Step 2: create the order
    items = [{"product_id": pid, "quantity": item["quantity"]} for pid, item in cart.items()]
    try:
        order_resp = requests.post(f"{ORDER_URL}/orders", json={
            "customer_id": customer["customer_id"],
            "items": items,
        }, timeout=8)
        if order_resp.status_code != 201:
            flash(f"Could not place order: {order_resp.json().get('error')}")
            return redirect(url_for("checkout_form"))
        order = order_resp.json()
    except requests.RequestException:
        flash("Order service is temporarily unavailable.")
        return redirect(url_for("checkout_form"))

    session["cart"] = {}
    session["last_phone"] = phone
    return render_template("order_confirmation.html", order=order, phone=phone)


@app.get("/track")
def track_form():
    return render_template("track.html", order=None)


@app.get("/track/result")
def track_result():
    phone = request.args.get("phone_number", "").strip()
    order_id = request.args.get("order_id", "").strip()
    order = None
    error = None
    if phone and order_id:
        try:
            resp = requests.get(f"{ORDER_URL}/orders/track",
                                 params={"phone_number": phone, "order_id": order_id}, timeout=5)
            if resp.status_code == 200:
                order = resp.json()
            else:
                error = resp.json().get("error", "Order not found.")
        except requests.RequestException:
            error = "Order tracking is temporarily unavailable."
    return render_template("track.html", order=order, error=error,
                            phone=phone, order_id=order_id)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))
