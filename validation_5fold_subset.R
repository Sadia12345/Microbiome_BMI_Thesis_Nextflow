# 5-fold versus 3-fold CV validation on a 5,000-sample subset
# Intended for Google Colab (R runtime) or any R session with internet access

install.packages(c("caret", "randomForest", "doParallel"), quiet = TRUE)

library(caret)
library(randomForest)
library(doParallel)

registerDoParallel(2)

data <- readRDS("preprocessed_filtered.rds")
dat <- data$dat_transformed

set.seed(42)
sub <- dat[sample(nrow(dat), 5000), ]
cat("Subset:", nrow(sub), "rows /", ncol(sub), "cols\n")

ctrl3 <- trainControl(method = "cv", number = 3, allowParallel = TRUE)
ctrl5 <- trainControl(method = "cv", number = 5, allowParallel = TRUE)

m3 <- train(bmi ~ ., data = sub, method = "rf", trControl = ctrl3, ntree = 100)
m5 <- train(bmi ~ ., data = sub, method = "rf", trControl = ctrl5, ntree = 100)

cat("\n3-fold R^2:", round(max(m3$results$Rsquared, na.rm = TRUE), 3), "\n")
cat("5-fold R^2:", round(max(m5$results$Rsquared, na.rm = TRUE), 3), "\n")
cat("3-fold RMSE:", round(min(m3$results$RMSE, na.rm = TRUE), 3), "\n")
cat("5-fold RMSE:", round(min(m5$results$RMSE, na.rm = TRUE), 3), "\n")
