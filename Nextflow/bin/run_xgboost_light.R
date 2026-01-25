#!/usr/bin/env Rscript

library(optparse)
library(mikropml)
library(dplyr)
library(caret)

# Argument Parsing
option_list <- list(
  make_option(c("-i", "--input"), type = "character", help = "Input preprocessed RDS"),
  make_option(c("-o", "--outdir"), type = "character", help = "Output directory"),
  make_option(c("-c", "--outcome"), type = "character", default = "bmi", help = "Outcome column name")
)

opt <- parse_args(OptionParser(option_list = option_list))

if (!dir.exists(opt$outdir)) dir.create(opt$outdir, recursive = TRUE)

message("Loading data for Lightweight XGBoost...")
data_obj <- readRDS(opt$input)
dat <- if("dat_transformed" %in% names(data_obj)) data_obj$dat_transformed else data_obj$dat

colnames(dat) <- make.names(colnames(dat))
outcome_col <- make.names(opt$outcome)
if ("sample_id" %in% colnames(dat)) dat$sample_id <- NULL

# "Lightweight" Sample Sizes (Skip the massive ones to ensure success)
# We focus on the curve shape: 2k, 5k, 8k, 12k
sizes <- c(2000, 5000, 8000, 12000)
sizes <- sizes[sizes <= nrow(dat)]

results_df <- data.frame()

for (n in sizes) {
    message("Running XGBoost (Light) on ", n, " samples...")
    
    set.seed(42)
    sample_idxs <- sample(seq_len(nrow(dat)), size = n)
    sub_dat <- dat[sample_idxs, ]
    
    # ULTRA-LIGHT HYPERPARAMETERS
    # This is the key to making it finish
    xgb_grid <- expand.grid(
        nrounds = 50,          # Reduced from 100
        max_depth = 2,         # Reduced from 3 (shallower trees = faster)
        eta = 0.3, 
        gamma = 0, 
        colsample_bytree = 0.8,
        min_child_weight = 1,
        subsample = 0.8
    )
    
    start_time <- Sys.time()
    
    tryCatch({
        ml_res <- run_ml(
            sub_dat,
            "xgbTree",
            outcome_colname = outcome_col,
            kfold = 3,
            cv_times = 1,
            training_frac = 0.8,
            seed = 42,
            hyperparameters = list(
                nrounds = c(50),
                max_depth = c(2),
                eta = c(0.3),
                gamma = c(0),
                colsample_bytree = c(0.8),
                min_child_weight = c(1),
                subsample = c(0.8)
            )
        )
        
        duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
        r2 <- ml_res$performance$Rsquared[1]
        
        message("  >> SUCCESS: R2 = ", round(r2, 3))
        
        results_df <- rbind(results_df, data.frame(
            n_samples = n,
            model = "xgbTree_Light",
            r_squared = r2,
            rmse = ml_res$performance$RMSE[1],
            time_sec = duration
        ))
        
        write.csv(results_df, file.path(opt$outdir, "xgboost_light_results.csv"), row.names = FALSE)
        
    }, error = function(e) {
        message("  >> FAILED: ", e$message)
    })
}

message("XGBoost Light Complete.")
