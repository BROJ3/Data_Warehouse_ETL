--loading of dimensions and fact data from data staging into the datawarehouse

-- loading customer dimension
insert into crnjakt_zagimore_dw.Customer_Dimension(customerKey,custId,custName,custzip)
select customerKey, custId, custName, custzip
from Customer_Dimension;

-- loading product dimension
insert into crnjakt_zagimore_dw.Product_Dimension(productKey,productID, categoryID, vendorId, productName, vendorName, categoryName, productType, productSalesPrice, productDailyRentalPrice, productWeekly)
select productKey, productID, categoryID, vendorId, productName, vendorName, categoryName, productType, productSalesPrice, productDailyRentalPrice, productpriceweekly
from Product_Dimension;

--loading store dimension
insert into crnjakt_zagimore_dw.Store_Dimension(storeKey, storeid, regionId, regionName, storeZip )
select storeKey, storeid, regionId, regionName, storeZip
from Store_Dimension;

--loading calendar dimension
insert into crnjakt_zagimore_dw.Calendar_Dimension(calendarKey, FullDate, MonthYear, Year)
select calendarKey, FullDate, MonthYear, Year
from Calendar_Dimension;

--loading revenue
insert into crnjakt_zagimore_dw.Revenue_and_unit_sold(revenueGenerated, unitSold, TID, revenueType, customerKey, storeKey, productKey, calendarKey )
select revenueGenerated, unitSold, TID, revenueType, customerKey, storeKey, productKey, calendarKey
from Revenue_and_unit_sold;