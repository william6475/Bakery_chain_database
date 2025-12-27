-- Run the Create and Insert files before executing
USE Bakery_stock;

/*Delivery cost (View for curent/future months and table for past months)
-----------------------------------------------------*/
-- View for cost of deliveries in this month and future months
Create VIEW Delivery_cost_current_future_months AS
SELECT D.Delivery_ID, Sum_cost.Delivery_cost_sum FROM Deliveries AS D
INNER JOIN (
	SELECT SUM(Item_cost * Item_quantity) AS Delivery_cost_sum, Ditems.Delivery_ID FROM Delivery_items AS Ditems
	INNER JOIN Inventory_items AS Iitems ON Iitems.Item_ID = Ditems.Item_ID 
	GROUP BY Delivery_ID
) AS Sum_cost ON Sum_cost.Delivery_ID = D.Delivery_ID
WHERE YEAR(Delivery_date_time) * 100 + MONTH(Delivery_date_time) >= YEAR(CURDATE()) * 100 + MONTH(CURDATE())
ORDER BY Delivery_ID;
-- Deliveries filtered by date to find deliveries in curent or future months then delivery cost summed within subquery using sum and groupby on Item_cost * Item_quantity

GRANT SELECT ON Bakery_stock.Delivery_cost_current_future_months TO 'Baker';
GRANT SELECT ON Bakery_stock.Delivery_cost_current_future_months TO 'Delivery_driver';
GRANT SELECT ON Bakery_stock.Delivery_cost_current_future_months TO 'Shop_assistant';

-- Table storing the cost of deliveries from past months
CREATE TABLE Delivery_cost_past_months(
Delivery_ID MEDIUMINT UNSIGNED UNIQUE,
Delivery_cost DECIMAL(8,2),
PRIMARY KEY(Delivery_ID),
FOREIGN KEY (Delivery_ID) REFERENCES Deliveries(Delivery_ID)
);

GRANT SELECT ON Bakery_stock.Delivery_cost_past_months TO 'Baker';
GRANT SELECT ON Bakery_stock.Delivery_cost_past_months TO 'Delivery_driver';
GRANT SELECT ON Bakery_stock.Delivery_cost_past_months TO 'Shop_assistant';

-- Insert the data from before the database was in use into the Delivery_cost_past_months table
INSERT INTO Delivery_cost_past_months (Delivery_ID, Delivery_cost)
SELECT D.Delivery_ID, Sum_cost.Delivery_cost_sum FROM Deliveries AS D
INNER JOIN (
	SELECT SUM(Item_cost * Item_quantity) AS Delivery_cost_sum, Ditems.Delivery_ID FROM Delivery_items AS Ditems
	INNER JOIN Inventory_items AS Iitems ON Iitems.Item_ID = Ditems.Item_ID 
	GROUP BY Delivery_ID
	) AS Sum_cost ON Sum_cost.Delivery_ID = D.Delivery_ID
WHERE EXTRACT(YEAR_MONTH FROM Delivery_date_time) < EXTRACT(YEAR_MONTH FROM CURDATE())
ORDER BY Delivery_ID;

