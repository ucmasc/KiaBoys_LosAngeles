# Hyundai Sonata theft model (constant specification)
# Alternative to sonata.R for Table 3 model comparison.
# Removes market growth parameter d (h_m = 1).

library(tidyverse)
library(rstan)
library(reshape)
library(scales)
library(gridExtra)

thefts <- read.csv("data/sonata_thefts_by_year.csv")
CarMat <- as.matrix(thefts[1:48, 3:26])

model <- suppressMessages(stan_model("sonata_constant.stan"))
fit_cars <- sampling(model,
                     data = list(N = 48, M = 24, thefts = CarMat),
                     iter = 2000, chains = 1, seed = 42)

pars <- c("a", "b", "c", "r0", "x0", "bump", "carseed")
#print(fit_cars, pars = pars)

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
      scrap <- 1.0 + a * exp(b * ((j - i + 25.0) / 25.0)^c)
      if (i < 36) {
        lam[i, j] <- carseed / scrap
      } else if (j > 20 && i < 45) {
        lam[i, j] <- bump * (1 / (1 + exp(-r0 * (j - 20 - x0)))) * carseed / scrap
      } else {
        lam[i, j] <- carseed / scrap
      }
    }
  }
}

# Log-likelihood for Table 3
cat("***Sonata model (constant)***\n")
ll <- summary(fit_cars, pars = "loglike")$summary[1]
cat("Log-likelihood:", ll, "\n")
cat("AIC:", -2 * ll + 2 * length(pars), "\n")

# Panel plots
myplot <- function(j) {
  ggplot() +
    geom_line(aes(x = thefts[, 2], y = thefts[, j + 2]), color = "red") +
    geom_line(aes(x = thefts[, 2], y = lam[, j]), color = "blue") +
    xlab("Make Year") + ylab("Thefts") +
    ggtitle(paste0("Sonata (const) Year: ", j + 1999)) + theme_bw()
}
plist <- lapply(1:24, myplot)
p <- grid.arrange(grobs = plist, ncol = 5)
#ggsave("model_output/sonata_constant_plot.pdf", p, width = 15, height = 10)
