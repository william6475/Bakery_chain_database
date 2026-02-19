**Project purpose**
This database enable stock tracking for a theoretical bakery with the purpose of overcoming stock management issues including overordering.



**Contents:**

* Requirements
* Creating the database
* File purpose and contents
* Soft deletes
* Cascading deletes and restores
* Deletion order(The order records must be deleted to avoid errors)
* Views
* Callable stored procedures
* Background triggers and stored procedures concerning users
* Other background triggers, stored procedures and events
* Role access levels



**Requirements**

Must be run using a MySQL database management system



If your MySQL version  is under 8.4.4, run this command:

INSTALL COMPONENT 'file://component\_validate\_password'; -- Enforces password strength requirements

To check your MySQL version run this command: SELECT VERSION();



**Creating the database**

To create the database, execute files within this order:

1\) Create.sql

1B)Insert\_and\_test.SQL (Run if you want the database filled with test data)

2)Advanced\_features.SQL



**File purpose and contents**

Create.sql

 	-Table creation statements

 	-Role creation

 	-User account creation



Insert\_and\_test.sql

 	-Test data insertion

 	-Tests to ensure database functionality

 		-Deletion tests

 		-Callable stored procedure tests

 		-Trigger tests

 		-Testing with challenging characters



Advanced\_features.sql

 	-Views and materialised tables

 	-Stored procedures to be called by users

 	-Stock management automation

 	-Deletion management



Sample\_queries.sql

 	- Example database queries



**Logical and physical ERD with materialisation tables?   what about views?      ----------------------------------------------------------------------------------------------------------------------
Data dictionary? Business logic?**



**Soft deletes**

Soft deletes delete records in a recoverable manor



To soft delete a record, change a record's Is\_deleted Boolean field to true



Soft deletes may be performed on these tables:

* Branches
* Inventory\_items
* Sales
* Products
* Sale products



**Cascading deletes and restores**

Cascading deletes automatically delete/soft delete records which correspond to a deleted record



Cascading deletes:

Table causing cascading delete     | Table to which cascading deletes applied | Type of cascading delete | Trigger which performs this cascading delete

Sales (When soft deleted)	   |Sale\_products                             |Soft                      |Delete\_sale\_products

Inventory\_items (When soft deleted)|Products                                  |Soft                      |Delete\_product

Inventory\_items(When soft deleted) |Item\_stock                                |Hard                      |Delete\_product



Cascading restores:

Table causing cascading restore    | Table to which cascading restore applied |Trigger which performs this cascading restore

Sale                    	   |Sale\_products                             |Delete\_sale\_products

Inventory\_item                     |Products                                  |Delete\_product



**Deletion order** (The order records must be deleted to avoid errors (Foreign key constraints))

Before deleting a record from the table on the left, corresponding records from the given tables must be deleted



Deliveries - Delivery\_cost\_past\_months



Products must be soft deleted by soft deleting the corresponding Inventory\_items record (By doing this a trigger will automatically soft delete the product)



**Views**

-Delivery\_cost\_current\_future\_months

&nbsp;	Sums the cost of the items included within a delivery for each delivery due to arrive this month or in future

-Sale\_cost\_current\_future\_months

&nbsp;	Sums the cost of the items sold within a sale for each sale made this month



**Callable stored procedures**

-Products made (Stored procedure)

&nbsp;	Deducts used ingredients from stock given the Branch\_ID, Product\_ID and quantity of product made



**Background triggers and stored procedures concerning users**



Stock automation:

-Add\_delivered\_delivery\_stock (Trigger)

&nbsp;	Adds delivery stock when a delivery is marked as delivered (By setting Is\_delivered to true)

-Add\_delivery\_stock\_insert (Trigger)

&nbsp;	When new items are added to a delivered delivery, adds these new items to stock

-Update\_delivery\_item\_stock (Trigger)

&nbsp;	If the quantity of an item within a delivery is changed, updates stock accordingly

-Deduct\_sale\_stock (Trigger)

&nbsp;	Deducts sold items from stock when a sale is made



Deletes and restores:

-Delete\_sale\_products (Trigger)

&nbsp;	Marks the products within a sale as deleted when the corresponding sale is deleted

-Delete\_product (Trigger)

&nbsp;	Marks the corresponding product and product stock as deleted when an item type (Inventory\_items record) is marked as 	deleted

-Restore\_sale\_product (Trigger)

&nbsp;	Restores (Marks as not deleted) the products within a sale when the corresponding sale is restored

-Restore\_product (Trigger)

&nbsp;	Restores (Marks as not deleted) the corresponding product when an item type (Inventory\_items record) is restored



**Other background triggers, stored procedures and events**

-Monthly\_delivery\_cost (Stored procedure)

&nbsp;	Inserts the last months delivery cost sums into the Delivery\_cost\_past\_months table

-Insert\_last\_month\_delivery\_cost (Event)

&nbsp;	Calls the Monthly\_delivery\_cost stored procedure at the end of each month to insert the delivery cost sums into 	the Delivery\_cost\_past\_months table

-Monthly\_sales\_cost(Stored procedure)

&nbsp;	Inserts the last months sale cost sums into the Sale\_cost\_past\_months table

-Insert\_last\_month\_sale\_cost (Event)

&nbsp;	Calls the Monthly\_sale\_cost stored procedure at the end of each month to insert the sale cost sums into the 	Sale\_cost\_past\_months table

-Allow\_delete\_product (Trigger)

&nbsp;	Stops the Prevent\_product\_deletion trigger from blocking a product from being marked as deleted when a permitted 	trigger is performing the delete (Delete\_product)

-Prevent\_product\_deletion(Trigger)

&nbsp;	Blocks a product from being marked as deleted unless it is indicated that a permited trigger (Delete\_product) is performing the delete via the user defined variable Triggered\_prevent\_product\_delete



**Role access levels**

Baker:

Deliveries - Select

Delivery\_items - Select, update, insert, delete

Inventory\_items - Select

Products - Select

Item stock - Select, update, insert

Product\_ingredients – Select

Deliver\_cost\_current\_future\_months – Select

Deliver\_cost\_past\_months – Select

Products\_made - Execute



Delivery driver:

Branches - Select

Deliveries - Select, update, insert, delete

Delivery\_items - Select, update, insert, delete

Inventory\_items- Select

Products - Select

Item\_stock – Select

Deliver\_cost\_current\_future\_months – Select

Deliver\_cost\_past\_months - Select



Shop assistant:

Deliveries - Select

Delivery\_items - Select, update, insert, delete

Products - Select

Sales - Select

Sale\_products – Select

Item\_stock - Select, update, insert

Deliver\_cost\_current\_future\_months – Select

Deliver\_cost\_past\_months – Select

Sale\_cost\_current\_future\_months – Select

Sale\_cost\_past\_months - Select



Till:

Sales - Insert

Sale\_products – Insert

