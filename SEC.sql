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


-- to create the 'num' table to store the financial values reported in each filing
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


-- to load SEC submission data from the tab-delimited num.txt file into the num table.
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

/* Step 3: top 10 companies by quarterly revenue (10-Q, latest quarter) */
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


/* Step 5: Alphabet profit bridge, quarter ended 30 Jun 2026.
   Operating income 40.77bn + non-operating income 97.98bn = pre-tax 138.75bn;
   less tax 26.56bn = net income 112.19bn. Most of the profit came from outside the main business. */
SELECT n.tag,
       ROUND(n.value / 1e9, 2) AS usd_bn
FROM num n
WHERE n.adsh = '0001652044-26-000071'
  AND n.qtrs = 1
  AND n.uom = 'USD'
  AND n.segments = ''
  AND n.coreg = ''
  AND n.ddate = 20260630
  AND n.tag IN ('Revenues',
                'CostOfRevenue',
                'OperatingIncomeLoss',
                'NonoperatingIncomeExpense',
                'IncomeLossFromContinuingOperationsBeforeIncomeTaxesExtraordinaryItemsNoncontrollingInterest',
                'IncomeTaxExpenseBenefit',
                'NetIncomeLoss')
ORDER BY FIELD(n.tag,
               'Revenues',
               'CostOfRevenue',
               'OperatingIncomeLoss',
               'NonoperatingIncomeExpense',
               'IncomeLossFromContinuingOperationsBeforeIncomeTaxesExtraordinaryItemsNoncontrollingInterest',
               'IncomeTaxExpenseBenefit',
               'NetIncomeLoss');


/* Step 6: net margin by industry (SIC division), all 10-Q filings, latest quarter */
WITH f AS (
  SELECT s.adsh, s.sic,
         MAX(CASE WHEN n.tag IN ('Revenues','RevenueFromContractWithCustomerExcludingAssessedTax')
                  THEN n.value END) AS rev,
         MAX(CASE WHEN n.tag = 'NetIncomeLoss' THEN n.value END) AS ni
  FROM sub s
  JOIN num n ON n.adsh = s.adsh
  WHERE s.form = '10-Q'
    AND n.qtrs = 1
    AND n.uom = 'USD'
    AND n.segments = ''
    AND n.coreg = ''
    AND n.ddate = s.period
    AND n.tag IN ('Revenues','RevenueFromContractWithCustomerExcludingAssessedTax','NetIncomeLoss')
  GROUP BY s.adsh, s.sic
)
SELECT CASE
         WHEN sic BETWEEN 100 AND 999 THEN 'Agriculture'
         WHEN sic BETWEEN 1000 AND 1499 THEN 'Mining & Oil'
         WHEN sic BETWEEN 1500 AND 1799 THEN 'Construction'
         WHEN sic BETWEEN 2000 AND 3999 THEN 'Manufacturing'
         WHEN sic BETWEEN 4000 AND 4999 THEN 'Transport & Utilities'
         WHEN sic BETWEEN 5000 AND 5199 THEN 'Wholesale'
         WHEN sic BETWEEN 5200 AND 5999 THEN 'Retail'
         WHEN sic BETWEEN 6000 AND 6799 THEN 'Finance & Real Estate'
         WHEN sic BETWEEN 7000 AND 8999 THEN 'Services'
         ELSE 'Other'
       END AS industry,
       COUNT(*) AS companies,
       ROUND(SUM(rev) / 1e9, 1) AS revenue_bn,
       ROUND(SUM(ni) / 1e9, 1) AS net_income_bn,
       ROUND(SUM(ni) / SUM(rev) * 100, 1) AS net_margin_pct
FROM f
WHERE rev > 0 AND ni IS NOT NULL
GROUP BY industry
ORDER BY net_margin_pct DESC;