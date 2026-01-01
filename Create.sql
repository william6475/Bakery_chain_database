/* Run this code if MYSQL version below 8.4.4
INSTALL COMPONENT 'file://component_validate_password'; -- Enforces password strength requirements
*/

CREATE DATABASE Bakery_stock;
USE Bakery_stock;

/* Table creation statments
--------------------------------------------------------------*/

-- Table storing branches of the bakery chain
CREATE TABLE IF NOT EXISTS Branches(
Branch_ID SMALLINT UNSIGNED AUTO_INCREMENT,
Branch_name VARCHAR(100) NOT NULL,
Branch_phone_number VARCHAR(15),
Branch_city VARCHAR(50),
Is_deleted Bool NOT NULL DEFAULT 0 NOT NULL,
PRIMARY KEY (Branch_ID)
);

-- Table storing deliveries (Delivered and to be delivered)
CREATE TABLE IF NOT EXISTS Deliveries(
Delivery_ID MEDIUMINT UNSIGNED AUTO_INCREMENT,
Branch_ID SMALLINT UNSIGNED NOT NULL,
Delivery_date_time TIMESTAMP NULL,
Is_delivered BOOL DEFAULT(0) NOT NULL,
PRIMARY KEY (Delivery_ID),
FOREIGN KEY(Branch_ID) REFERENCES Branches(Branch_ID)
);

-- Table storing items which can be at branches
CREATE TABLE IF NOT EXISTS Inventory_items(
Item_ID SMALLINT UNSIGNED AUTO_INCREMENT,
Item_name VARCHAR(100),
Item_cost DECIMAL(8, 2),
Item_category ENUM('Product', 'Ingredient', 'Packaging', 'Other'),
Is_deleted Bool NOT NULL DEFAULT 0,
PRIMARY KEY (Item_ID)
);

-- Table storing the items which each delivery holds
CREATE TABLE IF NOT EXISTS Delivery_items(
Delivery_ID MEDIUMINT UNSIGNED,
Item_ID SMALLINT UNSIGNED,
Item_quantity SMALLINT UNSIGNED NOT NULL,
PRIMARY KEY(Delivery_ID, Item_ID),
Foreign KEY (Delivery_ID) REFERENCES Deliveries(Delivery_ID),
FOREIGN KEY (Item_ID) REFERENCES Inventory_items(Item_ID)
);

-- Table storing product types
CREATE TABLE IF NOT EXISTS Products(
Product_ID SMALLINT UNSIGNED AUTO_INCREMENT,
Item_ID SMALLINT UNSIGNED UNIQUE NOT NULL,
Product_category ENUM('Cake', 'Bread', 'Pastry', 'Other') NOT NULL,
Product_price DECIMAL(6,2) NOT NULL,
Product_shelf_life_seconds MEDIUMINT UNSIGNED NOT NULL,
Is_deleted Bool NOT NULL DEFAULT 0, -- Only changable through marking an inventory_item as deleted
PRIMARY KEY(Product_ID),
FOREIGN KEY (Item_ID) REFERENCES Inventory_items(Item_ID)
);

-- Table storing sales
CREATE TABLE IF NOT EXISTS Sales(
Sale_ID INT UNSIGNED AUTO_INCREMENT,
Branch_ID SMALLINT UNSIGNED NOT NULL,
Sale_date_time TIMESTAMP NOT NULL,
Is_card_payment BOOL NOT NULL,
Is_deleted Bool NOT NULL DEFAULT 0,
PRIMARY KEY (Sale_ID),
FOREIGN KEY (Branch_ID) REFERENCES Branches(Branch_ID)
);

-- Table storing products
CREATE TABLE IF NOT EXISTS Sale_products(
Sale_ID INT UNSIGNED,
Product_ID SMALLINT UNSIGNED,
Product_quantity SMALLINT UNSIGNED NOT NULL,
Is_deleted Bool NOT NULL DEFAULT 0,
PRIMARY KEY(Sale_ID, Product_ID),
FOREIGN KEY (Sale_ID) REFERENCES Sales(Sale_ID),
FOREIGN KEY (Product_ID) REFERENCES Products(Product_ID)
);

-- Table storing branch stock
CREATE TABLE IF NOT EXISTS Item_stock(
Stock_ID MEDIUMINT UNSIGNED AUTO_INCREMENT,
Item_ID SMALLINT UNSIGNED NOT NULL,
Branch_ID SMALLINT UNSIGNED NOT NULL,
Item_quantity SMALLINT UNSIGNED NOT NULL,
PRIMARY KEY (Stock_ID),
FOREIGN KEY (Item_ID) REFERENCES Inventory_items(Item_ID),
FOREIGN KEY (Branch_ID) REFERENCES Branches(Branch_ID),
UNIQUE(Item_ID, Branch_ID)
);

