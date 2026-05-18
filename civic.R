# Honda Civic theft model
# Fits Bayesian Poisson model via Stan and generates:
#   - model_civic.csv: fitted values for 2000-2023
#   - civic_plot.pdf: observed vs fitted by theft year
#   - MASE table (printed to console) for Table 4

library(tidyverse)
library(rstan)
library(reshape)
library(gridExtra)

thefts <- read.csv("data/civic_thefts_by_year.csv")
CarMat <- as.matrix(thefts[1:48, 3:26])

# Fit Stan model (civic.stan)
model <- suppressMessages(stan_model("civic.stan"))
fit_cars <- sampling(model,
                     data = list(N = 48, M = 24, thefts = CarMat),
                     iter = 2000, chains = 1, seed = 42)

pars <- c("a", "b", "c", "d", "bump", "carseed")

#print(fit_cars, pars = pars)

# Extract posterior means
a       <- summary(fit_cars, pars = "a")$summary[1]
b       <- summary(fit_cars, pars = "b")$summary[1]
c       <- summary(fit_cars, pars = "c")$summary[1]
d       <- summary(fit_cars, pars = "d")$summary[1]
bump    <- summary(fit_cars, pars = "bump")$summary[1]
carseed <- summary(fit_cars, pars = "carseed")$summary[1]

# Compute expected theft matrix
# i<25 corresponds to pre-2001 model-years (no immobilizer)
# i>=25 corresponds to 2001+ model-years (with immobilizer)
lam <- matrix(0, 48, 24)
for (i in 1:48) {
  for (j in 1:24) {
    if ((i - j) < 26) {
      scrap <- 1.0 + a * exp(b * ((j - i + 25.0) / 25.0)^c)
      if (i < 25) {
        lam[i, j] <- i^d * carseed / scrap
      } else {
        lam[i, j] <- i^d * bump * carseed / scrap
      }
    }
  }
}

# Fitted values
lam2 <- lam[, 1:24]
colnames(lam2) <- seq(2000, 2023)
rownames(lam2) <- thefts[1:48, 2]
df <- melt(lam2)
colnames(df) <- c("y", "x", "thefts")
write.csv(lam2, "model_output/model_civic_final.csv")

# MASE for Table 4
cat("***Civic model (power-law)***\n")
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
print(mase_table)

# Panel plots: observed (red) vs fitted (blue)
myplot <- function(j) {
  ggplot() +
    geom_line(aes(x = thefts[, 2], y = thefts[, j + 2]), color = "red") +
    geom_line(aes(x = thefts[, 2], y = lam[, j]), color = "blue") +
    xlab("Make Year") + ylab("Thefts") +
    ggtitle(paste0("Civic Theft Year: ", j + 1999)) + theme_bw()
}
plist <- lapply(1:24, myplot)
p <- grid.arrange(grobs = plist, ncol = 5)
#ggsave("model_output/civic_plot.pdf", p, width = 15, height = 10)
