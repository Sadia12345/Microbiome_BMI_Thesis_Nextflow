#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(mikropml))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(ggplot2))

# Arguments
args <- commandArgs(trailingOnly = TRUE)
model_path <- args[1] # e.g., "results/rf_model.rds"
# output_csv is now arg 2 since we removed data_path
output_csv <- args[2] 
output_plot <- args[3]

if (is.na(model_path)) {
  stop("Missing arguments. Usage: script.R model.rds out.csv out.png")
}

message("Loading model from: ", model_path)
model_list <- readRDS(model_path)
# run_ml outputs a list with 'trained_model' and 'test_data'
model <- model_list$trained_model
test_dat <- model_list$test_data

if (is.null(test_dat)) {
    stop("test_data not found in model object. Cannot calculate importance.")
}
message("Loaded test data from model object. Rows: ", nrow(test_dat))

message("Extracting feature importance (Direct Method)...")

# Direct extraction from the underlying caret -> randomForest object
# model is a caret 'train' object. model$finalModel is the randomForest object.
if (is.null(model$finalModel)) {
    stop("Result IS NOT a caret model with a finalModel component.")
}

# The importance matrix
imp_mat <- model$finalModel$importance
# Convert to dataframe
feat_imp <- as.data.frame(imp_mat)
feat_imp$feat <- rownames(feat_imp)
# Rename the importance metric column (usually IncNodePurity or %IncMSE)
# We will just take the first column and call it 'perf_metric_diff' to match structure
colnames(feat_imp)[1] <- "perf_metric_diff"

message("Extraction successful. Rows: ", nrow(feat_imp))

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
