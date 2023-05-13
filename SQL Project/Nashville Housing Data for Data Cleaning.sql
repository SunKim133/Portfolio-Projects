/*

Cleaning Data in SQL Queries

*/

SELECT *
FROM [Portfolio Project].dbo.[Nashville Housing Data for Data Cleaning]	



---------------------------------------------------------------------------------------------------------------------------

-- Standardise Date Format

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM [Portfolio Project].dbo.[Nashville Housing Data for Data Cleaning]

UPDATE [Nashville Housing Data for Data Cleaning]
SET SaleDate = CONVERT(Date, SaleDate)


SELECT *
FROM [Portfolio Project].dbo.[Nashville Housing Data for Data Cleaning]	



---------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address Data

SELECT *
FROM [Portfolio Project].dbo.[Nashville Housing Data for Data Cleaning]
--WHERE PropertyAddress is null
ORDER BY ParcelID

-- PropertyAddress column has null values. I will fill those nulls using other rows that have same ParcelID and proper property address.

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM [Portfolio Project].dbo.[Nashville Housing Data for Data Cleaning] a
JOIN [Portfolio Project].dbo.[Nashville Housing Data for Data Cleaning] b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null


UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM [Portfolio Project].dbo.[Nashville Housing Data for Data Cleaning] a
JOIN [Portfolio Project].dbo.[Nashville Housing Data for Data Cleaning] b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null



---------------------------------------------------------------------------------------------------------------------------

-- Break out PropertyAddress into individual columns (Address, City)

SELECT PropertyAddress
FROM [Portfolio Project].dbo.[Nashville Housing Data for Data Cleaning]


SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM [Portfolio Project].dbo.[Nashville Housing Data for Data Cleaning]



ALTER TABLE [Nashville Housing Data for Data Cleaning]
ADD PropertySplitAddress Nvarchar(255);

UPDATE [Nashville Housing Data for Data Cleaning]
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE [Nashville Housing Data for Data Cleaning]
ADD PropertySplitCity Nvarchar(255);

UPDATE [Nashville Housing Data for Data Cleaning]
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))



---------------------------------------------------------------------------------------------------------------------------

-- Break out OwnerAddress into individual columns (Address, City)

SELECT OwnerAddress
FROM [Portfolio Project].dbo.[Nashville Housing Data for Data Cleaning]


SELECT
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM [Portfolio Project].dbo.[Nashville Housing Data for Data Cleaning]



ALTER TABLE [Nashville Housing Data for Data Cleaning]
ADD OwnerSplitAddress Nvarchar(255);

UPDATE [Nashville Housing Data for Data Cleaning]
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE [Nashville Housing Data for Data Cleaning]
ADD OwnerSplitCity Nvarchar(255);

UPDATE [Nashville Housing Data for Data Cleaning]
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE [Nashville Housing Data for Data Cleaning]
ADD OwnerSplitState Nvarchar(255);

UPDATE [Nashville Housing Data for Data Cleaning]
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)



---------------------------------------------------------------------------------------------------------------------------

-- Change 1 and 0 to Yes and No in "Sold as Vacant" Column

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM [Portfolio Project].dbo.[Nashville Housing Data for Data Cleaning]
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant,
	   CASE WHEN SoldAsVacant = 1 THEN 'Yes'
			WHEN SoldAsVacant = 0 THEN 'No'
			ELSE SoldAsVacant
		END
FROM [Portfolio Project].dbo.[Nashville Housing Data for Data Cleaning]


UPDATE [Nashville Housing Data for Data Cleaning]
SET SoldAsVacant = 
	   CASE WHEN SoldAsVacant = 1 THEN 'Yes'
			WHEN SoldAsVacant = 0 THEN 'No'
			ELSE SoldAsVacant
		END


---------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH RowNumCTE AS(
SELECT *,
	   ROW_NUMBER() OVER (
			PARTITION BY ParcelID,
						 PropertyAddress,
						 SalePrice,
						 SaleDate,
						 LegalReference
						 ORDER BY UniqueID
						 ) row_num
FROM [Portfolio Project].dbo.[Nashville Housing Data for Data Cleaning]
--ORDER BY ParcelID
)
SELECT *
--DELETE
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress



---------------------------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

ALTER TABLE [Portfolio Project].dbo.[Nashville Housing Data for Data Cleaning]
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE [Portfolio Project].dbo.[Nashville Housing Data for Data Cleaning]
DROP COLUMN SaleDate

SELECT *
FROM [Portfolio Project].dbo.[Nashville Housing Data for Data Cleaning]