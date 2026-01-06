#!/usr/bin/env Rscript

library(mikropml)
library(dplyr)
library(ggplot2)
library(caret)

# Arguments
args <- commandArgs(trailingOnly = TRUE)
data_path <- args[1] # e.g., "results/preprocessed.rds"
out_dir <- args[2]   # e.g., "results/saturation"

if (is.na(data_path) || is.na(out_dir)) {
  stop("Usage: Rscript run_saturation.R <preprocessed.rds> <out_dir>")
}

if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

message("Loading preprocessed data: ", data_path)
data_obj <- readRDS(data_path)
dat <- data_obj$dat_transformed
outcome_col <- "bmi" # Hardcoded for now as per pipeline

message("Total samples: ", nrow(dat))

# diverse sample sizes to test saturation
# Ensure we don't request more samples than exist
all_sizes <- c(1000, 5000, 10000, 15000, nrow(dat))
sizes <- sort(unique(all_sizes[all_sizes <= nrow(dat)]))

results_df <- data.frame(
  n_samples = integer(),
  r_squared = numeric(),
  rmse = numeric(),
  time_sec = numeric()
)

message("Starting Saturation Analysis...")

for (n in sizes) {
    message("------------------------------------------------")
    message("Running for sample size: ", n)
    
    # Subsample (stratified not strictly necessary for regression but good practice)
    # Simple random sample
    set.seed(42)
    sample_idxs <- sample(seq_len(nrow(dat)), size = n)
    sub_dat <- dat[sample_idxs, ]
    
    # Run ML (RF)
    # Using 'rf' but with FASTER controls for saturation check (e.g. fewer CV folds)
    # 2-fold CV is enough to get a performance estimate for the trend line
    start_time <- Sys.time()
    
    ml_res <- run_ml(
        sub_dat,
        "rf",
        outcome_colname = outcome_col,
        kfold = 2, # Fast CV
        cv_times = 1,
        training_frac = 0.8,
        seed = 42
    )
    
    end_time <- Sys.time()
    duration <- as.numeric(difftime(end_time, start_time, units = "secs"))
    
    # Extract metrics
    perf <- ml_res$performance
    r2 <- perf$Rsquared[1] # Mean Rsquared
    rmse <- perf$RMSE[1]
    
    message("Completed size ", n, ". R2: ", round(r2, 3), " Time: ", round(duration, 1), "s")
    
    results_df <- rbind(results_df, data.frame(
        n_samples = n,
        r_squared = r2,
        rmse = rmse,
        time_sec = duration
    ))
    
    # Save intermediate
    write.csv(results_df, file.path(out_dir, "saturation_results_partial.csv"), row.names = FALSE)
}

# Save final
final_csv <- file.path(out_dir, "saturation_results.csv")
write.csv(results_df, final_csv, row.names = FALSE)

# Plotting
p1 <- ggplot(results_df, aes(x = n_samples, y = r_squared)) +
    geom_line(color = "blue", linewidth = 1) +
    geom_point(size = 3) +
    labs(title = "Saturation Curve: Random Forest Performance",
         subtitle = "Performance vs. Sample Size",
         x = "Number of Samples",
         y = "R-squared") +
    theme_minimal() +
    ylim(0, max(results_df$r_squared) * 1.2)

ggsave(file.path(out_dir, "saturation_r2.png"), p1, width = 6, height = 4)

p2 <- ggplot(results_df, aes(x = n_samples, y = time_sec)) +
    geom_line(color = "red", linewidth = 1) +
    geom_point(size = 3) +
    labs(title = "Computational Scalability",
         subtitle = "Training Time vs. Sample Size",
         x = "Number of Samples",
         y = "Time (seconds)") +
    theme_minimal()

ggsave(file.path(out_dir, "scaling_time.png"), p2, width = 6, height = 4)

message("Saturation Analysis Complete. Results saved to ", out_dir)
