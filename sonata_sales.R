# Hyundai Sonata theft model (sales-data specification)
# Alternative to sonata.R for Table 3 model comparison.
# Uses Gaussian fit to empirical sales data for h_m.
# Requires: sonata_sales.csv, fit_sales.stan, sonata_sales.stan

library(tidyverse)
library(rstan)
library(reshape)
library(scales)
library(gridExtra)

thefts <- read.csv("data/sonata_thefts_by_year.csv")
sales  <- read.csv("data/sonata_sales.csv")
CarMat <- as.matrix(thefts[1:48, 3:26])

# Step 1: Fit Gaussian to sales data
model0 <- suppressMessages(stan_model("fit_sales.stan"))
fit_sales <- sampling(model0,
                      data = list(N = 35, sales = sales$N),
                      iter = 2000, chains = 1, seed = 42)

mu  <- summary(fit_sales, pars = "mu")$summary[1]
sig <- summary(fit_sales, pars = "sig")$summary[1]
c0  <- summary(fit_sales, pars = "c")$summary[1]
sales$fit <- c0 * exp(-(seq_len(35) - mu)^2 / (2 * sig^2))

p0 <- ggplot() +
  geom_point(aes(x = sales$year, y = sales$N), color = "red") +
  geom_line(aes(x = sales$year, y = sales$fit), color = "blue") +
  xlab("Make Year") + ylab("Sales") + theme_bw()
#ggsave("model_output/sales_fit.pdf", p0, width = 8, height = 5)

# Shift mu to 1976 baseline for theft model indexing
mu <- mu + 1990 - 1976

# Step 2: Fit theft model with sales-based h_m
model <- suppressMessages(stan_model("sonata_sales.stan"))
fit_cars <- sampling(model,
                     data = list(N = 48, M = 24, thefts = CarMat, mu = mu, sig = sig),
                     iter = 2000, chains = 1, seed = 42)

pars <- c("a", "b", "c", "r0", "x0", "bump", "carseed")
print(fit_cars, pars = pars)

a       <- summary(fit_cars, pars = "a")$summary[1]
b       <- summary(fit_cars, pars = "b")$summary[1]
c       <- summary(fit_cars, pars = "c")$summary[1]
r0      <- summary(fit_cars, pars = "r0")$summary[1]
x0      <- summary(fit_cars, pars = "x0")$summary[1]
bump    <- summary(fit_cars, pars = "bump")$summary[1]
carseed <- summary(fit_cars, pars = "carseed")$summary[1]

lam <- matrix(0, 48, 50)
for (i in 1:48) {
  for (j in 1:50) {
    if ((i - j) < 26) {
      sales_wt <- exp(-(i - mu)^2 / (2.0 * sig^2))
      scrap <- 1.0 + a * exp(b * ((j - i + 25.0) / 25.0)^c)
      if (i < 36) {
        lam[i, j] <- sales_wt * carseed / scrap
      } else if (j > 20 && i < 45) {
        lam[i, j] <- sales_wt * bump * (1 / (1 + exp(-r0 * (j - 20 - x0)))) * carseed / scrap
      } else {
        lam[i, j] <- sales_wt * carseed / scrap
      }
    }
  }
}

# Log-likelihood for Table 3 (9 params: 7 theft model + mu + sig)
cat("***Sonata model (sales)***\n")
ll <- summary(fit_cars, pars = "loglike")$summary[1]
cat("Log-likelihood:", ll, "\n")
cat("AIC:", -2 * ll + 2 * 9, "\n")

# Panel plots
myplot <- function(j) {
  ggplot() +
    geom_line(aes(x = thefts[, 2], y = thefts[, j + 2]), color = "red") +
    geom_line(aes(x = thefts[, 2], y = lam[, j]), color = "blue") +
    xlab("Make Year") + ylab("Thefts") +
    ggtitle(paste0("Sonata (sales) Year: ", j + 1999)) + theme_bw()
}
plist <- lapply(1:24, myplot)
p <- grid.arrange(grobs = plist, ncol = 5)
#ggsave("model_output/sonata_sales_plot.pdf", p, width = 15, height = 10)
