-- SQL: Data Cleaning & Feature Engineering for Tourism Revenue and Political Stability Project

-- Assumes base table `tourism_data_raw` contains long-format panel data with these columns:
-- countryname, year, tourism_receipts, political_stability, household_consumption,
-- gdp_ppp, inflation, exchange_rate, unemployment, fdi, tourism_arrivals

-- Step 1: Create cleaned version of the dataset with only valid numeric records
CREATE TABLE tourism_cleaned AS
SELECT
    countryname,
    year,
    tourism_receipts,
    tourism_arrivals,
    political_stability,
    household_consumption,
    gdp_ppp,
    inflation,
    exchange_rate,
    unemployment,
    fdi
FROM tourism_data_raw
WHERE
    tourism_receipts IS NOT NULL AND
    political_stability IS NOT NULL AND
    household_consumption IS NOT NULL AND
    gdp_ppp IS NOT NULL AND
    inflation IS NOT NULL AND
    exchange_rate IS NOT NULL AND
    unemployment IS NOT NULL AND
    fdi IS NOT NULL;

-- Step 2: Add interaction term and quartile variables
ALTER TABLE tourism_cleaned
ADD COLUMN interaction REAL,
ADD COLUMN stability_quartile INTEGER;

-- Step 3: Compute interaction term (political stability * household consumption)
UPDATE tourism_cleaned
SET interaction = political_stability * household_consumption;

-- Step 4: Assign stability quartiles using a CTE + UPDATE (PostgreSQL style)
WITH ranked AS (
    SELECT
        countryname,
        year,
        political_stability,
        NTILE(4) OVER (ORDER BY political_stability) AS quartile
    FROM tourism_cleaned
)
UPDATE tourism_cleaned AS t
SET stability_quartile = r.quartile
FROM ranked AS r
WHERE t.countryname = r.countryname AND t.year = r.year;

-- Step 5 (Optional): Add year-flag columns for fixed effect dummies
ALTER TABLE tourism_cleaned ADD COLUMN is_2019 INTEGER;
UPDATE tourism_cleaned SET is_2019 = CASE WHEN year = 2019 THEN 1 ELSE 0 END;

-- Step 6: Create regression-ready view
CREATE VIEW tourism_regression_data AS
SELECT
    tourism_receipts,
    political_stability,
    household_consumption,
    interaction,
    gdp_ppp,
    inflation,
    exchange_rate,
    unemployment,
    fdi,
    tourism_arrivals,
    year,
    stability_quartile
FROM tourism_cleaned;
