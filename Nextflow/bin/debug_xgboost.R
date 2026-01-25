#!/usr/bin/env Rscript

library(mikropml)
library(dplyr)
library(caret)

message("Loading data...")
# Hardcoded path for speed testing
data_obj <- readRDS("/Users/tahmid_23/Thesis_Project/Nextflow/work/19/aafa95663ac7c9030de01311b723bc/preprocessed.rds")
dat <- if("dat_transformed" %in% names(data_obj)) data_obj$dat_transformed else data_obj$dat
colnames(dat) <- make.names(colnames(dat))
if ("sample_id" %in% colnames(dat)) dat$sample_id <- NULL

# Try TINY sample size to rule out memory
n <- 500
message("Testing XGBoost on ", n, " samples...")

set.seed(42)
sample_idxs <- sample(seq_len(nrow(dat)), size = n)
sub_dat <- dat[sample_idxs, ]

# Explicit minimal grid
xgb_grid <- list(
    nrounds = c(10),
    max_depth = c(2),
    eta = c(0.3),
    gamma = c(0),
    colsample_bytree = c(0.8),
    min_child_weight = c(1),
    subsample = c(0.8)
)

tryCatch({
    ml_res <- run_ml(
        sub_dat,
        "xgbTree",
        outcome_colname = "bmi",
        kfold = 2,
        cv_times = 1,
        hyperparameters = xgb_grid,
        seed = 42
    )
    print(ml_res$performance)
    message("SUCCESS via run_ml")
}, error = function(e) {
    message("FAILED via run_ml: ", e$message)
})
