# Hyundai Sonata theft model (power-law specification)
# Fits Bayesian Poisson model via Stan and generates:
#   - model_sonata.csv: fitted values for 2000-2023
#   - forecast.csv: 50-year forecast matrix (2000-2049)
#   - sonata_plot.pdf: observed vs fitted by theft year
#   - sonata_forecast.pdf: forecast heatmap
#   - MASE table (printed to console) for Table 4
#   - Log-likelihood (printed to console) for Table 3

library(tidyverse)
library(rstan)
library(reshape)
library(scales)
library(gridExtra)

thefts <- read.csv("data/sonata_thefts_by_year.csv")
CarMat <- as.matrix(thefts[1:48, 3:26])

# Fit Stan model
model <- suppressMessages(stan_model("sonata.stan"))
fit_cars <- sampling(model,
                     data = list(N = 48, M = 24, thefts = CarMat),
                     iter = 2000, chains = 1, seed = 42)

pars <- c("a", "b", "c", "d", "r0", "x0", "bump", "carseed")
print(fit_cars, pars = pars)

# Extract posterior means
a       <- summary(fit_cars, pars = "a")$summary[1]
b       <- summary(fit_cars, pars = "b")$summary[1]
c       <- summary(fit_cars, pars = "c")$summary[1]
d       <- summary(fit_cars, pars = "d")$summary[1]
r0      <- summary(fit_cars, pars = "r0")$summary[1]
x0      <- summary(fit_cars, pars = "x0")$summary[1]
bump    <- summary(fit_cars, pars = "bump")$summary[1]
carseed <- summary(fit_cars, pars = "carseed")$summary[1]

# Compute expected theft matrix (48 model-years x 50 theft-years)
# i indexes model-year (1=1976, ..., 48=2023)
# j indexes theft-year (1=2000, ..., 50=2049)
# i<36 corresponds to pre-2011 model-years (no vulnerability)
# i>=36 & i<45 corresponds to 2011-2019 model-years (vulnerable)
# j>20 corresponds to post-2019 theft-years (vulnerability discovered)
lam <- matrix(0, 48, 50)
for (i in 1:48) {
  for (j in 1:50) {
    if ((i - j) < 26) {
      scrap <- 1.0 + a * exp(b * ((j - i + 25.0) / 25.0)^c)
      if (i < 36) {
        lam[i, j] <- i^d * carseed / scrap
      } else if (j > 20 && i < 45) {
        lam[i, j] <- i^d * bump * (1 / (1 + exp(-r0 * (j - 20 - x0)))) * carseed / scrap
      } else {
        lam[i, j] <- i^d * carseed / scrap
      }
    }
  }
}

# Fitted values for observation period (2000-2023)
lam2 <- lam[, 1:24]
colnames(lam2) <- seq(2000, 2023)
rownames(lam2) <- thefts[1:48, 2]
df <- melt(lam2)
colnames(df) <- c("y", "x", "thefts")
write.csv(lam2, "model_output/model_sonata_final.csv")

# Log-likelihood for Table 3
ll <- summary(fit_cars, pars = "loglike")$summary[1]
cat("***Sonata model (power-law)***\n")
cat("Log-likelihood:", ll, "\n")
cat("AIC:", -2 * ll + 2 * length(pars), "\n")

# MASE for Table 4
mase <- function(thefts, df, t_lag) {
  thft <- thefts
  thft$theft <- NULL
  df2 <- melt(thft, id = "myear")
  names(df2) <- names(df)
  df2$x <- df$x[1:nrow(df2)]
  unique_thft_years <- unique(df2$x)[(t_lag + 1):length(unique(df2$x))]
  unique_mdl_years <- unique(df$y)
  model_error <- 0
  naive_error <- 0
  for (yr in unique_thft_years) {
    for (myr in unique_mdl_years) {
      model_error <- model_error + abs(df$thefts[df$x == yr & df$y == myr] -
                                         df2$thefts[df$x == yr & df$y == myr])
      naive_error <- naive_error + abs(df2$thefts[df$x == (yr - t_lag) & df$y == myr] -
                                         df2$thefts[df$x == yr & df$y == myr])
    }
  }
  return(model_error / naive_error)
}

mase_table <- data.frame(lag = 1:10,
                          mase = sapply(1:10, function(k) mase(thefts, df, k)))

cat("***Sonata model (power-law)***\n")
print(mase_table)

# Panel plots: observed (red) vs fitted (blue) for each theft year
myplot <- function(j) {
  ggplot() +
    geom_line(aes(x = thefts[, 2], y = thefts[, j + 2]), color = "red") +
    geom_line(aes(x = thefts[, 2], y = lam[, j]), color = "blue") +
    xlab("Make Year") + ylab("Thefts") +
    ggtitle(paste0("Sonata Theft Year: ", j + 1999)) + theme_bw()
}
plist <- lapply(1:24, myplot)
p <- grid.arrange(grobs = plist, ncol = 5)
#ggsave("model_output/sonata_plot.pdf", p, width = 15, height = 10)

# Forecast heatmap (Figure 5A / Figure 4D)
colnames(lam) <- seq(2000, 2049)
rownames(lam) <- thefts[, 2]
df_forecast <- melt(lam)
colnames(df_forecast) <- c("y", "x", "thefts")
p2 <- ggplot(df_forecast, aes(x = x, y = y, fill = thefts)) +
  geom_tile() +
  scale_fill_gradient2(low = "blue", high = "red") +
  scale_y_continuous(breaks = c(2010, 2015, 2020), limits = c(2010, 2020)) +
  theme_minimal() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) +
  xlab("theft year") + ylab("model year")
#ggsave("model_output/sonata_forecast.pdf", p2, width = 8, height = 5)

write.csv(lam, "model_output/forecast_final.csv")

