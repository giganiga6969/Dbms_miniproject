import os
from decimal import Decimal
from flask import Flask, render_template, request, redirect, url_for, session, flash
import mysql.connector
from mysql.connector import errorcode


def get_db_config():
    return {
        'host': os.getenv('DB_HOST', '127.0.0.1'),
        'port': int(os.getenv('DB_PORT', '3306')),
        'user': os.getenv('DB_USER', 'root'),
        'password': os.getenv('DB_PASSWORD', '@Yush123!'),
        'database': os.getenv('DB_NAME', 'dbmsmp'),
        'autocommit': False,
    }


class _ConnectionContext:
    def __init__(self, cfg):
        self._cfg = cfg
        self._conn = None
    def __enter__(self):
        self._conn = mysql.connector.connect(**self._cfg)
        return self._conn
    def __exit__(self, exc_type, exc, tb):
        try:
            if self._conn is not None:
                if exc_type is not None:
                    try:
                        if getattr(self._conn, 'in_transaction', False):
                            self._conn.rollback()
                    except Exception:
                        pass
                self._conn.close()
        finally:
            self._conn = None
        return False

def get_connection():
    # Return a context manager so we can use: with get_connection() as conn:
    return _ConnectionContext(get_db_config())


app = Flask(__name__)
app.secret_key = os.getenv('FLASK_SECRET', 'dev-secret-change-me')


# ---------- Helpers ----------

def require_customer():
    cid = session.get('customer_id')
    if not cid:
        flash('Please enter your details to start shopping.', 'info')
        return False
    return True


def fetch_customer_by_email_or_phone(conn, email, phone):
    cur = conn.cursor(dictionary=True)
    cur.execute(
        "SELECT * FROM CUSTOMER WHERE email = %s OR phone = %s LIMIT 1",
        (email, phone),
    )
    row = cur.fetchone()
    cur.close()
    return row


# ---------- Routes ----------

@app.route('/products')
def home():
    # list products
    with get_connection() as conn:
        cur = conn.cursor(dictionary=True)
        cur.execute(
            "SELECT product_id, name, brand, category, price, stock_qty, in_stock FROM PRODUCT ORDER BY category, name"
        )
        products = cur.fetchall()
        cur.close()
    return render_template('index.html', products=products)


@app.route('/')
def welcome():
    return render_template('welcome.html')


@app.route('/start', methods=['GET', 'POST'])
def start():
    if request.method == 'POST':
        name = request.form.get('name')
        phone = request.form.get('phone')
        email = request.form.get('email')
        address = request.form.get('address')
        if not (name and phone and email and address):
            flash('All fields are required.', 'warning')
            return render_template('start.html')
        try:
            with get_connection() as conn:
                conn.start_transaction()
                existing = fetch_customer_by_email_or_phone(conn, email, phone)
                if existing:
                    customer_id = existing['customer_id']
                else:
                    cur = conn.cursor()
                    cur.execute(
                        """
                        INSERT INTO CUSTOMER(name, phone, email, address)
                        VALUES (%s, %s, %s, %s)
                        """,
                        (name, phone, email, address),
                    )
                    customer_id = cur.lastrowid
                    cur.close()
                conn.commit()
                session['customer_id'] = customer_id
                session['customer_name'] = name
                flash('Welcome! You can start shopping now.', 'success')
                return redirect(url_for('home'))
        except mysql.connector.Error as e:
            flash(f'Database error: {e.msg}', 'danger')
            return render_template('start.html')
    return render_template('start.html')


@app.route('/add_to_cart', methods=['POST'])
def add_to_cart():
    if not require_customer():
        return redirect(url_for('start'))

    product_id = request.form.get('product_id', type=int)
    qty = request.form.get('quantity', type=int)
    if not product_id or not qty or qty <= 0:
        flash('Invalid product/quantity.', 'warning')
        return redirect(url_for('home'))

    cid = session['customer_id']
    try:
        with get_connection() as conn:
            conn.start_transaction()
            cur = conn.cursor(dictionary=True)
            # validate product
            cur.execute(
                "SELECT product_id, name, price, stock_qty, in_stock FROM PRODUCT WHERE product_id = %s",
                (product_id,),
            )
            product = cur.fetchone()
            if not product:
                conn.rollback()
                flash('Product not found.', 'warning')
                return redirect(url_for('home'))
            if not product['in_stock'] or product['stock_qty'] <= 0:
                conn.rollback()
                flash('Sorry, this product is out of stock.', 'danger')
                return redirect(url_for('home'))

            # If cart row exists (active), update quantity else insert new
            cur.execute(
                """
                SELECT cart_id, quantity FROM CART
                WHERE customer_id = %s AND product_id = %s AND status = 'active'
                FOR UPDATE
                """,
                (cid, product_id),
            )
            existing = cur.fetchone()

            if existing:
                new_qty = existing['quantity'] + qty
                cur2 = conn.cursor()
                cur2.execute(
                    "UPDATE CART SET quantity = %s WHERE cart_id = %s",
                    (new_qty, existing['cart_id']),
                )
                cur2.close()
            else:
                cur2 = conn.cursor()
                cur2.execute(
                    """
                    INSERT INTO CART(customer_id, product_id, quantity, status)
                    VALUES (%s, %s, %s, 'active')
                    """,
                    (cid, product_id, qty),
                )
                cur2.close()

            conn.commit()
            flash('Item added to cart.', 'success')
    except mysql.connector.Error as e:
        flash(f'Could not add to cart: {e.msg}', 'danger')
    return redirect(url_for('home'))


