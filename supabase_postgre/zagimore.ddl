CREATE TABLE zagimore.vendor
(vendorid CHAR(2) NOT NULL,
 vendorname VARCHAR(25) NOT NULL,
 PRIMARY KEY (vendorid));
 
CREATE TABLE zagimore.category
(categoryid CHAR(2) NOT NULL,
 categoryname VARCHAR(25) NOT NULL,
 PRIMARY KEY (categoryid));
 
CREATE TABLE zagimore.product
(productid CHAR(3) NOT NULL,
 productname VARCHAR(25) NOT NULL,
 productprice NUMERIC (7,2) NOT NULL,
 vendorid CHAR(2) NOT NULL,
 categoryid CHAR(2) NOT NULL,
 PRIMARY KEY (productid),
 FOREIGN KEY (vendorid)
 REFERENCES zagimore.vendor(vendorid),
 FOREIGN KEY (categoryid) REFERENCES zagimore.category(categoryid));
 
CREATE TABLE zagimore.region
(regionid CHAR NOT NULL,
 regionname VARCHAR(25) NOT NULL,
 PRIMARY KEY (regionid));
 
CREATE TABLE zagimore.store
(storeid VARCHAR(3) NOT NULL,
 storezip CHAR(5) NOT NULL,
 regionid CHAR NOT NULL,
 PRIMARY KEY (storeid),
 FOREIGN KEY (regionid) REFERENCES zagimore.region(regionid));
 
CREATE TABLE zagimore.customer
(customerid CHAR(7) NOT NULL,
 customername VARCHAR(15) NOT NULL,
 customerzip CHAR(5) NOT NULL,
 PRIMARY KEY (customerid));
 
CREATE TABLE zagimore.salestransaction
(tid VARCHAR(8) NOT NULL,
 customerid CHAR(7) NOT NULL,
 storeid VARCHAR(3) NOT NULL,
 tdate DATE NOT NULL,
 PRIMARY KEY (tid),
 FOREIGN KEY (customerid) REFERENCES zagimore.customer(customerid),
 FOREIGN KEY (storeid)REFERENCES zagimore.store(storeid));
 
CREATE TABLE zagimore.soldvia
(productid CHAR(3) NOT NULL,
 tid VARCHAR(8) NOT NULL,
 noofitems INT NOT NULL,
 PRIMARY KEY (productid, tid),
 FOREIGN KEY (productid) REFERENCES zagimore.product(productid),
 FOREIGN KEY (tid) REFERENCES zagimore.salestransaction(tid));
 
 
CREATE TABLE zagimore.rentalProducts
(productid CHAR(3) NOT NULL,
 productname VARCHAR(25) NOT NULL,
 vendorid CHAR(2) NOT NULL,
 categoryid CHAR(2) NOT NULL,
 productpricedaily NUMERIC(7,2) NOT NULL,
 productpriceweekly NUMERIC(7,2) NOT NULL,
 PRIMARY KEY (productid),
 FOREIGN KEY (vendorid) REFERENCES zagimore.vendor(vendorid),
 FOREIGN KEY (categoryid) REFERENCES zagimore.category(categoryid));
 
CREATE TABLE zagimore.rentaltransaction
(tid VARCHAR(8) NOT NULL,
 customerid CHAR(7) NOT NULL,
 storeid VARCHAR(3) NOT NULL,
 tdate DATE NOT NULL,
 PRIMARY KEY (tid),
 FOREIGN KEY (customerid) REFERENCES zagimore.customer(customerid),
 FOREIGN KEY (storeid) REFERENCES zagimore.store(storeid));
 
CREATE TABLE zagimore.rentvia
  (productid CHAR(3) NOT NULL,
  tid VARCHAR(8) NOT NULL,
  rentaltype CHAR(1) NOT NULL,
  duration INTEGER NOT NULL CHECK (duration < 100),
  PRIMARY KEY (productid, tid),
  FOREIGN KEY (productid) REFERENCES zagimore.rentalProducts(productid),
  FOREIGN KEY (tid) REFERENCES zagimore.rentaltransaction(tid)
);