-- Table storing the ingredients required to make 1 of a product
CREATE TABLE IF NOT EXISTS Product_ingredients(
Product_ID SMALLINT UNSIGNED,
Ingredient_ID SMALLINT UNSIGNED,
Ingredient_quantity SMALLINT UNSIGNED NOT NULL,
PRIMARY KEY (Product_ID, Ingredient_ID),
FOREIGN KEY (Ingredient_ID) REFERENCES Inventory_items(Item_ID),
FOREIGN KEY (Product_ID) REFERENCES Products(Product_ID)
);

/*Role creation
--------------------------------------------------------------*/
-- Roles to be used as templates for user accounts
/*Roles
Baker
Delivery_driver
Shop assistant
Till
*/
-- Manager account permissions must be asigned bespokley around role specifics

-- Baker
CREATE ROLE IF NOT EXISTS 'Baker';
GRANT SELECT ON Bakery_stock.Deliveries TO 'Baker';
GRANT SELECT ON Bakery_stock.Delivery_items TO 'Baker';
GRANT UPDATE ON Bakery_stock.Delivery_items TO 'Baker';
GRANT INSERT ON Bakery_stock.Delivery_items TO 'Baker';
GRANT DELETE ON Bakery_stock.Delivery_items TO 'Baker';
GRANT SELECT ON Bakery_stock.Inventory_items TO 'Baker';
GRANT SELECT ON Bakery_stock.Products TO 'Baker';
GRANT SELECT ON Bakery_stock.Item_stock TO 'Baker';
GRANT UPDATE ON Bakery_stock.Item_stock TO 'Baker';
GRANT INSERT ON Bakery_stock.Item_stock TO 'Baker';
GRANT SELECT ON Bakery_stock.Product_ingredients TO 'Baker';

-- Delivery_driver
CREATE ROLE IF NOT EXISTS 'Delivery_driver';
GRANT SELECT ON Bakery_stock.Branches TO 'Delivery_driver';
GRANT SELECT ON Bakery_stock.Deliveries TO 'Delivery_driver';
GRANT UPDATE ON Bakery_stock.Deliveries TO 'Delivery_driver';
GRANT INSERT ON Bakery_stock.Deliveries TO 'Delivery_driver';
GRANT DELETE ON Bakery_stock.Deliveries TO 'Delivery_driver';
GRANT SELECT ON Bakery_stock.Delivery_items TO 'Delivery_driver';
GRANT UPDATE ON Bakery_stock.Delivery_items TO 'Delivery_driver';
GRANT INSERT ON Bakery_stock.Delivery_items TO 'Delivery_driver';
GRANT DELETE ON Bakery_stock.Delivery_items TO 'Delivery_driver';
GRANT SELECT ON Bakery_stock.Inventory_items TO 'Delivery_driver';
GRANT SELECT ON Bakery_stock.Products TO 'Delivery_driver';
GRANT SELECT ON Bakery_stock.Item_stock TO 'Delivery_driver';

-- Shop_assistant
CREATE ROLE IF NOT EXISTS 'Shop_assistant';
GRANT SELECT ON Bakery_stock.Deliveries TO 'Shop_assistant';
GRANT SELECT ON Bakery_stock.Delivery_items TO 'Shop_assistant';
GRANT UPDATE ON Bakery_stock.Delivery_items TO 'Shop_assistant';
GRANT INSERT ON Bakery_stock.Delivery_items TO 'Shop_assistant';
GRANT DELETE ON Bakery_stock.Delivery_items TO 'Shop_assistant';
GRANT SELECT ON Bakery_stock.Products TO 'Shop_assistant';
GRANT SELECT ON Bakery_stock.Sales TO 'Shop_assistant';
GRANT SELECT ON Bakery_stock.Sale_products TO 'Shop_assistant';
GRANT SELECT ON Bakery_stock.Item_stock TO 'Shop_assistant';
GRANT UPDATE ON Bakery_stock.Item_stock TO 'Shop_assistant';
GRANT INSERT ON Bakery_stock.Item_stock TO 'Shop_assistant';

-- Till
CREATE ROLE IF NOT EXISTS 'Till';
GRANT INSERT ON Bakery_stock.Sales TO 'Till';
GRANT INSERT ON Bakery_stock.Sale_products TO 'Till';

/*User account creation
--------------------------------------------------------------*/
-- User accounts must be linked to a host at a location
-- Passwords are rejected if they are shorter than 8 charecters or do not have 1 numeric, 1 lowercase, 1 upercase and 1 special charecter

-- Example account 1
CREATE USER IF NOT EXISTS 'BobbyM'@'localhost' IDENTIFIED BY 'Gr2n2r9*L02f';
GRANT 'Baker' TO 'BobbyM'@'localhost';
SET DEFAULT ROLE 'Baker' TO 'BobbyM'@'localhost';

-- Example account 2
CREATE USER IF NOT EXISTS'RossyE'@'localhost' IDENTIFIED BY '_Cakery8769_';
GRANT 'Shop_assistant' TO 'RossyE'@'localhost';
SET DEFAULT ROLE 'Shop_assistant' TO 'RossyE'@'localhost';