### Cash & Carry Mart — DBMS Mini Project (Flask + MySQL)

A simple user-side shopping web app where customers can browse products, add/remove items to/from cart, and place an order. The database enforces stock levels with triggers: when an item runs out, it shows as out-of-stock and checkout will not allow exceeding stock.

This project uses:
- Python 3.10+
- Flask (backend + HTML templates)
- MySQL 8+
- CSS (no framework) and basic HTML; no admin pages are included

---

#### 1) Database setup

1. Ensure MySQL 8+ is installed and running.
2. Open MySQL client and import the SQL file (this will create the `dbmsmp` database, tables, seed data, and triggers):
   ```sql
   SOURCE D:/PythonProject/DBMSProject/miniproject.sql;
   ```
   Or via command-line (update path and credentials accordingly):
   ```bash
   mysql -u root -p < D:/PythonProject/DBMSProject/miniproject.sql
   ```

The SQL adds these triggers at the end of the file:
- Keep `PRODUCT.in_stock` synced with `PRODUCT.stock_qty` on insert/update
- Validate `CART` inserts/updates so requested quantity cannot exceed available stock
- When a cart row changes `status` to `checked_out`, atomically decrement the product stock and update `in_stock`

Note: The app creates `ORDERS` and `PAYMENT` entries on checkout. The `ORDERS.cart_id` column in the schema remains nullable; the app does not tie orders to a single cart row.

---

#### 2) App configuration

App reads configuration from environment variables:
- `DB_HOST` (default `127.0.0.1`)
- `DB_PORT` (default `3306`)
- `DB_USER` (default `root`)
- `DB_PASSWORD` (default empty)
- `DB_NAME` (default `dbmsmp`)
- `FLASK_SECRET` (session secret, default `dev-secret-change-me`)

You can set them in your shell before running the app (PowerShell example on Windows):
```powershell
$env:DB_HOST="127.0.0.1"
$env:DB_USER="root"
$env:DB_PASSWORD="your_password"
$env:DB_NAME="dbmsmp"
$env:FLASK_SECRET="change-me"
```

---

#### 3) Install & run

1. Create and activate a virtual environment (recommended).
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Run the app:
   ```bash
   python app.py
   ```
4. Open the app at:
   - http://127.0.0.1:5000/

---

#### 4) How to use

- Start: Click "Start / Profile" and enter your name, phone, email, address. If phone or email already exist, the app will use your existing customer record.
- Products page: Shows all products with price and remaining stock.
  - If an item is out-of-stock (or becomes 0), it displays an "Out of Stock" badge and the Add button is disabled.
- Cart: Update quantity or remove items.
  - If you try to set a quantity higher than remaining stock, the database will reject it and the app will show an error.
- Checkout: Choose a payment method and place the order.
  - During checkout the database triggers atomically decrement product stock and update the `in_stock` flag.

---

#### 5) Project structure

```
D:/PythonProject/DBMSProject
├─ app.py                  # Flask app
├─ miniproject.sql         # DB schema, sample data, and triggers
├─ requirements.txt        # Python dependencies
├─ templates/              # Jinja2 templates
│  ├─ base.html
│  ├─ index.html
│  ├─ start.html
│  ├─ cart.html
│  ├─ checkout.html
│  └─ success.html
└─ static/
   └─ styles.css           # Minimal CSS
```

---

#### 6) Notes and assumptions

- Stock is not reserved when items are added to the cart; stock is only decremented on checkout. If multiple customers attempt to checkout the same remaining stock, triggers ensure only available quantities succeed, and others will see an error.
- The schema includes `INVENTORY` per-store and a global `PRODUCT.stock_qty`. The app uses the global `PRODUCT.stock_qty` column for simplicity.
- For a more detailed production app, consider adding authentication, order line items, and pagination.

---

#### 7) Troubleshooting

- If you get a MySQL error referencing triggers while adding to cart or updating quantity, it usually means requested quantity exceeds current stock.
- If `mysql` client reports `DELIMITER` issues, ensure you are using the MySQL CLI or Workbench (not a generic SQL runner that ignores `DELIMITER`). You can also run the trigger blocks manually in a proper MySQL client session.
