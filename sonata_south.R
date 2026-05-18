# Sonata spatial forecast: West vs South Bureau (Figure 5B,C)
# Must be run AFTER sonata.R (requires forecast.csv) and civic.R
# Requires: civic_west_south_compare_w_2023_7-29-24.csv
# Generates:
#   - west2south.pdf: regional theft fraction by car age
#   - multiplier.csv: LOESS-fitted regional multipliers
#   - forecast_south.csv, forecast_west.csv: regional forecasts

library(tidyverse)
library(reshape)
library(scales)

thefts <- read.csv("data/civic_west_south_compare.csv")

# Parse three regions from stacked data: all (rows 1-48), west (49-96), south (97-144)
parse_region <- function(rows) {
  lam2 <- as.matrix(thefts[rows, 3:26])
  colnames(lam2) <- seq(2000, 2023)
  rownames(lam2) <- thefts[rows, 2]
  df <- melt(lam2)
  colnames(df) <- c("y", "x", "thefts")
  return(df)
}

df  <- parse_region(1:48)
df2 <- parse_region(49:96)
df3 <- parse_region(97:144)

# Compute theft fractions by car age
df$time  <- df$x - df$y;  df$type  <- "all"
df2$time <- df2$x - df2$y; df2$type <- "west"
df3$time <- df3$x - df3$y; df3$type <- "south"

dfc  <- df  %>% filter(time >= 0) %>% group_by(time) %>% summarize(thefts = mean(thefts))
dfc2 <- df2 %>% filter(time >= 0) %>% group_by(time) %>% summarize(thefts = mean(thefts))
dfc3 <- df3 %>% filter(time >= 0) %>% group_by(time) %>% summarize(thefts = mean(thefts))

dfc2$p <- dfc2$thefts / (dfc$thefts + .001)
dfc3$p <- dfc3$thefts / (dfc$thefts + .001)
dfc2$type <- "west"
dfc2$time <- dfc2$time + 15  # time offset for West Bureau
dfc3$type <- "south"
dfcombine <- rbind(dfc2, dfc3)
dfcombine <- dfcombine %>% filter(time < 40)

# LOESS regression for regional multiplier
model <- loess(p ~ time, data = dfcombine, span = .65)
dfcombine$predict <- predict(model, dfcombine)

names(dfcombine)[4] <- "bureau"
dfcombine$time[dfcombine$bureau == "west"] <- dfcombine$time[dfcombine$bureau == "west"] - 15
dfcombine <- dfcombine[order(dfcombine$time), ]

p <- dfcombine %>% ggplot() +
  geom_point(aes(x = time, y = p, color = bureau, group = bureau)) +
  geom_line(aes(x = time, y = predict, group = bureau), color = "black") +
  theme_minimal() + xlab("age of car")
#ggsave("model_output/west2south.pdf", p, width = 7, height = 4)
#write.csv(dfcombine[, c("time", "predict", "bureau")], "model_output/multiplier.csv", row.names = FALSE)

# Apply multipliers to baseline forecast
forecast <- read.csv("data/forecast_final.csv")
rownames_fc <- forecast$X
forecast$X <- NULL
nr <- nrow(forecast)
nc <- ncol(forecast)
forecast_south <- forecast
forecast_west  <- forecast

for (i in 1:nr) {
  for (j in 1:nc) {
    ts <- (j - i + 24)
    if (ts >= 0 & ts < 40) {
      forecast_south[i, j] <- predict(model, ts) * forecast[i, j]
    }
    if (ts >= 40) {
      forecast_south[i, j] <- max(.0584 - (ts - 39) * .016, 0) * forecast[i, j]
    }
    ts <- (j - i + 24 + 15)
    if (ts >= 0 & ts < 40) {
      forecast_west[i, j] <- predict(model, ts) * forecast[i, j]
    }
    if (ts >= 40) {
      forecast_west[i, j] <- max(.0584 - (ts - 39) * .016, 0) * forecast[i, j]
    }
  }
}

row.names(forecast_south) <- rownames_fc
row.names(forecast_west)  <- rownames_fc
write.csv(forecast_south, "model_output/forecast_south_final.csv")
write.csv(forecast_west, "model_output/forecast_west_final.csv")
