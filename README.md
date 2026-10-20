# SEC Financial Statements Analysis (SQL)

Analysis of the U.S. SEC **Financial Statement Data Sets** (2026 Q3) in **MySQL**: the numbers companies report in their official 10-Q and 10-K filings.

**Status:** in progress (day 1 done: data loaded, first finance queries).

## Data
- Source: [SEC Financial Statement Data Sets](https://www.sec.gov/data-research/sec-markets-data/financial-statement-data-sets), file `2026q3.zip`
- `sub`: one row per filing (company, industry code, form, period, filing date): **6,516 rows**
- `num`: every number reported in every filing (tag, period, unit, value): **3,905,397 rows**

## What's in `SEC.sql`
1. Create the database and the `sub` and `num` tables
2. Bulk-load the tab-separated files with `LOAD DATA LOCAL INFILE` (date conversion, blanks to NULL)
3. Row-count checks against the source files
4. Indexes to speed up joins on 3.9M rows
5. Top 10 companies by quarterly revenue (10-Q, 3-month figures, USD, company totals only)
6. Gross margin and net margin for the top 10, using a CTE and conditional aggregation

## First results (quarter ended mid-2026)
| Company | Revenue ($bn) | Gross margin | Net margin |
|---|---|---|---|
| Amazon | 200.6 | n/a | 31.2% |
| Walmart | 187.9 | 26.1% | 3.4% |
| Alphabet | 119.8 | 61.6% | 93.7% |
| Apple | 109.4 | 50.1% | 27.2% |
| NVIDIA | 96.2 | 75.0% | 62.0% |

Gross margin is n/a where the company does not report gross profit or cost of revenue under the standard tags.

## Next
- Investigate Alphabet's unusually high net margin in the filing
- Margins by industry (SIC code)
- Findings write-up

## Tools
MySQL 8 · MySQL Workbench
