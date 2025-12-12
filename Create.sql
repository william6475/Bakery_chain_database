CREATE DATABASE bakery;
USE bakery;

-- Table for branches of the bakery chain
CREATE TABLE Branches(
Branch_ID SMALLINT UNSIGNED AUTO_INCREMENT,
Branch_name VARCHAR(100) NOT NULL,
Branch_phone_number VARCHAR(15),
Branch_city VARCHAR(50),
PRIMARY KEY (Branch_ID)
);

-- Table of deliveries (Delivered and to be delivered)
CREATE TABLE Deliveries(
Delivery_ID MEDIUMINT UNSIGNED AUTO_INCREMENT,
Branch_ID SMALLINT UNSIGNED NOT NULL,
Delivery_date_time TIMESTAMP NULL,
Is_delivered BOOL DEFAULT(0) NOT NULL,
PRIMARY KEY (Delivery_ID),
FOREIGN KEY(Branch_ID) REFERENCES Branches(Branch_ID)
);

-- Table of items which can be at branches
CREATE TABLE Inventory_items(
Item_ID SMALLINT UNSIGNED AUTO_INCREMENT,
Item_name VARCHAR(100),
Item_cost DECIMAL(8, 2),
Item_category ENUM('Product', 'Ingredient', 'Packaging', 'Other'),
PRIMARY KEY (Item_ID)
);

-- Table storing the items which each delivery holds
CREATE TABLE Delivery_items(
Delivery_ID MEDIUMINT UNSIGNED,
Item_ID SMALLINT UNSIGNED,
Item_quantity SMALLINT UNSIGNED NOT NULL,
PRIMARY KEY(Delivery_ID, Item_ID),
Foreign KEY (Delivery_ID) REFERENCES Deliveries(Delivery_ID),
FOREIGN KEY (Item_ID) REFERENCES Inventory_items(Item_ID)
);

-- Table storing product types
CREATE TABLE Products(
Product_ID SMALLINT UNSIGNED AUTO_INCREMENT,
Item_ID SMALLINT UNSIGNED UNIQUE NOT NULL,
Product_category ENUM('Cake', 'Bread', 'Pastry', 'Other') NOT NULL,
Product_price DECIMAL(6,2) NOT NULL,
Product_shelf_life_seconds MEDIUMINT UNSIGNED NOT NULL,
PRIMARY KEY(Product_ID),
FOREIGN KEY (Item_ID) REFERENCES Inventory_items(Item_ID)
);

-- Table storing sales
CREATE TABLE Sales(
Sale_ID INT UNSIGNED AUTO_INCREMENT,
Branch_ID SMALLINT UNSIGNED NOT NULL,
Sale_price DECIMAL (6,2) NOT NULL,
Sale_date Date NOT NULL,
Is_card_payment BOOL NOT NULL,
PRIMARY KEY (Sale_ID),
FOREIGN KEY (Branch_ID) REFERENCES Branches(Branch_ID)
);

-- Table storing products
CREATE TABLE Sale_products(
Sale_ID INT UNSIGNED,
Product_ID SMALLINT UNSIGNED,
Product_quantity SMALLINT UNSIGNED NOT NULL,
PRIMARY KEY(Sale_ID, Product_ID),
FOREIGN KEY (Sale_ID) REFERENCES Sales(Sale_ID),
FOREIGN KEY (Product_ID) REFERENCES Products(Product_ID)
);

-- Table storing branch stock
CREATE TABLE Item_stock(
Stock_ID MEDIUMINT UNSIGNED AUTO_INCREMENT,
Item_ID SMALLINT UNSIGNED NOT NULL,
Branch_ID SMALLINT UNSIGNED NOT NULL,
Item_quantity SMALLINT UNSIGNED NOT NULL,
PRIMARY KEY (Stock_ID),
FOREIGN KEY (Item_ID) REFERENCES Inventory_items(Item_ID),
FOREIGN KEY (Branch_ID) REFERENCES Branches(Branch_ID)
);

-- Table storing the ingredients required to make 1 of a product
CREATE TABLE Product_ingredients(
Product_ID SMALLINT UNSIGNED,
Item_ID SMALLINT UNSIGNED,
Ingredient_quantity SMALLINT UNSIGNED NOT NULL,
PRIMARY KEY (Product_ID, Ingredient_ID),
FOREIGN KEY (Item_ID) REFERENCES Items(Item_ID),
FOREIGN KEY (Product_ID) REFERENCES Products(Product_ID)
);