@app.route('/cart')
def view_cart():
    if not require_customer():
        return redirect(url_for('start'))
    cid = session['customer_id']
    with get_connection() as conn:
        cur = conn.cursor(dictionary=True)
        cur.execute(
            """
            SELECT ct.cart_id, ct.product_id, ct.quantity, p.name, p.brand, p.price, p.stock_qty, p.in_stock
            FROM CART ct
            JOIN PRODUCT p ON p.product_id = ct.product_id
            WHERE ct.customer_id = %s AND ct.status = 'active'
            ORDER BY p.name
            """,
            (cid,),
        )
        rows = cur.fetchall()
        cur.close()

    total = sum(Decimal(str(r['price'])) * r['quantity'] for r in rows)
    return render_template('cart.html', items=rows, total=total)


@app.route('/update_cart', methods=['POST'])
def update_cart():
    if not require_customer():
        return redirect(url_for('start'))
    cid = session['customer_id']
    action = request.form.get('action')
    try:
        with get_connection() as conn:
            conn.start_transaction()
            if action == 'remove':
                cart_id = request.form.get('cart_id', type=int)
                cur = conn.cursor()
                cur.execute(
                    "DELETE FROM CART WHERE cart_id = %s AND customer_id = %s AND status = 'active'",
                    (cart_id, cid),
                )
                cur.close()
            elif action == 'set_qty':
                cart_id = request.form.get('cart_id', type=int)
                qty = request.form.get('quantity', type=int)
                if qty is None or qty <= 0:
                    cur = conn.cursor()
                    cur.execute(
                        "DELETE FROM CART WHERE cart_id = %s AND customer_id = %s AND status = 'active'",
                        (cart_id, cid),
                    )
                    cur.close()
                else:
                    cur = conn.cursor()
                    cur.execute(
                        "UPDATE CART SET quantity = %s WHERE cart_id = %s AND customer_id = %s AND status = 'active'",
                        (qty, cart_id, cid),
                    )
                    cur.close()
            conn.commit()
            flash('Cart updated.', 'success')
    except mysql.connector.Error as e:
        flash(f'Could not update cart: {e.msg}', 'danger')
    return redirect(url_for('view_cart'))


@app.route('/checkout', methods=['GET', 'POST'])
def checkout():
    if not require_customer():
        return redirect(url_for('start'))
    cid = session['customer_id']

    if request.method == 'GET':
        # render summary and payment method selection
        with get_connection() as conn:
            cur = conn.cursor(dictionary=True)
            cur.execute(
                """
                SELECT ct.cart_id, ct.product_id, ct.quantity, p.name, p.price, p.stock_qty, p.in_stock
                FROM CART ct
                JOIN PRODUCT p ON p.product_id = ct.product_id
                WHERE ct.customer_id = %s AND ct.status = 'active'
                ORDER BY p.name
                """,
                (cid,),
            )
            items = cur.fetchall()
            cur.close()
        if not items:
            flash('Your cart is empty.', 'info')
            return redirect(url_for('home'))
        total = sum(Decimal(str(r['price'])) * r['quantity'] for r in items)
        return render_template('checkout.html', items=items, total=total)

    # POST: perform checkout
    payment_method = request.form.get('payment_method', 'cash')
    try:
        with get_connection() as conn:
            conn.start_transaction()
            cur = conn.cursor(dictionary=True)
            # Fetch items FOR UPDATE
            cur.execute(
                """
                SELECT ct.cart_id, ct.product_id, ct.quantity, p.price, p.stock_qty, p.in_stock
                FROM CART ct
                JOIN PRODUCT p ON p.product_id = ct.product_id
                WHERE ct.customer_id = %s AND ct.status = 'active' FOR UPDATE
                """,
                (cid,),
            )
            items = cur.fetchall()
            if not items:
                conn.rollback()
                flash('Your cart is empty.', 'info')
                return redirect(url_for('home'))

            # Pre-validate stock
            for it in items:
                if (not it['in_stock']) or it['quantity'] > it['stock_qty']:
                    conn.rollback()
                    flash('Insufficient stock for one or more items. Please adjust your cart.', 'danger')
                    return redirect(url_for('view_cart'))

            # Compute total
            total = sum(Decimal(str(it['price'])) * it['quantity'] for it in items)

            # Update each cart row to checked_out (trigger will decrement stock)
            for it in items:
                cur2 = conn.cursor()
                cur2.execute(
                    "UPDATE CART SET status = 'checked_out' WHERE cart_id = %s",
                    (it['cart_id'],),
                )
                cur2.close()

            # Create order
            cur3 = conn.cursor()
            cur3.execute(
                """
                INSERT INTO ORDERS(status, total_amount, customer_id)
                VALUES('completed', %s, %s)
                """,
                (str(total), cid),
            )
            order_id = cur3.lastrowid
            cur3.close()

            # Create payment record
            cur4 = conn.cursor()
            cur4.execute(
                """
                INSERT INTO PAYMENT(order_id, amount, method, transaction_status)
                VALUES(%s, %s, %s, 'success')
                """,
                (order_id, str(total), payment_method),
            )
            cur4.close()

            conn.commit()
            flash('Order placed successfully!', 'success')
            return redirect(url_for('success', order_id=order_id))
    except mysql.connector.Error as e:
        flash(f'Checkout failed: {e.msg}', 'danger')
        return redirect(url_for('view_cart'))


@app.route('/success')
def success():
    order_id = request.args.get('order_id', type=int)
    return render_template('success.html', order_id=order_id)


if __name__ == '__main__':
    app.run(debug=True)
