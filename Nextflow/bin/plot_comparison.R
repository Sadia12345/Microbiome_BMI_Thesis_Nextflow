#!/usr/bin/env Rscript
library(ggplot2)
library(readr)
library(dplyr)
library(tidyr)

# Load results
files <- list.files(".", pattern = "_results.csv", full.names = TRUE)

if (length(files) == 0) {
  stop("No results found in current directory!")
}

# Combine
results <- lapply(files, read_csv) %>% bind_rows()

print(results)

# Plot
p <- ggplot(results, aes(x = method, y = Rsquared, fill = method)) +
  geom_col() +
  theme_minimal() +
  labs(title = "Model Comparison: BMI Prediction", y = "R-squared", x = "Algorithm") +
  ylim(0, 1)

ggsave("model_comparison.svg", p, width = 6, height = 4)
print("Saved comparison plot to model_comparison.svg")
