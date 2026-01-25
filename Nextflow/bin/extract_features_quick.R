#!/usr/bin/env Rscript

library(optparse)
library(mikropml)
library(dplyr)

option_list <- list(
  make_option(c("-i", "--input"), type = "character", help = "Input preprocessed RDS"),
  make_option(c("-o", "--outdir"), type = "character", help = "Output directory"),
  make_option(c("-c", "--outcome"), type = "character", default = "bmi", help = "Outcome column name")
)
opt <- parse_args(OptionParser(option_list = option_list))
if (!dir.exists(opt$outdir)) dir.create(opt$outdir, recursive = TRUE)

message("Loading data for Feature Extraction...")
data_obj <- readRDS(opt$input)
dat <- if("dat_transformed" %in% names(data_obj)) data_obj$dat_transformed else data_obj$dat

colnames(dat) <- make.names(colnames(dat))
outcome_col <- make.names(opt$outcome)
if ("sample_id" %in% colnames(dat)) dat$sample_id <- NULL

# Train on 12,000 samples (The Saturation Sweet Spot)
set.seed(42)
sample_idxs <- sample(seq_len(nrow(dat)), size = min(12000, nrow(dat)))
sub_dat <- dat[sample_idxs, ]

message("Training RF to extract features (12k samples)...")
ml_res <- run_ml(
    sub_dat,
    "rf",
    outcome_colname = outcome_col,
    kfold = 3,
    cv_times = 1,
    training_frac = 0.8,
    seed = 42
)

# Extract Features
feat_imp <- ml_res$feature_importance
top_20 <- head(feat_imp, 20)

# Save
write.csv(top_20, file.path(opt$outdir, "top_20_features.csv"), row.names = FALSE)
message("Top 20 Features saved.")
