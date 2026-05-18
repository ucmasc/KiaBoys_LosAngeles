# Master script to reproduce analytics 
# Run from the ijf_code_data/ directory:
#   Rscript run_all.R
#
# Total runtime: approximately 7-15 minutes
#
# Outputs:
#   Fitted model data underlying Figure 4 (D-F): model_sonata_final.csv, model_civic_final.csv, model_camry_final.csv
#   Forecast data underlying Figure 5 (A-C): forecast_final.csv, forecast_west_final.csv, forecast_south_final.csv
#   Table 3 Log-likelihood and AIC values printed to console.
#   Table 4 MASE values printed to console.
#   Fitted model data for Kia Optima (not presented): model_optima_final.csv
#   Forecast data underlying Figure 9: forecast_optima_final.csv
#   Forecast data underlying Figure 10: forecast_recall_2024.csv, forecast_recall_2025.csv, forecast_recall_2026.csv

# Suppress the default Rplots.pdf from interactive plot calls
if (!interactive()) pdf(NULL)

cat("=== Starting full reproduction ===\n\n")

# ---------------------------------------------------------------------------------------
# Step 1: Sonata model (power-law) - Data for Figure 4D, 5A, 10B (part), Table 3, Table 4
# ---------------------------------------------------------------------------------------
cat(">>> Step 1/: Sonata model (power-law) ...\n")
source("sonata.R")
cat("    Done.\n\n")

# ---------------------------------------------------------------------------------------
# Step 2: Civic model (power-law) - Figure 4E, Table 4
# ---------------------------------------------------------------------------------------
cat(">>> Step 2/: Civic model ...\n")
source("civic.R")
cat("    Done.\n\n")

# ---------------------------------------------------------------------------------------
# Step 3: Camry model (power-law) - Figure 4F, Table 4
# ---------------------------------------------------------------------------------------
cat(">>> Step 3/: Camry model ...\n")
source("camry.R")
cat("    Done.\n\n")

# ---------------------------------------------------------------------------------------
# Step 4: Optima model (power-law) - Figure 9, Table 4
# ---------------------------------------------------------------------------------------
cat(">>> Step 4/: Optima model ...\n")
source("optima.R")
cat("    Done.\n\n")

# ---------------------------------------------------------------------------------------
# Step 5: Sonata recall scenarios - Figure 10
#   (depends on forecast.csv from Step 1)
# ---------------------------------------------------------------------------------------
cat(">>> Step 5/: Sonata recall model ...\n")
source("sonata_recall.R")
cat("    Done.\n\n")

# ---------------------------------------------------------------------------------------
# Step 6: Sonata South & West forecast- Figure 5 B,C
#   (depends on forecast_final.csv from Step 1)
# ---------------------------------------------------------------------------------------
cat(">>> Step 6/: Sonata spatial (West/South Bureau) ...\n")
source("sonata_south.R")
cat("    Done.\n\n")

# ---------------------------------------------------------------------------------------
# Step 7: Sonata exponential model - Table 3
# ---------------------------------------------------------------------------------------
cat(">>> Step 7/: Sonata model (exponential) ...\n")
source("sonata_exp.R")
cat("    Done.\n\n")

# ---------------------------------------------------------------------------------------
# Step 8: Sonata constant model - Table 3
# ---------------------------------------------------------------------------------------
cat(">>> Step 8/: Sonata model (constant) ...\n")
source("sonata_constant.R")
cat("    Done.\n\n")

# ---------------------------------------------------------------------------------------
# Step 9: Sonata sales model - Table 3
# ---------------------------------------------------------------------------------------
cat(">>> Step 9/: Sonata model (sales) ...\n")
source("sonata_sales.R")
cat("    Done.\n\n")

# ---------------------------------------------------------------------------------------
# Step 10: Sonata recall model - Table 3
# ---------------------------------------------------------------------------------------
cat(">>> Step 10/: Sonata model (recall) ...\n")
source("sonata_recall.R")
cat("    Done.\n\n")

# ---------------------------------------------------------------------------------------
# Step 11: Sonata logistic model fit- Table 3
# ---------------------------------------------------------------------------------------
cat(">>> Step 11/11: Sonata logistic model fit ...\n")
source("logistic_model.R")
cat("    Done.\n\n")

# Note: To reproduce the "sales" row of Table 3, also run:
#   source("sonata_sales.R")
# This requires sonata_sales.csv and sonata_sales.stan.

cat("=== All scripts completed ===\n")
cat("See CSV files in model_output directory for fitted models and forecasts.\n")
cat("Log-likelihood and AIC values (Table 3) were printed to console above.\n")
cat("MASE values (Table 4) were printed to console above for each vehicle.\n")
