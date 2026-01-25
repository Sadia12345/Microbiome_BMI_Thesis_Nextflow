#!/usr/bin/env Rscript

library(optparse)
library(mikropml)
library(dplyr)
library(ggplot2)
library(caret)
library(svglite)

# Argument Parsing
option_list <- list(
  make_option(c("-i", "--input"), type = "character", help = "Input preprocessed RDS"),
  make_option(c("-o", "--outdir"), type = "character", help = "Output directory"),
  make_option(c("-c", "--outcome"), type = "character", default = "bmi", help = "Outcome column name")
)

opt <- parse_args(OptionParser(option_list = option_list))

if (is.null(opt$input) || is.null(opt$outdir)) {
  stop("Usage: Rscript run_saturation.R --input <rds> --outdir <dir> [--outcome <col>]")
}

if (!dir.exists(opt$outdir)) {
  dir.create(opt$outdir, recursive = TRUE)
}

message("Loading preprocessed data: ", opt$input)
data_obj <- readRDS(opt$input)
# Handle potential list structure from preprocess.R
dat <- if("dat_transformed" %in% names(data_obj)) data_obj$dat_transformed else data_obj$dat

# Sanitize again to be safe (though main pipeline does it)
colnames(dat) <- make.names(colnames(dat))
outcome_col <- make.names(opt$outcome)

# Explicitly remove sample_id to prevent it from being used as a feature
if ("sample_id" %in% colnames(dat)) {
  dat$sample_id <- NULL
}

message("Total samples: ", nrow(dat))

# diverse sample sizes (The "Leo Curve" - High Res)
# We test every 2k to see the precise saturation point
sizes <- seq(2000, 16000, by = 2000)
# Ensure we don't go over data limit
sizes <- sizes[sizes <= nrow(dat)]

results_df <- data.frame(
  n_samples = integer(),
  model = character(),
  r_squared = numeric(),
  rmse = numeric(),
  time_sec = numeric()
)

message("Starting 'Feasibility First' Saturation Analysis...")

# Define models to test
# Note: Using 'kfold=3' for robustness as promised in thesis
models_to_test <- c("rf", "svmLinear", "rpart", "xgbTree")

# Loop through sizes
for (n in sizes) {
    if (n > nrow(dat)) next
    
    message("------------------------------------------------")
    message("Running for sample size: ", n)
    
    # Subsample 
    set.seed(42)
    sample_idxs <- sample(seq_len(nrow(dat)), size = n)
    sub_dat <- dat[sample_idxs, ]
    
    # Check each model
    for (mod in models_to_test) {
        message("  > Training Model: ", mod)
        
        # Define model-specific tuning to ensure speed/convergence
        hyperparams <- NULL
        if (mod == "xgbTree") {
            # Lightweight XGBoost grid for saturation (prevents hanging)
            hyperparams <- list(
                nrounds = c(100),
                max_depth = c(3),
                eta = c(0.3),
                gamma = c(0),
                colsample_bytree = c(0.8),
                min_child_weight = c(1),
                subsample = c(0.8)
            )
        } else if (mod == "svmLinear") {
             hyperparams <- list(C = 1)
        } else if (mod == "rpart") {
             hyperparams <- list(cp = c(0.01))
        }
        
        start_time <- Sys.time()
        
        tryCatch({
            # Construct args list to conditionally include hyperparameters
            args_list <- list(
                dataset = sub_dat,
                method = mod,
                outcome_colname = outcome_col,
                kfold = 3,
                cv_times = 1,
                training_frac = 0.8,
                seed = 42
            )
            
            if (!is.null(hyperparams)) {
                args_list$hyperparameters <- hyperparams
            }
            
            ml_res <- do.call(run_ml, args_list)
            
            end_time <- Sys.time()
            duration <- as.numeric(difftime(end_time, start_time, units = "secs"))
            
            # Extract metrics
            perf <- ml_res$performance
            r2 <- perf$Rsquared[1]
            rmse <- perf$RMSE[1]
        
            message("    Completed ", mod, " (", n, " samples). R2: ", round(r2, 3), " Time: ", round(duration, 1), "s")
        
            results_df <- rbind(results_df, data.frame(
                n_samples = n,
                model = mod,
                r_squared = r2,
                rmse = rmse,
                time_sec = duration
            ))
            
            # Save intermediate immediately (Safety)
            write.csv(results_df, file.path(opt$outdir, "saturation_results_partial.csv"), row.names = FALSE)
            
            # Cleanup to prevent OOM
            rm(ml_res)
            gc()
            
        }, error = function(e) {
            message("    FAILED ", mod, ": ", e$message)
        })
    }
}

# Save final
final_csv <- file.path(opt$outdir, "saturation_results.csv")
write.csv(results_df, final_csv, row.names = FALSE)

# Plotting (SVG) - Model Comparison Curve
p1 <- ggplot(results_df, aes(x = n_samples, y = r_squared, color = model)) +
    geom_line(linewidth = 1) +
    geom_point(size = 3) +
    labs(title = "Thesis Saturation Curve: Performance vs Sample Size",
         subtitle = "Determining the 'Feasible' Sample Cutoff",
         x = "Number of Samples",
         y = "R-squared") +
    theme_minimal() +
    ylim(0, max(results_df$r_squared, na.rm=TRUE) * 1.2)

ggsave(file.path(opt$outdir, "saturation_r2.svg"), p1, width = 7, height = 5)

p2 <- ggplot(results_df, aes(x = n_samples, y = time_sec, color = model)) +
    geom_line(linewidth = 1) +
    geom_point(size = 3) +
    labs(title = "Computational Scalability",
         subtitle = "Training Time vs. Sample Size",
         x = "Number of Samples",
         y = "Time (seconds)") +
    theme_minimal()

ggsave(file.path(opt$outdir, "scaling_time.svg"), p2, width = 7, height = 5)

message("Saturation Analysis Complete. Results saved to ", opt$outdir)
