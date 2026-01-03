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

# Preprocess
# method="glmnet" is just a default placeholder, preprocessing is general
preproc <- preprocess_data(dat, outcome_colname = opt$outcome)

# Save
saveRDS(preproc, opt$output)
