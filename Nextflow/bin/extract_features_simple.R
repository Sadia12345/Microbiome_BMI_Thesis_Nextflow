#!/usr/bin/env Rscript

# Simplified feature extraction using base randomForest
library(randomForest)
library(dplyr)

message("Loading data...")
data_obj <- readRDS("/Users/tahmid_23/Thesis_Project/Nextflow/work/19/aafa95663ac7c9030de01311b723bc/preprocessed.rds")
dat <- if("dat_transformed" %in% names(data_obj)) data_obj$dat_transformed else data_obj$dat

colnames(dat) <- make.names(colnames(dat))
if ("sample_id" %in% colnames(dat)) dat$sample_id <- NULL

# Use 5000 samples for faster training
set.seed(42)
n <- min(5000, nrow(dat))
sample_idxs <- sample(seq_len(nrow(dat)), size = n)
sub_dat <- dat[sample_idxs, ]

message("Training RF on ", n, " samples with importance=TRUE...")

y <- sub_dat$bmi
X <- sub_dat %>% select(-bmi)

# Train RF directly (no caret wrapper)
rf_model <- randomForest(x = X, y = y, ntree = 100, importance = TRUE)

message("Extracting importance...")
imp <- importance(rf_model)
imp_df <- data.frame(
    Feature = rownames(imp),
    IncMSE = imp[, "%IncMSE"],
    IncNodePurity = imp[, "IncNodePurity"]
)
imp_df <- imp_df %>% arrange(desc(IncMSE)) %>% head(20)

# Save
outdir <- "/Users/tahmid_23/Thesis_Project/Nextflow/results/features"
if (!dir.exists(outdir)) dir.create(outdir, recursive = TRUE)
write.csv(imp_df, file.path(outdir, "top_20_features.csv"), row.names = FALSE)

message("SUCCESS! Top 20 Features saved.")
print(imp_df)
