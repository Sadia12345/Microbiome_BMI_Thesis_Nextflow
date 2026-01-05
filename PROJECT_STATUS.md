# Project Technical Status & Handover Report
**Date:** January 2026
**Author:** Sadia Zaman

## 1. Project Summary
This project implements a Machine Learning pipeline to predict BMI from microbiome data (`metalog_subset.csv`).
The pipeline uses **Nextflow** for workflow management and **R (mikropml)** for model training.

## 2. Completed Work
### A. Data Preprocessing
- **Status:** ✅ Complete
- **Details:** The raw dataset (17,903 samples) was successfully preprocessed.
- **Output:** `preprocessed.rds`

### B. Modeling Status
| Model | Status | Result ($R^2$) | Notes |
| :--- | :--- | :--- | :--- |
| **GLMNet** (Lasso) | ✅ **Complete** | **0.14** | Ran successfully locally. |
| **Random Forest** | ⚠️ *Partial* | 0.325 | Result from older Dec 18 run. Recent full run failed. |
| **XGBoost** | ❌ Failed | - | Terminated due to hardware time limits (28h+). |
| **SVM (Radial)** | ❌ Failed | - | Terminated due to hardware time limits (28h+). |

## 3. Limitations (Why Local Training Failed)
Attempts to run the full benchmark on a local MacBook Pro failed three times (exceeding 28 hours).
- **Reason:** The dataset size (17k samples x 20k features) requires massive computational power.
- **Hardware Bottleneck:** Local laptops (even powerful ones) cannot sustain the continuous 30-50 hour uptime required for `SVM` and `XGBoost` without sleep/network interruption ("SIGHUP" errors).

## 4. Next Steps (Supercomputer Deployment)
To complete the thesis, you **must** run the pipeline on the CSC Supercomputer using the files already uploaded to GitHub.

### Step 1: Login to CSC
Login to the university server (e.g., Puhti/Mahti) via terminal.

### Step 2: Download Code
```bash
git clone https://github.com/Sadia12345/Microbiome_BMI_Thesis.git
cd Microbiome_BMI_Thesis
```

### Step 3: Run Pipeline
Execute the specialized profile for SLURM clusters:
```bash
# This sends the job to the queue system. It will NOT close when you disconnect.
nextflow run main.nf -profile csc -resume
```

### Step 4: Harvest Results
Check back in 2-3 days. The results (`.rds` files) will be in the `results/` folder.
