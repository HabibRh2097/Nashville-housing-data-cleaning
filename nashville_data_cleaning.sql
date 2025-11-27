/* ============================
    FULL NASHVILLE DATA CLEANING
=============================== */

-- 1) VIEW RAW DATA
SELECT *
FROM NashvilleHousing;



/* ======================================
   2) STANDARDIZE DATE FORMAT (CAST to DATE)
========================================= */

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate);



/* ======================================
   3) POPULATE NULL PROPERTY ADDRESSES
      USING OTHER ROWS WITH SAME ParcelID
========================================= */

UPDATE a
SET PropertyAddress = b.PropertyAddress
FROM NashvilleHousing a
JOIN NashvilleHousing b
    ON a.ParcelID = b.ParcelID
   AND a.UniqueID <> b.UniqueID       -- Avoid updating with itself
WHERE a.PropertyAddress IS NULL;



/* ======================================
   4) SPLIT PROPERTY ADDRESS INTO
      (Address, City)
========================================= */

-- Add new columns
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

GO

-- Fill them
UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
    PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));



/* ======================================
   5) SPLIT OWNER ADDRESS INTO
      (Address, City, State)
========================================= */

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

GO

-- PARSENAME splits backwards by dot, so replace commas first
UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    OwnerSplitCity    = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    OwnerSplitState   = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);


GO
/* ======================================
   6) CLEAN UP 'SoldAsVacant' COLUMN
      Standardize YES/NO
========================================= */

UPDATE NashvilleHousing
SET SoldAsVacant = 
    CASE 
        WHEN SoldAsVacant IN ('Y', 'Yes') THEN 'Yes'
        WHEN SoldAsVacant IN ('N', 'No')  THEN 'No'
        ELSE SoldAsVacant
    END;



/* ======================================
   7) REMOVE DUPLICATES
      Keep only the latest UniqueID
========================================= */

WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
               ORDER BY UniqueID
           ) AS row_num
    FROM NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1;



/* ======================================
   8) DROP USELESS COLUMNS
========================================= */

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress;



/* ======================================
   9) FINAL VIEW
========================================= */

SELECT *
FROM NashvilleHousing;
