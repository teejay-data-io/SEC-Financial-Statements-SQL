# SEC Financial Statements Analysis (SQL)

Analysis of the U.S. SEC **Financial Statement Data Sets** (2026 Q3) in **MySQL**: the numbers companies report in their official 10-Q and 10-K filings.

**Status:** complete (all queries done; findings below).

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
7. Alphabet profit bridge: revenue to net income, line by line
8. Net margin by industry (SIC division) across ~3,000 quarterly filings

## First results (quarter ended mid-2026)
| Company | Revenue ($bn) | Gross margin | Net margin |
|---|---|---|---|
| Amazon | 200.6 | n/a | 31.2% |
| Walmart | 187.9 | 26.1% | 3.4% |
| Alphabet | 119.8 | 61.6% | 93.7% |
| Apple | 109.4 | 50.1% | 27.2% |
| NVIDIA | 96.2 | 75.0% | 62.0% |

Gross margin is n/a where the company does not report gross profit or cost of revenue under the standard tags.

## Why is Alphabet's net margin 93.7%?
| Line (quarter ended 30 Jun 2026) | $bn |
|---|---|
| Revenue | 119.80 |
| Cost of revenue | 45.94 |
| Operating income | 40.77 |
| Non-operating income | 97.98 |
| Income before tax | 138.75 |
| Income tax | 26.56 |
| Net income | 112.19 |

The core business earned $40.8bn (a 34% operating margin). Another $98.0bn came from **non-operating income**, outside the main business, which is what pushes net margin to 93.7%. The data sets do not say what that income is; the notes to Alphabet's 10-Q would.

## Net margin by industry
| Industry (SIC division) | Companies | Revenue ($bn) | Net income ($bn) | Net margin |
|---|---|---|---|---|
| Services | 709 | 680.4 | 177.9 | 26.1% |
| Mining & Oil | 123 | 99.7 | 20.7 | 20.7% |
| Manufacturing | 1,206 | 1,924.2 | 239.3 | 12.4% |
| Transport & Utilities | 216 | 581.7 | 68.2 | 11.7% |
| Retail | 175 | 916.0 | 99.2 | 10.8% |
| Finance & Real Estate | 524 | 1,005.6 | 101.4 | 10.1% |
| Agriculture | 21 | 12.4 | 1.1 | 8.8% |
| Construction | 45 | 62.3 | 3.6 | 5.8% |
| Wholesale | 73 | 351.6 | 6.7 | 1.9% |

## Key findings
- **Revenue is not profit.** Walmart books $187.9bn in a quarter but keeps 3.4%; NVIDIA keeps 62.0% of $96.2bn.
- **One company can make a whole industry look rich.** Alphabet alone is $112.2bn of Services' $177.9bn net income, and Amazon is $62.6bn of Retail's $99.2bn.
- **Always read below the operating line.** Alphabet's headline margin comes mostly from non-operating income, not from its core business.
- Wholesale runs on the thinnest margin (1.9%): high volume, little profit per dollar.

## Tools
MySQL 8 · MySQL Workbench
