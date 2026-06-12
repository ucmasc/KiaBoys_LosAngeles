# Replication Code for "Forecasting the impact of the viral 'Kia Boys' social media trend on car thefts to 2050"

Brantingham, P.J., Uchida, C.D., Morstatter, F., and Mohler, G. (2026).

May 18, 2026

## Overview

This repository contains data and code to reproduce the analyses in the paper. The study examines the surge in Hyundai Sonata thefts in Los Angeles in relation to the 'Kia Boys' social media trend and uses mechanistic models to forecast theft patterns through 2050.

All data to reproduce the analyses are contained in the \data folder. Output files from analyses are saved in the \model_output folder. Reproducing the analyses requires R (model fitting, forecasts), Stata (VAR Analysis). Reproducing the figures requires Mathematica.

Note that R model estimates are posterior summaries produced by Hamiltonian Monte Carlo sampling (Stan, via rstan), not closed-form quantities. Stan does not guarantee bit-for-bit identical results across different operating systems, compilers, or hardware, even with a fixed random seed. As the Stan Reference Manual states, “Floating point operations on modern computers are notoriously difficult to replicate.” Exact reproducibility holds only when the “Stan version … operating system version … computer hardware … [and] C++ compiler, including version, compiler flags, and linked libraries” are all identical. That is, replicates on the same machine will be identical, whereas replicates on different machines will produce slightly different results. The between-machines differences in estimates are of similar magnitude to the differnces seen when changing random seeds within-machines. The differences across replicates do not change the interpretation of results.

See: https://mc-stan.org/docs/reference-manual/reproducibility.html for more information on reproducibiity with STAN.

## Requirements

### R Environment
- **R** (version 4.0+; tested with R 4.5.0)
- **R packages**:
  - `tidyverse` (data manipulation and visualization)
  - `rstan` (Bayesian inference via Stan)
  - `reshape` (data reshaping)
  - `scales` (plot scaling)
  - `gridExtra` (multi-panel plots)

Install packages in R:
```r
install.packages(c("tidyverse", "rstan", "reshape", "scales", "gridExtra"))
```

### Stata (for VAR analysis only)
- **Stata** (version 15+; tested with Stata 19 BE)
- Required for reproducing the Vector Autoregressive (VAR) analysis in Section 4.1

### Mathematica (for figures)
- **Mathematica** (version 14+; tested with Mathematica 14.2)
- Required for producing all figure elements. Excludes maps in Fig. 3B and 6A.

### System Requirements
- Estimated runtime: 7-15 minutes for full R reproduction
- RAM: 4GB minimum recommended

## Directory Structure

```
├── README.md                    # This file
├── run_all.R                    # Master script to reproduce all R analyses
├── data/                        # Input data files
│   ├── sonata_thefts_by_year.csv
│   ├── civic_thefts_by_year.csv
│   ├── camry_thefts_by_year.csv
│   ├── optima_thefts_by_year.csv
│   ├── civic_west_south_compare.csv
│   ├── weekly_sonata_logistic-10-4-24.csv
│   ├── sonata_sales.csv
│   └── ...
├── model_output/                # Generated output files
├── *.R                          # R analysis scripts
├── *.stan                       # Stan model specifications
└── VAR-Sonata-Kiaboys-8-2-25.do # Stata VAR analysis script
```

## Data Files

### Theft Data (by model-year and theft-year)
| File | Description | Rows | Columns |
|------|-------------|------|---------|
| `sonata_thefts_by_year.csv` | Hyundai Sonata thefts (LAPD 2000-2023) | 48 (model-years 1976-2023) | 24 (theft-years 2000-2023) |
| `civic_thefts_by_year.csv` | Honda Civic thefts | 48 | 24 |
| `camry_thefts_by_year.csv` | Toyota Camry thefts | 48 | 24 |
| `optima_thefts_by_year.csv` | Kia Optima thefts | 48 | 24 |

### Spatial and Time-Series Data
| File | Description |
|------|-------------|
| `civic_west_south_compare.csv` | Honda Civic thefts by LAPD bureau (citywide, West, South) |
| `weekly_sonata_logistic-10-4-24.csv` | Weekly Sonata thefts with Google Trends data (for VAR analysis) |
| `sonata_sales.csv` | National Hyundai Sonata sales by year |

