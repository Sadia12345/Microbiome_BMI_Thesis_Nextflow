#!/usr/bin/env Rscript

library(optparse)
library(data.table)

# Increase future globals limit to 20GB to handle large Metalog dataset
options(future.globals.maxSize = 20000 * 1024^2)
# Force sequential execution to prevent OOM
future::plan(future::sequential)


option_list <- list(
  make_option(c("-i", "--input"), type = "character", help = "Input dataset CSV"),
  make_option(c("-o", "--output"), type = "character", help = "Output preprocessed RDS"),
  make_option(c("-c", "--outcome"), type = "character", help = "Outcome column name")
)

opt <- parse_args(OptionParser(option_list = option_list))

# Load data efficiently
message("Loading data...")
dat <- fread(opt$input, data.table = FALSE)

message("Original dimensions: ", paste(dim(dat), collapse = " x "))

# Filtering Steps
# 1. Identify metadata columns to protect
metadata_cols <- c("sample_id", "bmi", "age", "sex", "weight", opt$outcome)
# Ensure we don't duplicate if outcome is already in list
metadata_cols <- unique(metadata_cols)

# 2. Separate features
feature_cols <- setdiff(names(dat), metadata_cols)
message("Number of features before filtering: ", length(feature_cols))

# 3. Calculate prevalence (assuming 0 means absent, using abundance data)
# Use a fast matrix operation
feat_mat <- as.matrix(dat[, feature_cols])
# Calculate fraction of samples where abundance > 0
prevalence <- colMeans(feat_mat > 0, na.rm = TRUE)

# 4. Filter features with prevalence < 1%
keep_feats <- names(prevalence)[prevalence >= 0.01]
message("features to keep (>= 1% prevalence): ", length(keep_feats))

# 4.5 Variance Filtering: Keep top 500 features by variance (Feature Sniper Strategy)
if (length(keep_feats) > 500) {
    message("Performing variance filtering (top 500)...")
    # Subsample data
    subset_dat <- dat[, keep_feats]
    subset_mat <- as.matrix(subset_dat)
    # Calculate variance
    variances <- apply(subset_mat, 2, var, na.rm = TRUE)
    # Identify top 500
    top_500_names <- names(sort(variances, decreasing = TRUE))[1:min(500, length(variances))]
    keep_feats <- top_500_names
    message("features reduced to top 500 by variance.")
} else {
    message("Features count ", length(keep_feats), " <= 500, skipping variance filter.")
}

# 5. Reconstruct dataframe
dat_filtered <- dat[, c(intersect(names(dat), metadata_cols), keep_feats)]
message("Filtered dimensions: ", paste(dim(dat_filtered), collapse = " x "))

# CLEANUP: Free memory of the large raw dataset
rm(dat)
gc()

# Manual Preprocessing (Lightweight - No Caret)
message("Starting Lightweight Preprocessing...")

# 1. Manual Near Zero Variance
# Function to check if a vector is constant or near constant
is_near_zero_var <- function(x) {
  if (is.numeric(x)) {
    return(var(x, na.rm = TRUE) == 0)
  }
  # For character/factor, check unique values
  u <- unique(x)
  return(length(u) <= 1)
}

# Identify NZV columns
nzv_cols <- sapply(dat_filtered, is_near_zero_var)
keep_cols <- names(nzv_cols)[!nzv_cols]

# Ensure outcome is kept
if(!(opt$outcome %in% keep_cols)) keep_cols <- c(opt$outcome, keep_cols)
dat_selected <- dat_filtered[, keep_cols]

# Convert to data.table for in-place modification
setDT(dat_selected)

# 2. Scale & Center Numeric columns
num_cols <- sapply(dat_selected, is.numeric)
# Exclude outcome from scaling
num_cols[opt$outcome] <- FALSE

if(sum(num_cols) > 0) {
  # Use set operation for memory efficiency
  cols_to_scale <- names(num_cols)[num_cols]
  dat_selected[, (cols_to_scale) := lapply(.SD, scale), .SDcols = cols_to_scale]
}

message("Manual processing done. Dimensions: ", paste(dim(dat_selected), collapse = " x "))

# Save
preproc <- list(dat_transformed = dat_selected)
saveRDS(preproc, opt$output)
