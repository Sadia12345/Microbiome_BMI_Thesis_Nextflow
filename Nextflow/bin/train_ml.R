#!/usr/bin/env Rscript

library(optparse)
library(mikropml)
library(readr)
library(dplyr)

# Increase future globals limit to 20GB to handle large Metalog dataset
options(future.globals.maxSize = 20000 * 1024^2)


option_list <- list(
  make_option(c("-i", "--input"), type = "character", help = "Input preprocessed RDS"),
  make_option(c("-o", "--output"), type = "character", help = "Output results CSV"),
  make_option(c("-O", "--model_output"), type = "character", help = "Output model RDS"),
  make_option(c("-c", "--outcome"), type = "character", help = "Outcome column name"),
  make_option(c("-m", "--method"), type = "character", default = "glmnet", help = "ML method (glmnet, rf, xgbTree)")
)

opt <- parse_args(OptionParser(option_list = option_list))

# Load data
preproc <- readRDS(opt$input)

# Run ML
results <- run_ml(
  dataset = preproc$dat_transformed,
  method = opt$method,
  outcome_colname = opt$outcome,
  kfold = 2,
  seed = 100
)

# Save performance
write_csv(results$performance, opt$output)

# Save model object
if (!is.null(opt$model_output)) {
  saveRDS(results, opt$model_output)
}
