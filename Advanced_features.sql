-- Run the Create and Insert files before executing
/*
File contents:
-Views and materialised tables
-Stored procedures to be called by users
-Stock management automation
-Deletion management
*/

USE Bakery_stock;

/* Views and materialised tables
------------------------------------------------------------------------------------------------------------------------------*/

/*Delivery cost (View for current/future months and table for past months)
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
-- Deliveries filtered by date to find deliveries in current or future months then delivery cost summed within subquery using sum and groupby on Item_cost * Item_quantity

GRANT SELECT ON Bakery_stock.Delivery_cost_current_future_months TO 'Baker';
GRANT SELECT ON Bakery_stock.Delivery_cost_current_future_months TO 'Delivery_driver';
GRANT SELECT ON Bakery_stock.Delivery_cost_current_future_months TO 'Shop_assistant';

-- Table storing the cost of deliveries from past months
CREATE TABLE IF NOT EXISTS Delivery_cost_past_months(
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

-- An event to call the Monthly_delivery_cost stored procedure at the beginning of each month
DELIMITER $$
CREATE EVENT Insert_last_month_delivery_cost
ON SCHEDULE EVERY 1 MONTH
STARTS CONCAT(DATE_ADD(LAST_DAY(CURDATE()), INTERVAL 1 DAY), ' 00:00:00')
DO
BEGIN
CALL Monthly_delivery_cost;
END $$
DELIMITER ;

/*Sale cost (View for current/future months and table for past months)
-----------------------------------------------------*/
-- View for cost of sales in this month and future months
Create VIEW Sale_cost_current_future_months AS
SELECT S.Sale_ID, Sum_cost.Sale_cost_sum FROM Sales AS S
INNER JOIN (
	SELECT SUM(Iitems.Item_cost * Sproducts.Product_quantity) AS Sale_cost_sum, Sproducts.Sale_ID FROM Sale_products AS Sproducts
	INNER JOIN Products AS P ON P.Product_ID = Sproducts.Product_ID
	INNER JOIN Inventory_items AS Iitems ON Iitems.Item_ID = P.Item_ID
	GROUP BY Sale_ID
) AS Sum_cost ON Sum_cost.Sale_ID = S.Sale_ID
WHERE YEAR(Sale_date_time) * 100 + MONTH(Sale_date_time) >= YEAR(CURDATE()) * 100 + MONTH(CURDATE()) AND S.Is_deleted = FALSE
ORDER BY Sale_ID;
-- Sales filtered by date to find sales in current or future months then sale cost summed within subquery using sum and groupby on Sale_cost * Product_quantity

GRANT SELECT ON Bakery_stock.Sale_cost_current_future_months TO 'Shop_assistant';

