#!/usr/bin/env Rscript

library(optparse)
library(dplyr)
library(caret)
library(randomForest)

option_list <- list(
  make_option(c("-i", "--input"), type = "character", help = "Input preprocessed RDS"),
  make_option(c("-o", "--outdir"), type = "character", help = "Output directory"),
  make_option(c("-c", "--outcome"), type = "character", default = "bmi", help = "Outcome column name")
)
opt <- parse_args(OptionParser(option_list = option_list))
if (!dir.exists(opt$outdir)) dir.create(opt$outdir, recursive = TRUE)

message("Loading data...")
data_obj <- readRDS(opt$input)
dat <- if("dat_transformed" %in% names(data_obj)) data_obj$dat_transformed else data_obj$dat

colnames(dat) <- make.names(colnames(dat))
outcome_col <- make.names(opt$outcome)
if ("sample_id" %in% colnames(dat)) dat$sample_id <- NULL

# Use 10k samples for speed
set.seed(42)
n <- min(10000, nrow(dat))
sample_idxs <- sample(seq_len(nrow(dat)), size = n)
sub_dat <- dat[sample_idxs, ]

message("Training Random Forest on ", n, " samples...")

# Prepare formula
y <- sub_dat[[outcome_col]]
X <- sub_dat %>% select(-all_of(outcome_col))

# Train using caret directly
ctrl <- trainControl(method = "cv", number = 3)
rf_model <- train(x = X, y = y, method = "rf", trControl = ctrl, importance = TRUE)

message("Extracting feature importance...")
imp <- varImp(rf_model, scale = TRUE)
imp_df <- imp$importance
imp_df$Feature <- rownames(imp_df)
imp_df <- imp_df %>% arrange(desc(Overall)) %>% head(20)

# Save
write.csv(imp_df, file.path(opt$outdir, "top_20_features.csv"), row.names = FALSE)
message("Top 20 Features saved to ", file.path(opt$outdir, "top_20_features.csv"))
