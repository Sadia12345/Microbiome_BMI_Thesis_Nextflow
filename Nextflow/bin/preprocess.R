#!/usr/bin/env Rscript

library(optparse)
library(mikropml)
library(readr)

# Increase future globals limit to 20GB to handle large Metalog dataset
options(future.globals.maxSize = 20000 * 1024^2)


option_list <- list(
  make_option(c("-i", "--input"), type = "character", help = "Input dataset CSV"),
  make_option(c("-o", "--output"), type = "character", help = "Output preprocessed RDS"),
  make_option(c("-c", "--outcome"), type = "character", help = "Outcome column name")
)

opt <- parse_args(OptionParser(option_list = option_list))

# Load data
dat <- read_csv(opt$input)

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

# 5. Reconstruct dataframe
dat_filtered <- dat[, c(intersect(names(dat), metadata_cols), keep_feats)]
message("Filtered dimensions: ", paste(dim(dat_filtered), collapse = " x "))


# Preprocess
# method="glmnet" is just a default placeholder, preprocessing is general
preproc <- preprocess_data(dat_filtered, outcome_colname = opt$outcome)

# Save
saveRDS(preproc, opt$output)
