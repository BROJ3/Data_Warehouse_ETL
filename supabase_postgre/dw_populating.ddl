-- Loading of dimensions and fact data from data staging into the data warehouse

-- Loading Customer Dimension
INSERT INTO warehouse.Customer_Dimension(customerKey, customerid, cname, czip)
SELECT customerkey, customerid, cname, czip
FROM staging.Customer_Dimension;

-- Loading Product Dimension
INSERT INTO warehouse.Product_Dimension(
  productkey, productname, vendorid, vendorname, categoryname, categoryid, productsalesprice, productdailyrentalprice, productweeklyrental, producttype, productid)
SELECT productkey, productname, vendorid, vendorname, categoryname, categoryid, productsalesprice, productdailyrentalprice, productweeklyrental, producttype, productid
FROM staging.Product_Dimension;

-- Loading Store Dimension
INSERT INTO warehouse.Store_Dimension(storekey, storeid, storezip, regionid, regionname)
SELECT storekey, storeid, storezip, regionid, regionname
FROM staging.Store_Dimension;


-- Loading Calendar Dimension
INSERT INTO warehouse.Calendar_Dimension(calendar_key, fulldate, monthyear, year)
SELECT calendar_key, fulldate, monthyear, year
FROM staging.Calendar_Dimension;

-- Loading Revenue
INSERT INTO warehouse.revenue(revenuetype, tid, customerkey, storekey, productkey, calendar_key, unitsolds, revenuegenerated)
SELECT revenuetype, tid, customerkey, storekey, productkey, calendar_key, unitsold, revenuegenerated
FROM staging.revenue;
