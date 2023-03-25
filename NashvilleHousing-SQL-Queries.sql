-- NASHVILLE HOUSING PROJECT

-- Data Cleaning

-- Used table

SELECT *
FROM PortfolioProject..NashvilleHousing


-- Standardise Date Format
-- Removing unnecessary time

SELECT SaleDate, SaleDateConverted
FROM PortfolioProject..NashvilleHousing

-- This is not working

UPDATE PortfolioProject..NashvilleHousing
SET SaleDate = CONVERT(date, SaleDate)

-- So let's try it this way

ALTER TABLE PortfolioProject..NashvilleHousing
ADD SaleDateConverted Date;

UPDATE PortfolioProject..NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate)


-- Populate Property Address data where values are null

SELECT *
FROM PortfolioProject..NashvilleHousing
ORDER BY ParcelID

-- By analysing the above we can see that equal ParcelID corresponds to the same Property Address
-- So we can populate the Property Address this way

SELECT
	a.ParcelID,
	a.PropertyAddress,
	b.ParcelID,
	b.PropertyAddress,
	ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL


-- Breaking down Property Address into Individual Columns (Address, City)
-- Using SUBSTRING function

SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing

SELECT
	PropertyAddress,
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing

-- Adding column for Property Address

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitAddress nvarchar(50);

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

-- Adding column for Property City

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitCity nvarchar(50);

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress))

-- Validating Final result

SELECT
	PropertyAddress,
	PropertySplitAddress,
	PropertySplitCity
FROM PortfolioProject..NashvilleHousing


-- Breaking down Owner Address into Individual Columns (Address, City, State)
-- Using PARSENAME function

SELECT
	OwnerAddress,
	TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)) AS Address,
	TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)) AS City,
	TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)) AS State
FROM PortfolioProject..NashvilleHousing

-- Adding column for Owner Address

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitAddress nvarchar(50);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3))

-- Adding column for Owner City

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitCity nvarchar(50);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitCity = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2))

-- Adding column for Owner State

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitState nvarchar(50);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitState = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1))

-- Validating Final result

SELECT
	OwnerAddress,
	OwnerSplitAddress,
	OwnerSplitCity,
	OwnerSplitState
FROM PortfolioProject..NashvilleHousing


-- Changing values to Yes and No in "Sold as Vacant" field

SELECT
	DISTINCT(SoldAsVacant),
	COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant

SELECT
	SoldAsVacant,
	CASE
		WHEN SoldAsVacant = 1 THEN 'Yes'
		ELSE 'No'
		END
FROM PortfolioProject..NashvilleHousing

UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 1 THEN 'Yes'
					ELSE 'No' END


-- Remove duplicates (not a standard practice)

WITH CTE_RowNum AS
(
SELECT
	*,
	ROW_NUMBER() OVER (PARTITION BY
					 ParcelID,
					 PropertyAddress,
					 SalePrice,
					 SaleDate,
					 LegalReference
					 ORDER BY
						UniqueID
						) row_num
FROM PortfolioProject..NashvilleHousing
)
DELETE
FROM CTE_RowNum
WHERE row_num > 1


-- Delete unused columns
-- Just as an experiment as deleting columns in tables is not a good practice

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress, SaleDate

