-- Run the Create, Insert and Advanced_features files before executing
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
AND Branch_ID = 13 GROUP BY EXTRACT(YEAR_MONTH FROM S.Sale_date_time);
-- Sums the sale costs from the Sale_cost_past_months table where the date is a month before the current month

-- How long until the next delivery is due to stock a given item?
SELECT MIN(Delivery_date_time) AS Delivery_date FROM Deliveries
WHERE NOW() < Delivery_date_time
AND Branch_ID = 13;

-- What is the name of a branch given only part of it?
SELECT Branch_name FROM Branches
WHERE Branch_name LIKE '%dian%';

-- What is a given products monthly sales?
SELECT DATE_FORMAT(Sales.Sale_date_time, '%Y-%M') AS Year_and_month, SUM(Sproducts.Product_quantity) AS Monthly_sales
FROM Sale_products AS Sproducts
NATURAL JOIN Sales
WHERE Sproducts.Product_ID = '1'
GROUP BY DATE_FORMAT(Sales.Sale_date_time, '%Y-%M')
ORDER BY DATE_FORMAT(Sales.Sale_date_time, '%Y-%M');

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