#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(mikropml))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(ggplot2))

# Arguments
args <- commandArgs(trailingOnly = TRUE)
model_path <- args[1] # e.g., "results/rf_model.rds"
data_path <- args[2]  # e.g., "results/preprocessed.rds"
output_csv <- args[3] # e.g., "results/feature_importance.csv"
output_plot <- args[4] # e.g., "results/feature_importance.png"

if (is.na(model_path) || is.na(data_path)) {
  stop("Missing arguments. Usage: script.R model.rds data.rds out.csv out.png")
}

message("Loading model from: ", model_path)
model <- readRDS(model_path)

message("Loading data from: ", data_path)
data_obj <- readRDS(data_path)
# mikropml expects 'dat' for permutation importance
# preprocessed.rds from mikropml::preprocess_data is usually a list with $dat and $outcome
# We need to pass the dataframe.
test_dat <- data_obj$dat

message("Extracting feature importance...")
feat_imp <- mikropml::get_feature_importance(model, test_data = test_dat, outcome_colname = "bmi")

# Save full importance data
message("Saving importance to: ", output_csv)
write_csv(feat_imp, output_csv)

# Plot Top 20
message("Generating plot...")
top_20 <- feat_imp %>%
  head(20)

p <- ggplot(top_20, aes(x = reorder(feat, perf_metric_diff), y = perf_metric_diff)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +
  labs(
    title = "Top 20 Predictive Microbial Features (Random Forest)",
    x = "Microbial Species",
    y = "Importance (Permutation)"
  ) +
  theme_bw()

ggsave(output_plot, plot = p, width = 10, height = 8)
message("Plot saved to: ", output_plot)