## Stan Model Files

| File | Description | Parameters |
|------|-------------|------------|
| `sonata.stan` | Sonata model with power-law market growth and Kia Boys vulnerability window | a, b, c, d, r0, x0, bump, carseed |
| `sonata_exp.stan` | Sonata model with exponential market growth | a, b, c, d, r0, x0, bump, carseed |
| `sonata_constant.stan` | Sonata model with constant market (no d parameter) | a, b, c, r0, x0, bump, carseed |
| `sonata_sales.stan` | Sonata model using empirical sales data for h_m | a, b, c, r0, x0, bump, carseed |
| `fit_sales.stan` | Gaussian fit to national sales data | mu, sig, c |
| `civic.stan` | Honda Civic model (immobilizer threshold at 2001) | a, b, c, d, bump, carseed |
| `camry.stan` | Toyota Camry model (immobilizer threshold at 1992) | a, b, c, d, bump, carseed |
| `optima.stan` | Kia Optima model (vulnerability window 2011-2020) | a, b, c, d, r0, x0, bump, carseed |

## Reproducing Results

### Quick Start: Reproduce All R Analyses

From the repository directory:
```bash
Rscript run_all.R
```

This executes all 11 analysis steps in sequence (~7-15 minutes total):

| Step | Script | Output | Paper Reference |
|------|--------|--------|-----------------|
| 1 | `sonata.R` | `model_sonata_final.csv`, `forecast_final.csv` | Figure 4D, 5A, Table 3-4 |
| 2 | `civic.R` | `model_civic_final.csv` | Figure 4E, Table 4 |
| 3 | `camry.R` | `model_camry_final.csv` | Figure 4F, Table 4 |
| 4 | `optima.R` | `model_optima_final.csv`, `optima_forecast_final.csv` | Figure 9, Table 4 (Appendix D) |
| 5 | `sonata_recall.R` | `forecast_recall_2024/2025/2026.csv` | Figure 10 (Appendix F) |
| 6 | `sonata_south.R` | `forecast_south_final.csv`, `forecast_west_final.csv` | Figure 5B-C |
| 7 | `sonata_exp.R` | (console output) | Table 3 |
| 8 | `sonata_constant.R` | (console output) | Table 3 |
| 9 | `sonata_sales.R` | (console output) | Table 3 |
| 10 | `sonata_recall.R` | (same as step 5) | Table 3 |
| 11 | `logistic_model.R` | (console output) | Section 4.1 (logistic parameters) |

### Reproduce Individual Results

#### Figure 4: Empirical and Model-Based Matrix-Frequency Plots
```bash
Rscript sonata.R    # Panel D: Hyundai Sonata
Rscript civic.R     # Panel E: Honda Civic
Rscript camry.R     # Panel F: Toyota Camry
```

#### Figure 5: Projected Hyundai Sonata Thefts
```bash
Rscript sonata.R        # Panel A: Citywide forecast
Rscript sonata_south.R  # Panels B-C: West/South Bureau forecasts
```
*Note: `sonata_south.R` requires `forecast_final.csv` from `sonata.R`*

#### Table 3: Model Comparison (Log-Likelihood and AIC)
Run each model specification and note the values printed to console:
```bash
Rscript sonata.R          # power model (8 parameters)
Rscript sonata_exp.R      # exponential model (8 parameters)
Rscript sonata_constant.R # constant model (7 parameters)
Rscript sonata_sales.R    # sales-data model (9 parameters)
```

Expected output (approximate given floating point variation):
| Model | Log-Likelihood | AIC |
|-------|----------------|-----|
| power | 22076.74 | -44137.48 |
| exp | 22030.40 | -44044.80 |
| constant | 21954.69 | -43895.38 |
| sales | 22215.63 | -44413.25 |

