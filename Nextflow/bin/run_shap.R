#!/usr/bin/env Rscript

library(optparse)
library(ggplot2)
library(dplyr)
library(mikropml)
library(caret)

# Handling package installation if missing
if (!requireNamespace("fastshap", quietly = TRUE)) {
  install.packages("fastshap", repos = "https://cloud.r-project.org")
}
library(fastshap)

option_list <- list(
  make_option(c("-m", "--model"), type = "character", help = "Path to trained model .rds file"),
  make_option(c("-d", "--data"), type = "character", help = "Path to training data .rds file"),
  make_option(c("-o", "--output"), type = "character", help = "Output path for SHAP plot")
)

opt <- parse_args(OptionParser(option_list = option_list))

# Load Model
message("Loading model: ", opt$model)
model_obj <- readRDS(opt$model)

# Extract the actual caret model
if ("trained_model" %in% names(model_obj)) {
  final_model <- model_obj$trained_model
} else {
  final_model <- model_obj
}

# Load Data
message("Loading data: ", opt$data)
dat <- readRDS(opt$data)

# Handle mikropml list output
if (is.list(dat) && !is.data.frame(dat)) {
  message("Loaded object is a list. Extracting dataframe...")
  if ("dat" %in% names(dat)) {
    dat <- dat$dat
  } else if ("dat_transformed" %in% names(dat)) {
    dat <- dat$dat_transformed
  } else {
    stop("Data loaded is a list but neither 'dat' nor 'dat_transformed' slot found. Available: ", paste(names(dat), collapse=", "))
  }
}
# Preprocess data if necessary (mikropml objects usually contain the processed data in the 'dat' slot)
# But here we pass the preprocessed file directly.
# Depending on mikropml version, we might need to extract the feature matrix.

# Prepare feature matrix for SHAP
# We need X (features) only.
# Assume 'bmi' or outcome is in the data, remove it.
# Also remove sample_id if present.
features <- dat %>% select(-one_of(c("bmi", "sample_id", "age", "sex", "weight"))) 

# Prediction wrapper for fastshap (caret models need specific wrapper)
pfun <- function(object, newdata) {
  predict(object, newdata = newdata)
}

# Calculate SHAP values (using a subset for speed if large)
# Metalog is 17k. SHAP on 17k is slow. Let's use a background set of 50 samples for speed.
set.seed(123)
sample_indices <- sample(nrow(features), min(50, nrow(features)))
X_subset <- features[sample_indices, ]

message("Computing SHAP values on ", nrow(X_subset), " samples...")

# fastshap explain
shap_vals <- explain(
  final_model, 
  X = X_subset, 
  pred_wrapper = pfun, 
  nsim = 10 # Number of Monte Carlo simulations
)

# Create Summary Plot
message("Generating SHAP summary plot...")
# p <- autoplot(shap_vals, type = "dependence", feature = names(shap_vals)[1], X = X_subset) 

# Manual plotting code follows...

# fastshap autoplot is limited. Better to use manual plotting for summary (beeswarm style is standard but hard in base R).
# Let's use a simple bar chart of mean absolute SHAP values.
shap_imp <- data.frame(
  Variable = names(X_subset),
  Importance = colMeans(abs(shap_vals))
) %>%
  arrange(desc(Importance)) %>%
  head(20) # Top 20

p_summary <- ggplot(shap_imp, aes(x = reorder(Variable, Importance), y = Importance)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(title = "SHAP Feature Importance (Top 20)",
       x = "Feature",
       y = "Mean Absolute SHAP Value") +
  theme_minimal()

ggsave(opt$output, plot = p_summary, width = 8, height = 6)
message("SHAP plot saved to ", opt$output)
