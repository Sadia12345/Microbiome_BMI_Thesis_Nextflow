#!/usr/bin/env Rscript

library(optparse)
library(dplyr)
library(xgboost)
library(caret) # Only for creating folds, not for training

# Argument Parsing
option_list <- list(
  make_option(c("-i", "--input"), type = "character", help = "Input preprocessed RDS"),
  make_option(c("-o", "--outdir"), type = "character", help = "Output directory"),
  make_option(c("-c", "--outcome"), type = "character", default = "bmi", help = "Outcome column name")
)

opt <- parse_args(OptionParser(option_list = option_list))

if (!dir.exists(opt$outdir)) dir.create(opt$outdir, recursive = TRUE)

message("Loading data for Native XGBoost...")
data_obj <- readRDS(opt$input)
dat <- if("dat_transformed" %in% names(data_obj)) data_obj$dat_transformed else data_obj$dat
colnames(dat) <- make.names(colnames(dat))
if ("sample_id" %in% colnames(dat)) dat$sample_id <- NULL

# Prepare data for XGBoost (Matrix format)
outcome_col <- opt$outcome
y <- dat[[outcome_col]]
X <- dat %>% select(-all_of(outcome_col)) %>% as.matrix()

# Sample sizes to test
sizes <- c(2000, 4000, 8000, 12000)
sizes <- sizes[sizes <= nrow(dat)]

results_df <- data.frame()

for (n in sizes) {
    message("Running Native XGBoost on ", n, " samples...")
    
    set.seed(42)
    sample_idxs <- sample(seq_len(nrow(dat)), size = n)
    
    X_sub <- X[sample_idxs, ]
    y_sub <- y[sample_idxs]
    
    # Create DMatrix
    dtrain <- xgb.DMatrix(data = X_sub, label = y_sub)
    
    start_time <- Sys.time()
    
    # Train using xgb.cv to get cross-validated metrics directly
    cv_res <- xgb.cv(
        data = dtrain,
        nrounds = 50,
        nfold = 3,
        max_depth = 2,
        eta = 0.3,
        objective = "reg:squarederror",
        metrics = "rmse",
        verbose = 0
    )
    
    # Get best RMSE
    best_rmse <- min(cv_res$evaluation_log$test_rmse_mean)
    
    # Estimate R2 (approximate from RMSE and variance of y)
    mse <- best_rmse^2
    var_y <- var(y_sub)
    r2 <- 1 - (mse / var_y)
    
    duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    
    message("  >> Success! R2: ", round(r2, 3), " RMSE: ", round(best_rmse, 3))
    
    results_df <- rbind(results_df, data.frame(
        n_samples = n,
        model = "xgbTree_Native",
        r_squared = r2,
        rmse = best_rmse,
        time_sec = duration
    ))
    
    write.csv(results_df, file.path(opt$outdir, "xgboost_native_results.csv"), row.names = FALSE)
}

message("Native XGBoost Complete.")