#### Table 4: MASE Values
MASE tables are printed to console when running each vehicle script:
```bash
Rscript sonata.R   # Sonata MASE
Rscript civic.R    # Civic MASE
Rscript camry.R    # Camry MASE
Rscript optima.R   # Optima MASE
```
Expected output (approximate given floating point variation):
| lag k | Sonata | Civic | Camry | Optima |
|-------|--------|-------|-------|--------|
| 1 | 1.03 | 2.22 | 1.97 | 1.67 |
| 2 | 0.64 | 1.59 | 1.18 | 1.21 |
| 3 | 0.51 | 1.26 | 0.83 | 0.96 |
| 4 | 0.48 | 1.09 | 0.63 | 0.93 |
| 5 | 0.47 | 0.94 | 0.49 | 0.91 |
| 6 | 0.46 | 0.84 | 0.39 | 0.89 |
| 7 | 0.45 | 0.79 | 0.32 | 0.86 |
| 8 | 0.44 | 0.73 | 0.27 | 0.84 |
| 9 | 0.43 | 0.72 | 0.24 | 0.83 |
| 10 | 0.42 | 0.67 | 0.21 | 0.82 |

#### Appendix D: Kia Optima Forecast (Figure 9)
```bash
Rscript optima.R   # generates optima_forecast_final.csv
```

#### Appendix F: Recall Impact Scenarios (Figure 10)
```bash
Rscript sonata.R        # must run first
Rscript sonata_recall.R # generates recall scenario forecasts
```

### VAR Analysis (Section 4.1) - Stata Required

The Vector Autoregressive (VAR) analysis requires Stata:

1. Open Stata
2. Set working directory to this repository
3. Run the do-file:
```stata
cd "path/to/this/repository"
do VAR-Sonata-Kiaboys-8-2-25.do
```
**Note:** Edit line 5 of the do-file to set your working directory path.

The script performs:
- Unit root tests (Dickey-Fuller, Phillips-Perron)
- VAR model estimation with 3 lags
- Lag-order selection (varsoc)
- Stability condition check (varstable)
- Autocorrelation tests (varlmar)
- Granger causality tests (vargranger)

Expected key results:
- Sonata thefts Granger-cause US 'Kia Boys' searches (χ² = 10.748, p = 0.013)
- US 'Kia Boys' searches do NOT Granger-cause Sonata thefts (χ² = 2.747, p = 0.432)

## Figure Rendering - Mathematica 14+ Required

A Mathematica 14.2 notebook file is provided to reproduce the figure elements in the paper using the data contained in the \data folder. Printed versions of Figures 3A and 8A were produced in MS Excel, which provides greater flexibility over multi-axis presentations. The figure elements generated by Mathematica are numerically identical. Figure layout and labeling of some features was done in MS PowerPoint. Maps in Figures 3B and 8A were made in QGIS and are not reproduced here.  


## Output Files

| File | Description |
|------|-------------|
| `model_sonata_final.csv` | Fitted Sonata theft matrix (2000-2023) |
| `model_civic_final.csv` | Fitted Civic theft matrix (2000-2023) |
| `model_camry_final.csv` | Fitted Camry theft matrix (2000-2023) |
| `model_optima_final.csv` | Fitted Optima theft matrix (2000-2023) |
| `forecast_final.csv` | 50-year Sonata forecast matrix (2000-2049) |
| `forecast_west_final.csv` | West Bureau Sonata forecast |
| `forecast_south_final.csv` | South Bureau Sonata forecast |
| `optima_forecast_final.csv` | 50-year Optima forecast matrix |
| `forecast_recall_2024.csv` | Sonata forecast with 2024 recall |
| `forecast_recall_2025.csv` | Sonata forecast with 2025 recall |
| `forecast_recall_2026.csv` | Sonata forecast with 2026 recall |

## Notes on Reproducibility

### Package Versions
The code was tested with:
- R 4.5.0
- rstan 2.32.7 (Stan 2.32.2)
- tidyverse 2.0.0
- Stata 19 BE
- Mathematica 14.2

## Citation

```bibtex
@article{brantingham2026forecasting,
  title={Forecasting the impact of the viral '{K}ia {B}oys' social media trend on car thefts to 2050},
  author={Brantingham, P. Jeffrey and Uchida, Craig D. and Morstatter, Fred and Mohler, George},
  journal={TBA},
  year={2026}
}
```

## Contact

P. Jeffrey Brantingham
Department of Anthropology
University of California, Los Angeles
branting@ucla.edu
