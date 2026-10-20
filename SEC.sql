/* ============================================
   PROJECT: SEC Financial Statements Analysis
   Data: SEC Financial Statement Data Sets, 2026 Q3
   Tool: MySQL Workbench
   ============================================ */

-- to create database
CREATE DATABASE SEC;

-- to specify the db to use, which contains our tables
USE SEC;

-- Allow MySQL to load data from local files 
SET GLOBAL local_infile = 1;


-- to create the 'sub' table to store SEC filing submission metadata
CREATE TABLE sub (
  adsh CHAR(20) PRIMARY KEY,
  cik INT,
  name VARCHAR(150),
  sic SMALLINT,
  countryba CHAR(2),
  stprba CHAR(2),
  cityba VARCHAR(50),
  form VARCHAR(10),
  period DATE,
  fy SMALLINT,
  fp CHAR(2),
  filed DATE,
  fye CHAR(4),
  afs VARCHAR(5)
);


-- to load SEC submission data from the tab-delimited sub.txt file into the sub table.
LOAD DATA LOCAL INFILE 'C:\\SEC\\sub.txt'
INTO TABLE sub
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(adsh, cik, name, @sic, countryba, stprba, cityba, @skip, @skip, @skip,
 @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip, @skip,
 @skip, @skip, afs, @skip, fye, form, period, @fy, fp, filed, @skip, @skip,
 @skip, @skip, @skip, @skip)
SET sic = NULLIF(@sic, ''), fy = NULLIF(@fy, '');


-- to return the total number of records currently stored in the sub table.
SELECT COUNT(*) FROM sub;


-- to create the 'num' table to store every number reported in each filing (tag = what it is, value = the amount)
CREATE TABLE num (
  adsh CHAR(20),
  tag VARCHAR(256),
  version VARCHAR(20),
  ddate DATE,
  qtrs TINYINT,
  uom VARCHAR(20),
  segments TEXT,
  coreg VARCHAR(256),
  value DECIMAL(28,4),
  footnote TEXT
);


-- to load the financial values from the tab-delimited num.txt file into the num table.
LOAD DATA LOCAL INFILE 'C:\\SEC\\num.txt'
INTO TABLE num
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(adsh, tag, version, @ddate, @qtrs, uom, segments, coreg, @val, footnote)
SET ddate = STR_TO_DATE(@ddate, '%Y%m%d'),
    qtrs = NULLIF(@qtrs, ''),
    value = NULLIF(@val, '');

-- to return the total number of records currently stored in the num table.
SELECT COUNT(*) FROM num;


-- to create an index on the adsh column of the num table
CREATE INDEX idx_num_adsh ON num (adsh);


-- to create an index on the tag column of the num table
CREATE INDEX idx_num_tag ON num (tag(100));

-- to retrieve the top 10 companies with the highest quarterly revenue (10-Q filings)
SELECT s.name,
       s.period,
       ROUND(MAX(n.value) / 1e9, 1) AS revenue_bn_usd
FROM num n
JOIN sub s ON s.adsh = n.adsh
WHERE s.form = '10-Q'
  AND n.tag IN ('Revenues', 'RevenueFromContractWithCustomerExcludingAssessedTax')
  AND n.qtrs = 1
  AND n.uom = 'USD'
  AND n.segments = ''
  AND n.coreg = ''
  AND n.ddate = s.period
GROUP BY s.name, s.period
ORDER BY revenue_bn_usd DESC
LIMIT 10;


/* Step 4: gross and net margin, top 10 by revenue */
WITH f AS (
  SELECT s.name,
         n.adsh,
         MAX(CASE WHEN n.tag IN ('Revenues', 'RevenueFromContractWithCustomerExcludingAssessedTax') THEN n.value END) AS revenue,
         MAX(CASE WHEN n.tag = 'GrossProfit' THEN n.value END) AS gross_profit,
         MAX(CASE WHEN n.tag = 'CostOfRevenue' THEN n.value END) AS cost_of_revenue,
         MAX(CASE WHEN n.tag = 'NetIncomeLoss' THEN n.value END) AS net_income
  FROM num n
  JOIN sub s ON s.adsh = n.adsh
  WHERE s.form = '10-Q'
    AND n.tag IN ('Revenues', 'RevenueFromContractWithCustomerExcludingAssessedTax',
                  'GrossProfit', 'CostOfRevenue', 'NetIncomeLoss')
    AND n.qtrs = 1
    AND n.uom = 'USD'
    AND n.segments = ''
    AND n.coreg = ''
    AND n.ddate = s.period
  GROUP BY s.name, n.adsh
)
SELECT name,
       ROUND(revenue / 1e9, 1) AS revenue_bn,
       ROUND(COALESCE(gross_profit, revenue - cost_of_revenue) / revenue * 100, 1) AS gross_margin_pct,
       ROUND(net_income / revenue * 100, 1) AS net_margin_pct
FROM f
ORDER BY revenue DESC
LIMIT 10;