CREATE TABLE productCategoryDimension AS
SELECT DISTINCT p.categoryId, p.categoryName 
FROM Product_Dimension p


ALTER TABLE productCategoryDimension
ADD COLUMN ProductCategoryKey INT AUTO_INCREMENT PRIMARY KEY

