-- Run the Create, Insert and Advanced_features files before executing
-- Validation queries to test weather writes and deletes have worked are commented out
USE Bakery_stock;

-- How many of a given item does a branch have?
SELECT Branch_name, Item_quantity FROM Item_stock  AS Istock
INNER JOIN Branches AS B ON Istock.Branch_ID = B.Branch_ID
INNER JOIN Inventory_items AS Iitems ON Istock.Item_ID = Iitems.Item_ID
WHERE Item_name = 'Tomato';
-- Uses Inventory_items to translate the item name into an Item_ID then finds the item stock for that Item_ID for each branch

-- When is a given branch receiving deliveries on a given day? 
SELECT Delivery_ID, Delivery_Date_time FROM Deliveries
WHERE EXTRACT(YEAR_MONTH FROM Delivery_date_time) = '201608'
AND Branch_ID = 7
ORDER BY Delivery_date_time;

-- What was a given branches sales revenue last month?
SELECT SUM(Sale_cost) AS Last_month_revenue FROM Sale_cost_past_months AS SaleC
INNER JOIN Sales AS S ON S.Sale_ID = SaleC.Sale_ID
WHERE EXTRACT(YEAR_MONTH FROM S.Sale_date_time) = EXTRACT(YEAR_MONTH FROM DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
AND S.Is_deleted IS NULL OR S.Is_deleted = 0
AND Branch_ID = 13;
-- Sums the sale costs from the Sale_cost_past_months table where the date is a month before the current month

-- How long until the next delivery is due to stock a given item?
SELECT MIN(Delivery_date_time) AS Delivery_date FROM Deliveries
WHERE NOW() < Delivery_date_time
AND Branch_ID = 13;

-- What is the name of a branch given only part of it?
SELECT Branch_name FROM Branches
WHERE Branch_name LIKE '%dian%';

-- What is a given products monthly sales?
SELECT DATE_FORMAT(S.Sale_date_time, '%Y-%M') AS Year_and_month, SUM(Sproducts.Product_quantity) AS Monthly_sales
FROM Sale_products AS Sproducts
NATURAL JOIN Sales AS S
WHERE Sproducts.Product_ID = '1' AND S.Is_deleted = FALSE
GROUP BY DATE_FORMAT(S.Sale_date_time, '%Y-%M')
ORDER BY DATE_FORMAT(S.Sale_date_time, '%Y-%M');

-- What ingredients are needed to make a product and how much of each ingredient?
SELECT Iitems.Item_name, Pingredients.Ingredient_quantity FROM Inventory_items AS Iitems
INNER JOIN Product_ingredients AS Pingredients ON Pingredients.Ingredient_ID = Iitems.Item_ID
WHERE Pingredients.Product_ID = 35;

-- How many of a given product can be made with a branch's currently available ingredients? (Null if none)
SELECT MIN(Istock.Item_quantity / Product_required_ingredients.Ingredient_quantity) AS Amount_able_to_be_made
FROM Item_stock AS Istock
INNER JOIN Branches AS B ON B.Branch_ID = Istock.Branch_ID
RIGHT JOIN (
	SELECT Iitems.Item_ID, Pingredients.Ingredient_quantity FROM Inventory_items AS Iitems
	INNER JOIN Product_ingredients AS Pingredients ON Pingredients.Ingredient_ID = Iitems.Item_ID
	WHERE Pingredients.Product_ID = 35 																-- Product_ID goes here
) AS Product_required_ingredients ON Product_required_ingredients.Item_ID = Istock.Item_ID
WHERE Istock.Branch_ID = 2 																			-- Branch_ID goes here
ORDER BY Istock.Item_ID;
/*Finds the amount of each ingredient required to make 1 of the given product within the subquery
then finds how much of these ingredients a given branch has in stock
Then divides the amount of ingredients in stock by the reqruied ingredients*/

-- Insert sale information after sale (Automatically deducts sold products from stock (Via Deduct_sale_stock trigger))
INSERT INTO Sales (Sale_ID, Branch_ID, Sale_date_time, Is_card_payment)
VALUES (1000 ,17, '1992-06-06 12:21:34', 1);
INSERT INTO Sale_products (Sale_ID, Product_ID, Product_quantity)
VALUES (1000, 23, 17);

-- Add delivery items to stock once delivered (Via Add_delivered_delivery_stock trigger)
-- SELECT Item_ID, Branch_ID, Item_quantity FROM Item_stock WHERE Item_ID = 104 AND Branch_ID = 9;
UPDATE Deliveries
SET Is_delivered = TRUE WHERE Delivery_ID = 9;
SELECT * FROM Deliveries WHERE Delivery_ID = 9;
-- SELECT Item_ID, Branch_ID, Item_quantity FROM Item_stock WHERE Item_ID = 104 AND Branch_ID = 9;

-- Deduct sold items from stock (Via Deduct_sale_stock trigger)
INSERT INTO Sales (Sale_ID, Branch_ID, Sale_date_time, Is_card_payment)
VALUES (1000 ,17, '1992-06-06 12:21:34', 1);
-- SELECT * FROM Sales WHERE Sale_ID = 1000;
-- SELECT * FROM Item_stock WHERE Branch_ID = 19 AND Item_ID = 12;
INSERT INTO Sale_products (Sale_ID, Product_ID, Product_quantity)
VALUES (1000, 12, 17);
-- SELECT * FROM Item_stock WHERE Branch_ID = 19 AND Item_ID = 12;

-- Deduct used ingredients from stock (Via Products_made stored procedure)
/*SELECT Branch_ID, Product_ID, Ingredient_quantity FROM Item_stock AS Istock
INNER JOIN Inventory_items AS Iitems ON Iitems.Item_ID = Istock.Item_ID
INNER JOIN Product_ingredients AS Pingredients ON Pingredients.Ingredient_ID = Iitems.Item_ID
WHERE Product_ID = 1 AND Branch_ID = 1;*/
CALL Products_made(1, 1, 3);
/*SELECT * FROM Product_ingredients WHERE Product_ID = 1;
SELECT Branch_ID, Product_ID, Ingredient_quantity FROM Item_stock AS Istock
INNER JOIN Inventory_items AS Iitems ON Iitems.Item_ID = Istock.Item_ID
INNER JOIN Product_ingredients AS Pingredients ON Pingredients.Ingredient_ID = Iitems.Item_ID
WHERE Product_ID = 1 AND Branch_ID = 1;*/

-- Delete deliveries when they are cancelled
-- SELECT * FROM Delivery_items WHERE Delivery_ID = 40;
DELETE FROM Delivery_items WHERE Delivery_ID = 40;
-- SELECT * FROM Delivery_items WHERE Delivery_ID = 40;
-- SELECT * FROM Deliveries WHERE Delivery_ID = 40;
DELETE FROM Delivery_cost_past_months WHERE Delivery_ID = 40;
DELETE FROM Deliveries WHERE Delivery_ID = 40;
-- SELECT * FROM Deliveries WHERE Delivery_ID = 40;

-- Delete a product when no longer sold (Cascade deleted from Inventory_items via Delete_product trigger)
-- SELECT Product_ID, Is_deleted FROM Products WHERE Product_ID = 24;
UPDATE Inventory_items SET Is_deleted = TRUE WHERE Item_ID = 15;
-- SELECT Product_ID, Is_deleted FROM Products WHERE Product_ID = 24;