# Predicting BMI from Human Microbiome (Thesis Project)

## 📌 Overview
This repository contains a scalable **Nextflow** pipeline to predict Body Mass Index (BMI) from human gut microbiome data (Metagenomics). It utilizes the **Metalog** database (17,903 samples) and benchmarks multiple Machine Learning models:
*   **GLMNet** (Linear Baseline)
*   **Random Forest** (Non-Linear Ensemble)
*   **XGBoost** (Gradient Boosting)
*   **SVM** (Support Vector Machine)

## 📂 Repository Structure
*   `Nextflow/`: The core pipeline code.
    *   `main.nf`: The master workflow file.
    *   `bin/`: Helper scripts (R and Python) called by the pipeline.
    *   `results/`: Output folder for model performance (CSVs) and plots.
*   `Thesis/`: The academic manuscript.
    *   `thesis.Rmd`: The RMarkdown source code for the thesis.
    *   `thesis.html`: The compiled, readable thesis document.

## 🚀 How to Run (Local Computer)
### Prerequisites
1.  **Conda**: `miniconda` or `anaconda` installed.
2.  **Nextflow**: `curl -s https://get.nextflow.io | bash`

### Quick Start
```bash
# 1. Clone the repo
git clone https://github.com/tahmid-toki/mikropml_project.git
cd mikropml_project

# 2. Setup Environment
conda env create -f environment.yml  # (Create this file if needed, usually mikropml_env)

# 3. Run Pipeline
cd Nextflow
nextflow run main.nf
```

## ⚡ How to Run on Supercomputer (CSC / Slurm)
This pipeline is designed to be **HPC-Ready**. You do **not** need to change the code (scripts). You only need to verify the configuration.

### 1. The Power of Nextflow
Nextflow separates the *logic* (the scripts in `bin/`) from the *execution* (where it runs). On your laptop, it runs locally. On a supercomputer, it submits jobs to the queue automatically.

### 2. Instructions for CSC (Puhti/Mahti)
1.  **Login** to the supercomputer.
2.  **Clone** this repository there.
3.  **Run** using the `slurm` executor profile (create a `nextflow.config` file if specific settings are needed):

```bash
# Example command for CSC
module load nextflow
nextflow run main.nf -profile csc --executor slurm
```

### 3. What Happens?
*   Nextflow will see the 4 models (GLM, RF, XGB, SVM).
*   It will submit **4 separate jobs** to the Slurm queue.
*   The supercomputer will run them in parallel (saving days of work).
*   Results will appear in `results/` just like on your laptop.

## 📊 Results & Artifacts
*   **Performance:** Check `results/model_comparison.png`.
*   **Models:** Trained model objects are saved as `.rds` files for feature extraction.