-- Table storing the cost of sales from past months
CREATE TABLE IF NOT EXISTS Sale_cost_past_months(
Sale_ID INT UNSIGNED UNIQUE,
Sale_cost DECIMAL(8,2),
PRIMARY KEY(Sale_ID),
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
WHERE EXTRACT(YEAR_MONTH FROM Sale_date_time) < EXTRACT(YEAR_MONTH FROM CURDATE()) AND S.Is_deleted = FALSE
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
WHERE EXTRACT(YEAR_MONTH FROM Sale_date_time) = EXTRACT(YEAR_MONTH FROM DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) AND S.Is_deleted = FALSE
ORDER BY Sale_ID;
END $$
DELIMITER ;

-- An event to call the Monthly_sales_cost stored procedure at the beginning of each month
DELIMITER $$
CREATE EVENT Insert_last_month_sale_cost
ON SCHEDULE EVERY 1 MONTH
STARTS CONCAT(DATE_ADD(LAST_DAY(CURDATE()), INTERVAL 1 DAY), ' 00:00:00')
DO
BEGIN
CALL Monthly_sales_cost;
END $$
DELIMITER ;

/* Stored procedures to be called by users
------------------------------------------------------------------------------------------------------------------------------*/

-- Stored procedure to deduct ingredients from stock once products made
DELIMITER $$
CREATE PROCEDURE Products_made(
IN Param_branch_ID SMALLINT UNSIGNED,
IN Param_product_ID SMALLINT UNSIGNED,
IN Param_quantity_made SMALLINT UNSIGNED
)
BEGIN
UPDATE Item_stock AS Istock
INNER JOIN Inventory_items AS Iitems ON Iitems.Item_ID = Istock.Item_ID
INNER JOIN Product_ingredients AS Pingredients ON Pingredients.Ingredient_ID = Iitems.Item_ID
SET Istock.Item_quantity = GREATEST(CAST(Istock.Item_quantity AS SIGNED) - (CAST(Param_quantity_made AS SIGNED) * CAST(Pingredients.Ingredient_quantity AS SIGNED)), 0)
WHERE Param_branch_ID = Istock.Branch_ID AND Pingredients.Product_ID = Param_product_ID;
END $$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE Bakery_stock.Products_made TO 'Baker';

/* Stock management automation
------------------------------------------------------------------------------------------------------------------------------*/

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
    -- Subquery used so the data that failed to insert can be reused within the update under an alias
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
		UPDATE Item_stock.Item_quantity = GREATEST(CAST(Item_stock.Item_quantity AS SIGNED) + (CAST(NEW.Item_quantity AS SIGNED) - CAST(OLD.Item_quantity AS SIGNED)) , 0);
    
    -- If Item_quantity decreased
    ELSEIF NEW.Item_quantity < OLD.Item_quantity
		THEN INSERT INTO Item_stock (Item_ID, Branch_ID, Item_quantity)
		SELECT NEW.Item_ID, D.Branch_ID, NEW.Item_quantity
		FROM Deliveries AS D
        WHERE D.Delivery_ID = NEW.Delivery_ID
		ON DUPLICATE KEY
		UPDATE Item_stock.Item_quantity = GREATEST(CAST(Item_stock.Item_quantity AS SIGNED) - (CAST(OLD.Item_quantity AS SIGNED) - CAST(NEW.Item_quantity AS SIGNED)), 0);
    END IF;
END IF;
END $$
DELIMITER ;

/*Trigger to deduct products from Inventory_stock once they have been sold
-----------------------------------------------------*/

-- Deducts Sale_products from stock (Sold items)
DELIMITER $$
CREATE TRIGGER Deduct_sale_stock
AFTER INSERT ON Sale_products
FOR EACH ROW
BEGIN
UPDATE Item_stock AS Istock
INNER JOIN Inventory_items AS Iitems ON Iitems.Item_ID = Istock.Item_ID
INNER JOIN Products AS P ON P.item_ID = Iitems.Item_ID
INNER JOIN Sale_Products AS Sproducts ON Sproducts.Product_ID = P.Product_ID
SET Item_quantity = GREATEST(CAST(Istock.Item_quantity AS SIGNED) - CAST(NEW.Product_quantity AS SIGNED), 0)
WHERE Sproducts.Product_ID = NEW.Product_ID;
END $$
DELIMITER ;

/*Deletion management
------------------------------------------------------------------------------------------------------------------------------*/

/*Manually cascading deletes
-----------------------------------------------------*/

-- Marks sale_product records as deleted (Soft delete) when the corresponding sale is soft deleted
DELIMITER $$
CREATE TRIGGER Delete_sale_products
AFTER UPDATE ON Sales
FOR EACH ROW
BEGIN
IF NEW.Is_deleted <> OLD.Is_deleted AND NEW.Is_deleted = TRUE
	THEN UPDATE Sale_products
    SET Is_deleted = TRUE
    WHERE Sale_ID = NEW.Sale_ID;
END IF;
END $$
DELIMITER ;

-- Marks the corresponding product as deleted (Soft delete) and deletes corresponding Item_stock records when the corresponding inventory_item is marked as deleted
DELIMITER $$
CREATE TRIGGER Delete_product
AFTER UPDATE ON Inventory_items
FOR EACH ROW
BEGIN
IF NEW.Is_deleted <> OLD.Is_deleted AND NEW.Is_deleted = TRUE
	THEN
    DELETE FROM Item_stock WHERE Item_ID = OLD.Item_ID;
    
    UPDATE Products
    SET Is_deleted = TRUE
    WHERE Item_ID = NEW.Item_ID;
    SET @Triggered_prevent_product_delete = '';
END IF;
END $$
DELIMITER ;

-- Tells the Prevent_products_deletion trigger to allow the change to Product.Is_deleted as it is being performed by the Delete_product or Restore_product trigger
DELIMITER $$
CREATE TRIGGER Allow_delete_product
BEFORE UPDATE ON Inventory_items
FOR EACH ROW
BEGIN
IF NEW.Is_deleted <> OLD.Is_deleted
    THEN SET @Triggered_prevent_product_delete = 'Delete_product';
END IF;
END $$
DELIMITER ;

/*Manually cascading restore (soft un-delete)
-----------------------------------------------------*/

-- Restores sale_product records when the corresponding sale is restored
DELIMITER $$
CREATE TRIGGER Restore_sale_product
AFTER UPDATE ON Sales
FOR EACH ROW
BEGIN
IF NEW.Is_deleted <> OLD.Is_deleted AND NEW.Is_deleted = FALSE
	THEN UPDATE Sale_products
    SET Is_deleted = FALSE
    WHERE Sale_ID = NEW.Sale_ID;
END IF;
END $$
DELIMITER ;

-- Restores the corresponding product when an inventory_item is restored
DELIMITER $$
CREATE TRIGGER Restore_product
AFTER UPDATE ON Inventory_items
FOR EACH ROW
BEGIN
IF NEW.Is_deleted <> OLD.Is_deleted AND NEW.Is_deleted = FALSE
	THEN
    UPDATE Products
    SET Is_deleted = FALSE
    WHERE Item_ID = NEW.Item_ID;
    SET @Triggered_prevent_product_delete = '';
END IF;
END $$
DELIMITER ;

/*Delete restrictions
-----------------------------------------------------*/

-- Prevent users other than the Delete_product and Restore_product triggers from soft deleting a product
DELIMITER $$
CREATE TRIGGER Prevent_product_deletion
BEFORE UPDATE ON Products
FOR EACH ROW
BEGIN
IF NEW.Is_deleted <> OLD.Is_deleted AND (@Triggered_prevent_product_delete != 'Delete_product' OR @Triggered_prevent_product_delete IS NULL)
	THEN SET NEW.Is_deleted = OLD.Is_deleted;
END IF;
END $$
DELIMITER ;