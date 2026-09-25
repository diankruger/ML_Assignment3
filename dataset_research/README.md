# Dataset shortlist for Option 4

Retrieved and structurally checked on 2026-09-25. Files are original downloads, not cleaned or truncated. The ZIP was extracted into bike-sharing/.

Option 4 asks for five time series and a comparison of Elman, Jordan and multi-recurrent networks. The shortlist prioritizes compact numeric series and regular observation indexes. Each can be used as a univariate forecasting problem: predict the next target value from previous target values.

| Dataset | File | Observations | Frequency / coverage | Target |
|---|---|---:|---|---|
| Capital Bikeshare | bike-sharing/day.csv | 731 | Daily, 2011-01-01 to 2012-12-31 | cnt |
| Historical sunspots (fixed R benchmark) | sunspots.csv | 2,820 | Monthly, January 1749 to December 1983 | value |
| US electricity net generation | usmelec.csv | 486 | Monthly, January 1973 to June 2013 | value |
| US finished motor gasoline supplied | gasoline.csv | 1,355 | Weekly, 1991-2017 | value |
| Electricity transformer oil temperature | ETTh1.csv | 17,420 | Hourly, 2016-07-01 00:00 to 2018-06-26 19:00 | OT |

## Sources and download URLs

### Capital Bikeshare

- Documentation and citation: https://archive.ics.uci.edu/dataset/275/bike+sharing+dataset
- Download: https://archive.ics.uci.edu/static/public/275/bike+sharing+dataset.zip
- Use day.csv. The separate hour.csv file is not part of the recommended five or the audit.
- For the simplest forecasting setup use dteday and cnt. The same-day casual and registered counts sum to cnt and must not be used to forecast that day's total. Calendar variables are optional; future realized weather must not be treated as known in advance.
- Two years provide limited independent annual cycles. Day-to-day forecasting is a better starting point than long annual horizons.

### Historical sunspots

- Documentation: https://vincentarelbundock.github.io/Rdatasets/doc/datasets/sunspots.html
- Download: https://vincentarelbundock.github.io/Rdatasets/csv/datasets/sunspots.csv
- A fixed historical benchmark, not the latest recalibrated SILSO series. Keep the version and citation explicit.
- R documentation explains the distinction between fixed sunspots and the updated/recalibrated sunspot.month: https://www.stat.math.ethz.ch/CRAN/doc/manuals/r-patched/packages/datasets/refman/datasets.html
- Zero values are legitimate. Avoid ordinary MAPE because the target can be zero.

### US electricity net generation

- Documentation: https://vincentarelbundock.github.io/Rdatasets/doc/fpp2/usmelec.html
- Download: https://vincentarelbundock.github.io/Rdatasets/csv/fpp2/usmelec.csv
- EIA series packaged in fpp2; values are billions of kWh. This file has 486 observations and no trailing missing row.

### US finished motor gasoline supplied

- Documentation: https://vincentarelbundock.github.io/Rdatasets/doc/fpp2/gasoline.html
- Download: https://vincentarelbundock.github.io/Rdatasets/csv/fpp2/gasoline.csv
- EIA series packaged in fpp2; values are millions of barrels per day, recorded weekly. It measures product supplied, not price.
- Textbook forecasting example: https://otexts.com/fpp2/weekly.html
- The fractional-year index advances by 7/365.25. Preserve sequence order; do not parse the decimal portion as a calendar month or assume exactly 52 weeks per year.

### ETTh1

- Documentation and recommended paper citation: https://github.com/zhouhaoyi/ETDataset
- Download: https://raw.githubusercontent.com/zhouhaoyi/ETDataset/main/ETT-small/ETTh1.csv
- Authors supply preprocessed CSVs. The downloaded hourly file's exact coverage is given above, rather than the repository's approximate two-year description.
- Use date and OT for a univariate task; six power-load variables are optional historical inputs.

## Verification and limits

Run check_quality.ps1 to reproduce quality_checks.json. It records sizes, row counts, SHA-256 hashes, target ranges and structural checks.

All five files returned zero missing cells, invalid/non-finite numeric measurements, duplicate time values and irregular time steps. Monthly/weekly decimal indexes use a tolerance of 1e-7 years for floating-point rounding. The audit checks the supplied index, not independent original measurement records.

These checks do not prove the absence of measurement error, historical revisions, undocumented upstream imputation or unusual genuine events. No outliers were deleted and no stationarity tests were performed. Seasonal and changing-level behaviour is a modelling property, not automatically a data-quality defect.

## Minimal preparation

- Select the target and preserve chronological order. Drop rownames in the three Rdatasets CSVs; it is a row identifier, not a predictor. Monthly dates can be reconstructed from the documented start and row order.
- Use chronological training/validation/test periods and rolling-origin validation. Fit scaling and any learned transformation on each training fold only.
- Build lagged sequences for the recurrent networks. These are normal model inputs, not data cleaning.
- Assess stationarity using plots and appropriate tests before labelling it in the report. Do not automatically difference every series just because a network is being used.
- All five fit easily in laptop memory. Actual training time depends on model size, sequence length, optimization, number of folds and repetitions; it was not benchmarked here.

References on validation and stationarity:

- https://otexts.com/fpp3/tscv.html
- https://otexts.com/fpp3/stationarity.html
