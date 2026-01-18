# Microbiome Biomarker Discovery for Thesis

This repository contains the machine learning workflow for analyzing microbiome data to predict BMI and Activity levels.

## Project Overview

**Objective:** Identify robust microbiome biomarkers associated with BMI and physical activity.

**Methodology:**
1.  **Data Preprocessing:**
    *   Prevalence Filtering: Retain features present in >1% of samples.
    *   **Variance Filtering:** Select Top 1000 features by variance to reduce dimensionality and noise (Bioinformatics Standard).
2.  **Machine Learning Models:**
    *   Random Forest (RF)
    *   XGBoost (xgbTree)
    *   Support Vector Machine (svmLinear)
3.  **Validation:**
    *   5-Fold Cross-Validation for robust performance estimation.
4.  **Output:**
    *   High-resolution SVG plots for thesis inclusion.

## Workflow

The analysis is implemented using **Nextflow** for reproducibility and scalability.

### Usage

Run the workflow using Nextflow:
```bash
nextflow run main.nf
```

### Dependencies
*   Nextflow
*   R (with mikropml, caret, xgboost, kernlab, svglite)
