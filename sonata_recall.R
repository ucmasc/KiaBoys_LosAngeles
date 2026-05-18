# Hyundai Sonata recall impact model (Appendix F)
# Must be run AFTER sonata.R (requires forecast.csv)
# Generates:
#   - completion_rate.pdf: recall completion curve (Figure 10A)
#   - forecasted_sonata_recall.pdf: recall scenario comparison (Figure 10B)
#   - forecast_recall_2024/2025/2026.csv: forecast matrices for each scenario

library(tidyverse)
library(rstan)
library(reshape)
library(scales)
library(ggplot2)

thefts <- read.csv("data/sonata_thefts_by_year.csv")
CarMat <- as.matrix(thefts[1:48, 3:26])

# Fit Stan model (same as sonata.R)
model <- suppressMessages(stan_model("sonata.stan"))
fit_cars <- sampling(model,
                     data = list(N = 48, M = 24, thefts = CarMat),
                     iter = 2000, chains = 1, seed = 42)

a       <- summary(fit_cars, pars = "a")$summary[1]
b       <- summary(fit_cars, pars = "b")$summary[1]
c       <- summary(fit_cars, pars = "c")$summary[1]
d       <- summary(fit_cars, pars = "d")$summary[1]
r0      <- summary(fit_cars, pars = "r0")$summary[1]
x0      <- summary(fit_cars, pars = "x0")$summary[1]
bump    <- summary(fit_cars, pars = "bump")$summary[1]
carseed <- summary(fit_cars, pars = "carseed")$summary[1]

# NHTSA recall completion rate model (Eq. 8 in paper)
# Parameters from NHTSA 2021 report, Fig. 10, for Hyundai
L1  <- 100.51111786
k1  <- -0.22285628
x01 <- 7.9678379
C1  <- -0.26576496
logistic_function <- function(x, L1, k1, x01, C1) {
  C1 + (L1 - C1) / (1 + exp(-k1 * (x - x01)))
}

# Plot completion rate (Figure 10A)
df_comp <- data.frame(x = seq(0, 20, length.out = 400))
df_comp$y <- logistic_function(df_comp$x, L1, k1, x01, C1)
p <- ggplot(df_comp, aes(x = x, y = y)) +
  geom_line(color = "black", linewidth = 1.2) +
  scale_x_continuous(limits = c(0, 20)) +
  scale_y_continuous(limits = c(0, 100)) +
  labs(x = "Age of vehicle", y = "Predicted completion rate") +
  theme_minimal(base_size = 14)
#ggsave("model_output/completion_rate.pdf", p, width = 5, height = 5)

# Recall scenarios: 2024 (mr=25), 2025 (mr=26), 2026 (mr=27)
lam_list <- list()
mr <- c(25, 26, 27)

for (ll in 1:3) {
  lam_list[[ll]] <- matrix(0, 48, 50)
  for (i in 1:48) {
    for (j in 1:50) {
      if ((i - j) < 26) {
        scrap <- 1.0 + a * exp(b * ((j - i + 25.0) / 25.0)^c)
        if (i < 36) {
          lam_list[[ll]][i, j] <- i^d * carseed / scrap
        } else if (j > 20 && i < 45) {
          lam_list[[ll]][i, j] <- i^d * bump * (1 / (1 + exp(-r0 * (j - 20 - x0)))) * carseed / scrap
          if (j >= mr[ll]) {
            bsr <- i^d * carseed / scrap
            bdiff <- lam_list[[ll]][i, j] - bsr
            lam_list[[ll]][i, j] <- bsr + bdiff * (1 - logistic_function(mr[ll] - i + 25, L1, k1, x01, C1) / 100)
          }
        } else {
          lam_list[[ll]][i, j] <- i^d * carseed / scrap
        }
      }
    }
  }
}

# Plot recall scenarios (Figure 10B)
lam_no_recall <- read.csv("data/forecast_final.csv", header = TRUE, row.names = 1)
lam1 <- colSums(lam_no_recall)
lam2 <- colSums(lam_list[[1]])
lam3 <- colSums(lam_list[[2]])
lam4 <- colSums(lam_list[[3]])
x <- seq(2000, 2049)

p3 <- ggplot() +
  geom_line(aes(x = x, y = lam1, color = "line1"), linewidth = 1.2) +
  geom_line(aes(x = x, y = lam2, color = "line2"), linewidth = 1.2) +
  geom_line(aes(x = x, y = lam3, color = "line3"), linewidth = 1.2) +
  geom_line(aes(x = x, y = lam4, color = "line4"), linewidth = 1.2) +
  xlim(2026, 2045) +
  xlab("Theft year") + ylab("Forecasted Sonata thefts") +
  scale_color_manual(
    name = "",
    values = c("line1" = "blue", "line2" = "red", "line3" = "green4", "line4" = "orange"),
    labels = c("No Recall", "2024 Recall", "2025 Recall", "2026 Recall")
  ) +
  theme_minimal(base_size = 14) +
  theme(legend.position = c(1, 1), legend.justification = c(1, 1))
#ggsave("model_output/forecasted_sonata_recall.pdf", p3, width = 5, height = 5)

# Save forecast matrices
x_row <- thefts[, 2]
y_col <- seq(2000, 2049)
for (ll in 1:3) {
  colnames(lam_list[[ll]]) <- y_col
  rownames(lam_list[[ll]]) <- x_row
}
write.csv(lam_list[[1]], "model_output/forecast_recall_2024.csv")
write.csv(lam_list[[2]], "model_output/forecast_recall_2025.csv")
write.csv(lam_list[[3]], "model_output/forecast_recall_2026.csv")