-- Stored procedure to insert the costs of last month's deliveries into Delivery_cost_past_months
DELIMITER $$
CREATE PROCEDURE Monthly_delivery_cost()
BEGIN
INSERT INTO Delivery_cost_past_months (Delivery_ID, Delivery_cost)
SELECT D.Delivery_ID, Sum_cost.Delivery_cost_sum FROM Deliveries AS D
INNER JOIN (
	SELECT SUM(Item_cost * Item_quantity) AS Delivery_cost_sum, Ditems.Delivery_ID FROM Delivery_items AS Ditems
	INNER JOIN Inventory_items AS Iitems ON Iitems.Item_ID = Ditems.Item_ID 
	GROUP BY Delivery_ID
) AS Sum_cost ON Sum_cost.Delivery_ID = D.Delivery_ID
WHERE EXTRACT(YEAR_MONTH FROM Delivery_date_time) = EXTRACT(YEAR_MONTH FROM DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
ORDER BY Delivery_ID;
END $$
DELIMITER ;

-- An event to call the Monthly_delivery_cost stored procedure at the begining of each month
DELIMITER $$
CREATE EVENT Insert_last_month_delivery_cost
ON SCHEDULE EVERY 1 MONTH
STARTS CONCAT(DATE_ADD(LAST_DAY(CURDATE()), INTERVAL 1 DAY), ' 00:00:00')
DO
BEGIN
CALL Monthly_delivery_cost;
END $$
DELIMITER ;

/*Sale cost (View for curent/future months and table for past months)
-----------------------------------------------------*/
-- View for cost of sales in this month and future months
Create VIEW Sale_cost_current_future_months AS
SELECT S.Sale_ID, Sum_cost.`Sale_cost_sum` FROM Sales AS S
INNER JOIN (
	SELECT SUM(Iitems.Item_cost * Sproducts.Product_quantity) AS Sale_cost_sum, Sproducts.Sale_ID FROM Sale_products AS Sproducts
	INNER JOIN Products AS P ON P.Product_ID = Sproducts.Product_ID
	INNER JOIN Inventory_items AS Iitems ON Iitems.Item_ID = P.Item_ID
	GROUP BY Sale_ID
) AS Sum_cost ON Sum_cost.Sale_ID = S.Sale_ID
WHERE YEAR(Sale_date_time) * 100 + MONTH(Sale_date_time) >= YEAR(CURDATE()) * 100 + MONTH(CURDATE())
ORDER BY Sale_ID;
-- Sales filtered by date to find sales in curent or future months then sale cost summed within subquery using sum and groupby on Sale_cost * Product_quantity

GRANT SELECT ON Bakery_stock.Sale_cost_current_future_months TO 'Shop_assistant';

-- Table storing the cost of sales from past months
CREATE TABLE Sale_cost_past_months(
Sale_ID INT UNSIGNED UNIQUE,
Sale_cost DECIMAL(8,2),
PRIMARY KEY(Sale_ID, Sale_date_time),
FOREIGN KEY (Sale_ID) REFERENCES Sales(Sale_ID)
);

GRANT SELECT ON Bakery_stock.Sale_cost_past_months TO 'Shop_assistant';

-- Insert the data from before the database was in use into Sale_cost_past_months
INSERT INTO Sale_cost_past_months (Sale_ID, Sale_cost)
SELECT S.Sale_ID, Sum_cost.Sale_cost_sum FROM Sales AS S
INNER JOIN (
	SELECT SUM(Iitems.Item_cost * Sproducts.Product_quantity) AS Sale_cost_sum, Sproducts.Sale_ID FROM Sale_products AS Sproducts
	INNER JOIN Products AS P ON P.Product_ID = Sproducts.Product_ID
	INNER JOIN Inventory_items AS Iitems ON Iitems.Item_ID = P.Item_ID
	GROUP BY Sale_ID
) AS Sum_cost ON Sum_cost.Sale_ID = S.Sale_ID
WHERE EXTRACT(YEAR_MONTH FROM Sale_date_time) < EXTRACT(YEAR_MONTH FROM CURDATE())
ORDER BY Sale_ID;

-- Stored procedure to insert the cost of last months sale's into Sale_cost_past_months
DELIMITER $$
CREATE PROCEDURE Monthly_sales_cost()
BEGIN
INSERT INTO Sale_cost_past_months (Sale_ID, Sale_cost)
SELECT S.Sale_ID, Sum_cost.Sale_cost_sum FROM Sales AS S
INNER JOIN (
	SELECT SUM(Iitems.Item_cost * Sproducts.Product_quantity) AS Sale_cost_sum, Sproducts.Sale_ID FROM Sale_products AS Sproducts
	INNER JOIN Products AS P ON P.Product_ID = Sproducts.Product_ID
	INNER JOIN Inventory_items AS Iitems ON Iitems.Item_ID = P.Item_ID
	GROUP BY Sale_ID
) AS Sum_cost ON Sum_cost.Sale_ID = S.Sale_ID
WHERE EXTRACT(YEAR_MONTH FROM Sale_date_time) = EXTRACT(YEAR_MONTH FROM DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
ORDER BY Sale_ID;
END $$
DELIMITER ;

-- An event to call the Monthly_sales_cost stored procedure at the begining of each month
DELIMITER $$
CREATE EVENT Insert_last_month_sale_cost
ON SCHEDULE EVERY 1 MONTH
STARTS CONCAT(DATE_ADD(LAST_DAY(CURDATE()), INTERVAL 1 DAY), ' 00:00:00')
DO
BEGIN
CALL Monthly_sales_cost;
END $$
DELIMITER ;

/*Stored procedure to deduct ingredients from stock once products made
-----------------------------------------------------*/
DELIMITER $$
CREATE PROCEDURE Products_made(
IN Branch_ID SMALLINT UNSIGNED,
IN Product_ID SMALLINT UNSIGNED,
IN Quantity_made SMALLINT UNSIGNED
)
BEGIN
-- Deduct the ingredients used from the branch's stock
UPDATE Item_stock AS Istock
INNER JOIN (-- Finds the quantity of ingredients it takes to make the given quantity of the given product
	SELECT Iitems.Item_ID, Iitems.Item_name, Pingredients.Ingredient_quantity * Quantity_made AS Ingredients_used FROM Inventory_items AS Iitems
	INNER JOIN Product_ingredients AS Pingredients ON Pingredients.Ingredient_ID = Iitems.Item_ID
	WHERE Pingredients.Product_ID = Product_ID
) AS Ingredient_usage_information ON Istock.Item_ID = Ingredient_usage_information.Item_ID
SET Istock.Item_quantity = Istock.Item_quantity - Ingredient_usage_information.Ingredients_used
WHERE Istock.Branch_ID = Branch_ID;
END $$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE Bakery_stock.Products_made TO 'Baker';

/*Triggers to add delivered items to Item_stock once a delivery is delivered
-----------------------------------------------------*/
-- Adds delivery stock if Deliveries.Is_delivered updated to true
DELIMITER $$
CREATE TRIGGER Add_delivered_delivery_stock
AFTER UPDATE ON Deliveries
FOR EACH ROW
BEGIN
IF NEW.Is_delivered <> OLD.Is_delivered AND NEW.Is_delivered = TRUE
	THEN INSERT INTO Item_stock (Item_ID, Branch_ID, Item_quantity)
    -- Subquery used so the data that failed to insert can be reused within the update under an aliaise
    SELECT * FROM(
		SELECT Ditems.Item_ID, NEW.Branch_ID, Ditems.Item_quantity
		FROM Delivery_items AS Ditems
		WHERE Ditems.Delivery_ID = NEW.Delivery_ID) AS Failed_insert_data
		ON DUPLICATE KEY
		UPDATE Item_stock.Item_quantity = Item_stock.Item_quantity + Failed_insert_data.Item_quantity;
END IF;
END $$
DELIMITER ;

-- Adds delivery stock when a new Delivery_items record is inserted which corresponds to a delivered delivery
drop trigger Add_delivery_item_stock
DELIMITER $$
CREATE TRIGGER Add_delivery_stock_insert
AFTER INSERT ON Delivery_items
FOR EACH ROW
BEGIN
IF (SELECT Is_delivered FROM Deliveries
	WHERE Delivery_ID = NEW.Delivery_ID) = TRUE
	THEN INSERT INTO Item_stock (Item_ID, Branch_ID, Item_quantity)
	SELECT NEW.Item_ID, D.Branch_ID, NEW.Item_quantity
    FROM Deliveries AS D
    WHERE D.delivery_ID = NEW.Delivery_ID
    ON DUPLICATE KEY
    UPDATE Item_stock.Item_quantity = Item_stock.Item_quantity + NEW.Item_quantity;
END IF;
END $$
DELIMITER ;

-- Updates stock levels if the Item_quantity of a delivery item for a delivered item is updated
DELIMITER $$
CREATE TRIGGER Update_delivery_item_stock
AFTER UPDATE ON Delivery_items
FOR EACH ROW
BEGIN
IF NEW.Item_quantity <> OLD.Item_quantity
	-- If Item_quantity increased
	THEN IF NEW.Item_quantity > OLD.Item_quantity
		THEN INSERT INTO Item_stock (Item_ID, Branch_ID, Item_quantity)
		SELECT NEW.Item_ID, D.Branch_ID, NEW.Item_quantity
		FROM Deliveries AS D
        WHERE D.Delivery_ID = NEW.Delivery_ID
		ON DUPLICATE KEY
		UPDATE Item_stock.Item_quantity = Item_stock.Item_quantity + (NEW.Item_quantity - OLD.Item_quantity);
    
    -- If Item_quantity decreased
    ELSEIF NEW.Item_quantity < OLD.Item_quantity
		THEN INSERT INTO Item_stock (Item_ID, Branch_ID, Item_quantity)
		SELECT NEW.Item_ID, D.Branch_ID, NEW.Item_quantity
		FROM Deliveries AS D
        WHERE D.Delivery_ID = NEW.Delivery_ID
		ON DUPLICATE KEY
		UPDATE Item_stock.Item_quantity = Item_stock.Item_quantity - (OLD.Item_quantity - NEW.Item_quantity);
    END IF;
END IF;
END $$
DELIMITER ;

/*Trigger to deduct products from Inventory_stock once they have been sold
-----------------------------------------------------*/
DELIMITER $$
CREATE TRIGGER Deduct_sale_stock
AFTER INSERT ON Sale_products
FOR EACH ROW
BEGIN
UPDATE Item_stock AS Istock
INNER JOIN Inventory_items AS Iitems ON Iitems.Item_ID = Istock.Item_ID
INNER JOIN Products AS P ON P.item_ID = Iitems.Item_ID
INNER JOIN Sale_products AS Sproducts ON Sproducts.Product_ID = P.Product_ID
SET Istock.Item_quantity = Istock.Item_quantity - Sproducts.Product_quantity
WHERE NEW.Sale_ID = Sproducts.Sale_ID;
END $$
DELIMITER ;
