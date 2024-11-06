# Project Title: Bankruptcy Prediction Model

## Overview
This project aims to predict corporate bankruptcy using financial and market data. The dataset combines firm-level financial metrics, market data, and bankruptcy events to build a predictive model that classifies companies as likely to default or remain solvent.

## Data Sources
The data is derived from multiple sources:
- **Compustat**: Provides financial information, including balance sheets and income statements.
- **CRSP**: Contains daily stock market data, such as prices and returns.
- **LoPucki Bankruptcy Database**: Offers detailed bankruptcy filing records, including type and filing dates.
- **Moody's Annual Default Reports**: Source for detailed analysis of corporate bond defaults and credit rating changes.

For more information on the datasets created and used in this project, refer to `DATA_DESCRIPTION.md`.

## Project Structure

- `data/`: Contains the cleaned and merged datasets used for modeling.
- `models/`: Stores trained models and related files.
- `notebooks/`: Jupyter notebooks for modeling.
- `reports/`: Contains Quarto files for results presentation.
- `scripts`: Contains R scripts of functions used in our Quarto file report.
- `DATA_DESCRIPTION.md`: Detailed description of the datasets created, including key fields and sources.

## Building our dataset

We created our features and target variable using different sources from WRDS, Lopucki and Moody's reports.<br>
You can check our reports on the following links :
- [Building our target Y](https://n-pizzetta.github.io/scoring_project/dataset_build.html)
- [Building our features]
