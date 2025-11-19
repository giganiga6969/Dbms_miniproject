create database dbmsmp;
use dbmsmp;
CREATE TABLE CUSTOMER (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    address VARCHAR(255) NOT NULL
);
CREATE TABLE STORE (
    store_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    branch VARCHAR(100),
    manager VARCHAR(100) NOT NULL,
    location VARCHAR(255) NOT NULL,
    opening_hours VARCHAR(100) NOT NULL
);
CREATE TABLE PRODUCT (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    brand VARCHAR(100),
    category VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    stock_qty INT DEFAULT 0 CHECK (stock_qty >= 0),
    in_stock BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE INVENTORY (
    inventory_id INT AUTO_INCREMENT PRIMARY KEY,
    store_id INT NOT NULL,
    product_id INT NOT NULL,
    stock_level INT DEFAULT 0 CHECK (stock_level >= 0),
    reorder_level INT DEFAULT 0 CHECK (reorder_level >= 0),
    FOREIGN KEY (store_id) REFERENCES STORE(store_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (product_id) REFERENCES PRODUCT(product_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE (store_id, product_id)
);
CREATE TABLE CART (
    cart_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT DEFAULT 1 CHECK (quantity > 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    status ENUM('active','abandoned','checked_out') DEFAULT 'active',
    FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (product_id) REFERENCES PRODUCT(product_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE ORDERS (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending','completed','cancelled') DEFAULT 'pending',
    total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
    customer_id INT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE PAYMENT (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT UNIQUE NOT NULL,
    amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    method ENUM('cash','card','upi','wallet') NOT NULL,
    transaction_status ENUM('success','failed','pending') DEFAULT 'pending',
    FOREIGN KEY (order_id) REFERENCES ORDERS(order_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO CUSTOMER (customer_id, name, phone, email, address) VALUES
(1, 'Alice Johnson', '9876543210', 'alice@example.com', '12 Park Lane'),
(2, 'Bob Smith', '9123456780', 'bob@example.com', '45 Market St'),
(3, 'Charlie Brown', '9988776655', 'charlie@example.com', '78 Ocean Ave');
INSERT INTO STORE (store_id, name, branch, manager, location, opening_hours) VALUES
(1, 'Downtown Store', 'Central', 'John Doe', '33 Main St', '9AM-9PM'),
(2, 'Uptown Store', 'North Branch', 'Mary Jane', '55 Broadway', '10AM-10PM');
INSERT INTO PRODUCT (product_id, name, brand, category, price, stock_qty) VALUES
(1, 'Milk 1L', 'Amul', 'Dairy', 55.00, 100),
(2, 'Bread', 'Britannia', 'Bakery', 40.00, 50),
(3, 'Apple', 'FreshFarm', 'Fruits', 120.00, 200),
(4, 'Eggs (12 pcs)', 'Keggs', 'Dairy', 78.00, 120),
(5, 'Rice 5kg', 'India Gate', 'Grains', 435.00, 80),
(6, 'Sugar 1kg', 'Dhampur', 'Pantry', 52.00, 150),
(7, 'Salt 1kg', 'Tata', 'Pantry', 20.00, 200),
(8, 'Sunflower Oil 1L', 'Fortune', 'Oil & Ghee', 145.00, 90),
(9, 'Tea 250g', 'Tata Tea', 'Beverages', 125.00, 110),
(10, 'Coffee 200g', 'Nescafe', 'Beverages', 295.00, 70),
(11, 'Banana 1kg', 'FreshFarm', 'Fruits', 60.00, 180),
(12, 'Orange 1kg', 'FreshFarm', 'Fruits', 95.00, 160),
(13, 'Tomato 1kg', 'FreshFarm', 'Vegetables', 35.00, 220),
(14, 'Onion 1kg', 'FreshFarm', 'Vegetables', 30.00, 250),
(15, 'Potato 2kg', 'FreshFarm', 'Vegetables', 50.00, 200),
(16, 'Cheese 200g', 'Amul', 'Dairy', 110.00, 85),
(17, 'Yogurt 500g', 'Mother Dairy', 'Dairy', 70.00, 95),
(18, 'Toilet Soap Bar', 'Lux', 'Personal Care', 40.00, 140),
(19, 'Shampoo 200ml', 'Head & Shoulders', 'Personal Care', 175.00, 60),
(20, 'Toothpaste 150g', 'Colgate', 'Personal Care', 99.00, 130);
INSERT INTO INVENTORY (inventory_id, store_id, product_id, stock_level, reorder_level) VALUES
(1, 1, 1, 80, 20),
(2, 1, 2, 30, 10),
(3, 2, 3, 150, 30);
INSERT INTO CART (cart_id, customer_id, product_id, quantity, created_at, updated_at, status) VALUES
(1, 1, 1, 2, '2025-10-03 09:30:00', '2025-10-03 09:40:00', 'active'),
(2, 2, 2, 1, '2025-10-02 15:10:00', '2025-10-02 15:30:00', 'checked_out'),
(3, 3, 3, 5, '2025-10-01 18:00:00', '2025-10-01 18:10:00', 'abandoned');
INSERT INTO ORDERS (order_id, order_date, status, total_amount, customer_id) VALUES
(1, '2025-10-03', 'completed', 110.00, 1),
(2, '2025-10-02', 'pending', 40.00, 2);
INSERT INTO PAYMENT (payment_id, order_id, amount, payment_date, method, transaction_status) VALUES
(1, 1, 110.00, '2025-10-03', 'upi', 'success'),
(2, 2, 40.00, '2025-10-02', 'card', 'pending');



-- see all customers with carts 
SELECT c.name, ct.product_id, ct.quantity, ct.status
FROM CUSTOMER c
JOIN CART ct ON c.customer_id = ct.customer_id;
-- all orders with payments done
SELECT o.order_id, o.status, p.method, p.transaction_status
FROM ORDERS o
JOIN PAYMENT p ON o.order_id = p.order_id;
-- check stock avaailabe or not 
SELECT p.name, i.stock_level, i.reorder_level
FROM PRODUCT p
JOIN INVENTORY i ON p.product_id = i.product_id;

show tables;




-- =============================
-- TRIGGERS FOR STOCK ENFORCEMENT
-- =============================
DELIMITER $$

-- Keep PRODUCT.in_stock synced with PRODUCT.stock_qty
DROP TRIGGER IF EXISTS trg_product_bi_stock$$
CREATE TRIGGER trg_product_bi_stock
BEFORE INSERT ON PRODUCT
FOR EACH ROW
BEGIN
  SET NEW.in_stock = (NEW.stock_qty > 0);
END$$

DROP TRIGGER IF EXISTS trg_product_bu_stock$$
CREATE TRIGGER trg_product_bu_stock
BEFORE UPDATE ON PRODUCT
FOR EACH ROW
BEGIN
  SET NEW.in_stock = (NEW.stock_qty > 0);
END$$

-- Validate CART insert against available stock
DROP TRIGGER IF EXISTS trg_cart_bi_validate$$
CREATE TRIGGER trg_cart_bi_validate
BEFORE INSERT ON CART
FOR EACH ROW
BEGIN
  DECLARE v_stock INT DEFAULT 0;
  DECLARE v_in_stock TINYINT DEFAULT 0;
  SELECT stock_qty, in_stock INTO v_stock, v_in_stock
  FROM PRODUCT
  WHERE product_id = NEW.product_id
  FOR UPDATE;

  IF v_stock IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product not found';
  END IF;
  IF v_in_stock = 0 OR v_stock <= 0 OR NEW.quantity > v_stock THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock for product';
  END IF;
END$$

-- Validate quantity changes and decrement stock when checking out
DROP TRIGGER IF EXISTS trg_cart_bu_validate_and_checkout$$
CREATE TRIGGER trg_cart_bu_validate_and_checkout
BEFORE UPDATE ON CART
FOR EACH ROW
BEGIN
  DECLARE v_stock INT DEFAULT 0;
  DECLARE v_in_stock TINYINT DEFAULT 0;
  DECLARE v_new_stock INT DEFAULT 0;

  -- Ensure product exists and lock it
  SELECT stock_qty, in_stock INTO v_stock, v_in_stock
  FROM PRODUCT
  WHERE product_id = NEW.product_id
  FOR UPDATE;

  IF v_stock IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product not found';
  END IF;

  -- When cart remains active and qty changes, validate available stock
  IF NEW.status = 'active' THEN
    IF NEW.quantity <= 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity must be > 0';
    END IF;
    IF NEW.quantity > v_stock THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock for requested quantity';
    END IF;
  END IF;

  -- On transition to checked_out, atomically decrease product stock
  IF OLD.status <> 'checked_out' AND NEW.status = 'checked_out' THEN
    IF NEW.quantity > v_stock THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock to checkout';
    END IF;
    SET v_new_stock = v_stock - NEW.quantity;
    UPDATE PRODUCT
      SET stock_qty = v_new_stock,
          in_stock = (v_new_stock > 0)
      WHERE product_id = NEW.product_id;
  END IF;
END$$

DELIMITER ;

-- One-time sync to correct any in_stock flags for existing data
UPDATE PRODUCT SET in_stock = (stock_qty > 0);


-- =============================
-- STORED PROCEDURES (utility; no functionality change)
-- =============================
DELIMITER $$

-- List all products that are currently available (stock_qty > 0 and in_stock = 1)
DROP PROCEDURE IF EXISTS sp_list_available_products$$
CREATE PROCEDURE sp_list_available_products()
BEGIN
  SELECT product_id, name, brand, category, price, stock_qty
  FROM PRODUCT
  WHERE in_stock = 1 AND stock_qty > 0
  ORDER BY category, name;
END$$

-- List products by a given category (exact match)
DROP PROCEDURE IF EXISTS sp_list_products_by_category$$
CREATE PROCEDURE sp_list_products_by_category(IN p_category VARCHAR(100))
BEGIN
  SELECT product_id, name, brand, category, price, stock_qty, in_stock
  FROM PRODUCT
  WHERE category = p_category
  ORDER BY name;
END$$

-- Get the current active cart for a customer (aggregated view)
DROP PROCEDURE IF EXISTS sp_get_customer_cart$$
CREATE PROCEDURE sp_get_customer_cart(IN p_customer_id INT)
BEGIN
  SELECT ct.cart_id,
         ct.product_id,
         p.name,
         p.brand,
         p.price,
         ct.quantity,
         (p.price * ct.quantity) AS line_total,
         p.stock_qty,
         p.in_stock
  FROM CART ct
  JOIN PRODUCT p ON p.product_id = ct.product_id
  WHERE ct.customer_id = p_customer_id AND ct.status = 'active'
  ORDER BY p.name;
END$$

DELIMITER ;
