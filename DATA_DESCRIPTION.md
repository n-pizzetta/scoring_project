# DATA_DESCRIPTION.md

## Project Overview
This document provides an overview of the datasets used in this project. It describes the purpose of each dataset, the origin of the data, and the definitions of key fields. The datasets are primarily used for analyzing corporate bankruptcy risks and building predictive models for default and bankruptcy.

## Datasets Included
1. **Financial Data** (`financial_data.csv`): Contains firm-level financial metrics used as predictors.
2. **Market Data** (`market_data.csv`): Includes stock market information like price and volume for the companies.
3. **Bankruptcy Data** (`bankruptcy_data.csv`): Details bankruptcy events, including the type and date of bankruptcy, for each company.
4. **Link Table** (`link_table.csv`): Maps unique identifiers between datasets to merge company information from different sources.

## Field Descriptions

### 1. Financial Data (`financial_data.csv`)
This dataset contains annual financial information for each company, retrieved from Compustat. It includes key financial indicators and calculated ratios.

- **gvkey**: Unique identifier for each company in Compustat.
- **fyear**: Fiscal year of the data.
- **at**: Total assets of the company.
- **wcap**: Working capital.
- **re**: Retained earnings.
- **ebit**: Earnings before interest and taxes.
- **lt**: Long-term debt.
- **sale**: Total sales.
- **WCTA**: Working Capital to Total Assets ratio, calculated as `wcap / at`.
- **RETA**: Retained Earnings to Total Assets ratio, calculated as `re / at`.
- **EBTA**: EBIT to Total Assets ratio, calculated as `ebit / at`.
- **TLTA**: Total Liabilities to Total Assets ratio, calculated as `lt / at`.
- **SLTA**: Sales to Total Assets ratio, calculated as `sale / at`.

### 2. Market Data (`market_data.csv`)
This dataset contains daily stock market data for each company, sourced from CRSP. The data includes stock prices, returns, and trading volume.

- **permno**: Unique identifier for each stock in CRSP.
- **date**: Date of the trading data.
- **prc**: Daily stock price.
- **vol**: Daily trading volume.
- **shrout**: Number of shares outstanding.
- **ret**: Daily return on the stock.
- **market_cap**: Market capitalization, calculated as `prc * shrout`.
- **log_vol**: Log of trading volume.
- **vol_rolling**: 1-year rolling volatility based on daily returns.

### 3. Bankruptcy Data (`bankruptcy_data.csv`)
This dataset provides information on bankruptcy events for each company, derived from both Compustat and LoPucki’s Bankruptcy Database.

- **gvkey**: Unique identifier for each company in Compustat.
- **Disposition**: Reason for bankruptcy (e.g., “Chapter 7 at filing”) in LoPucki.
- **Chapter**: The chapter of the bankruptcy code under which the case proceeded (`7` for liquidation, `11` for reorganization) in LoPucki.
- **DateFiled**: Date the bankruptcy case was filed in LoPucki.
- **conm**: Company name in LoPucki.
- **dlrsn**: Deletion reason (`2` for bankruptcy, `3` for liquidation) in Compustat.
- **dldte**: Deletion date (if applicable) in Compustat.

### 4. Link Table (`link_table.csv`)
This table links identifiers between Compustat and CRSP to enable merging of financial and market data for each company.

- **gvkey**: Unique identifier for each company in Compustat.
- **permno**: Unique identifier for each stock in CRSP.
- **linkdt**: Start date of the link between Compustat and CRSP.
- **linkenddt**: End date of the link between Compustat and CRSP.

## Data Sources
- **WRDS (Wharton Research Data Services)**: Online platform that provides access to a wide range of financial, economic, and corporate data for academic and professional research. It serves as a central hub for databases like Compustat and CRSP.
- **Compustat**: Source of financial data, including balance sheets and income statements.
- **CRSP**: Source of stock market data, including daily prices, returns, and trading volume.
- **LoPucki Bankruptcy Database**: Source for detailed bankruptcy filing information, including type and date of filing.
- **Moody**: 

## Usage Notes
1. **Merging Datasets**: Use `gvkey` and `permno` from the **Link Table** to join financial data with market data.
2. **Filtering Data**: To focus on companies that have filed for bankruptcy, filter the `bankruptcy_data.csv` dataset by `Chapter` values (`7` for liquidation or `11` for reorganization).
3. **Target Variable (𝑌)**: The target variable for bankruptcy prediction is created by identifying companies with a bankruptcy date (`DateFiled` or `dldte`) within 1 year of the fiscal year (`fyear`).

## Additional Information
- **Handling Missing Values**: Some fields may contain missing values due to incomplete data or different reporting standards. It’s recommended to handle missing values according to the modeling needs.
- **Updating the Data**: As new data becomes available, the datasets can be updated by adding additional fiscal years or newly listed companies.
