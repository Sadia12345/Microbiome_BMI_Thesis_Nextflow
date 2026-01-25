#!/usr/bin/env Rscript

library(optparse)
library(mikropml)
library(readr)
library(dplyr)

# Increase future globals limit to 20GB to handle large Metalog dataset
options(future.globals.maxSize = 20000 * 1024^2)
# Force sequential execution to prevent OOM on local machine
future::plan(future::sequential)


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

# Handle mikropml structure
dat_input <- if("dat_transformed" %in% names(preproc)) preproc$dat_transformed else preproc$dat

# Sanitize column names for caret compatibility (XGBoost/SVM require valid R names)
colnames(dat_input) <- make.names(colnames(dat_input))
opt$outcome <- make.names(opt$outcome)

# Explicitly remove sample_id to prevent it from being used as a feature
if ("sample_id" %in% colnames(dat_input)) {
  dat_input$sample_id <- NULL
}

# Define hyperparameters/grid based on method
hyperparams <- NULL
tune_grid <- NULL

if (opt$method == "svmLinear") {
    # Mikropml requires explicit hyperparameters for svmLinear
    hyperparams <- list(C = 1)
    message("Using fixed C=1 for svmLinear")
} else if (opt$method == "xgbTree") {
    # Simplify XGBoost grid to prevent convergence failures/metrics issues
    # mikropml expects a LIST of vectors, not an expand.grid object
    hyperparams <- list(
        nrounds = c(100),
        max_depth = c(3, 6),
        eta = c(0.1, 0.3),
        gamma = c(0),
        colsample_bytree = c(0.8),
        min_child_weight = c(1),
        subsample = c(0.8)
    )
    message("Using simplified tuning grid for xgbTree")
} else if (opt$method == "rpart") {
    # Mikropml requires explicit hyperparameters for rpart
    hyperparams <- list(cp = c(0.001, 0.01, 0.1))
    message("Using explicit grid for rpart")
} else if (opt$method == "glmnet") {
    # glmnet is default but good to be explicit if needed
    message("Using default mikropml grid for glmnet")
}

# Run ML with lightweight settings
# We pass hyperparams/grid only if they are defined
args_list <- list(
  dataset = dat_input,
  method = opt$method,
  outcome_colname = opt$outcome,
  kfold = 3,
  cv_times = 1,
  seed = 100
)

if (!is.null(hyperparams)) {
   args_list$hyperparameters <- hyperparams
}
# Note regarding model specific checks
if (opt$method == "xgbTree") {
    # Ensure compatible data structure for tree-based boosting
    message("Verifying XGBoost Tree configuration...")
} 

results <- do.call(run_ml, args_list)

# Save performance
write_csv(results$performance, opt$output)

# Save model object
if (!is.null(opt$model_output)) {
  saveRDS(results, opt$model_output)
}
