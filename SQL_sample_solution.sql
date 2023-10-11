-- Show sales data table for all 3 years: 2015, 2016, 2017, order by date
select *
from Sales_2015
union all 
select *
from Sales_2016
union all 
select *
from Sales_2017
order by OrderDate, StockDate
-- Look at total order quantity by each product key and subcategory key
select s.productkey,
		p.ProductSubcategoryKey, 
		sum(s.OrderQuantity) as TotalOrderQuantity
from(
select *
from Sales_2015
union all 
select *
from Sales_2016
union all 
select *
from Sales_2017) as s
left join Products as p
on s.productkey=p.productkey
left join Product_Subcategories as sc
on sc.ProductSubcategoryKey=p.ProductSubcategoryKey
group by s.productkey,
		p.ProductSubcategoryKey

-- Look at total quantity of orders returned by each product key
select ProductKey, 
		sum(ReturnQuantity) as TotalReturnQuantity
from Returns
group by ProductKey

-- Look at the profit made (from orders made) and profit lost (from orders returned) by each category
with sub_order_table as (
select s.productkey,
		p.ProductSubcategoryKey, 
		sum(s.OrderQuantity) as TotalOrderQuantity
from(
select *
from Sales_2015
union all 
select *
from Sales_2016
union all 
select *
from Sales_2017) as s
left join Products as p
on s.productkey=p.productkey
left join Product_Subcategories as sc
on sc.ProductSubcategoryKey=p.ProductSubcategoryKey
group by s.productkey,
		p.ProductSubcategoryKey),
sub_return_table as (
select ProductKey, 
		sum(ReturnQuantity) as TotalReturnQuantity
from Returns
group by ProductKey)
select c.ProductCategoryKey,
		c.CategoryName,
		sum(TotalOrderQuantity*(p.ProductPrice-p.ProductCost)) as ProfitMade,
		sum(TotalReturnQuantity*(p.ProductPrice-p.ProductCost)) as ProfitLost
from sub_order_table as so
join sub_return_table as sr
on so.ProductKey=sr.ProductKey
left join products as p
on p.ProductKey=so.ProductKey
left join Product_Subcategories as sc
on p.ProductSubcategoryKey=sc.ProductSubcategoryKey
left join Product_Categories as c
on sc.ProductCategoryKey=c.ProductCategoryKey
group by c.ProductCategoryKey, c.CategoryName

-- Calculate the final sales result of each category
with sub_order_table as (
select s.productkey,
		p.ProductSubcategoryKey, 
		sum(s.OrderQuantity) as TotalOrderQuantity
from(
select *
from Sales_2015
union all 
select *
from Sales_2016
union all 
select *
from Sales_2017) as s
left join Products as p
on s.productkey=p.productkey
left join Product_Subcategories as sc
on sc.ProductSubcategoryKey=p.ProductSubcategoryKey
group by s.productkey,
		p.ProductSubcategoryKey),
sub_return_table as (
select ProductKey, 
		sum(ReturnQuantity) as TotalReturnQuantity
from Returns
group by ProductKey),
sum_table as (
select 
		sc.ProductCategoryKey,
		c.CategoryName,
		sum(TotalOrderQuantity*(p.ProductPrice-p.ProductCost)) as ProfitMade,
		sum(TotalReturnQuantity*(p.ProductPrice-p.ProductCost)) as ProfitLost
from sub_order_table as so
join sub_return_table as sr
on so.ProductKey=sr.ProductKey
left join products as p
on p.ProductKey=so.ProductKey
left join Product_Subcategories as sc
on p.ProductSubcategoryKey=sc.ProductSubcategoryKey
left join Product_Categories as c
on sc.ProductCategoryKey=c.ProductCategoryKey
group by sc.ProductCategoryKey,
		c.CategoryName)
select ProductCategoryKey,
		CategoryName,
		round((ProfitMade-ProfitLost),2) as SalesResult
from sum_table
order by SalesResult desc
