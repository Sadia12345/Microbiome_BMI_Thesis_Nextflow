#!/usr/bin/env Rscript
# Extract the real cross-validated Random Forest predictions from the saved model
# (a mikropml run_ml() result, e.g. results/rf_model.rds) and write them to CSV.
# These are the out-of-fold predictions on the training partition (best mtry = 16),
# i.e. the exact points behind the predicted-vs-actual scatter and the prediction-error
# distribution figure in the thesis Results chapter.
#
# The model file is large and is not redistributed in this repository; set its path
# with the RF_MODEL environment variable (defaults to results/rf_model.rds).
#
# Usage:  RF_MODEL=path/to/rf_model.rds Rscript extract_rf_predictions.R
# Output: rf_cv_predictions.csv  (columns: obs, pred)
# The figure is then produced by plot_prediction_error.py from this CSV.

model_path <- Sys.getenv("RF_MODEL", "results/rf_model.rds")
m <- readRDS(model_path)
p <- m$trained_model$pred
best <- m$trained_model$bestTune$mtry
p <- p[p$mtry == best, c("obs", "pred")]

err <- p$pred - p$obs
mae <- mean(abs(err)); rmse <- sqrt(mean(err^2))
r2 <- 1 - sum(err^2) / sum((p$obs - mean(p$obs))^2)
cat(sprintf("n=%d  MAE=%.3f  RMSE=%.3f  R2=%.3f\n", nrow(p), mae, rmse, r2))
cat(sprintf("within 2 = %.1f%%, within 5 = %.1f%%\n",
            100 * mean(abs(err) <= 2), 100 * mean(abs(err) <= 5)))

write.csv(p, "rf_cv_predictions.csv", row.names = FALSE)
cat("wrote rf_cv_predictions.csv\n")
