-- How many of a given item does a branch have?
-- Uses Inventory_items to translate the item name into an Item_ID then finds the item stock for that Item_ID for each branch
SELECT Branch_name, Item_quantity FROM Item_stock  AS Istock
INNER JOIN Branches AS B ON Istock.Branch_ID = B.Branch_ID
INNER JOIN Inventory_items AS Iitems ON Istock.Item_ID = Iitems.Item_ID
WHERE Item_name = 'Tomato';

-- What is the monthly sales revenue of a given branch?

-- What deliveries is a given branch receiving on a given day?

-- How well is a given product selling?

-- What are the best and worst sellers?

-- How many of a given product can be made with a branch's currently available ingredients?
