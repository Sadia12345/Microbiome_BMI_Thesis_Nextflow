# Microbiome BMI Prediction: A Nextflow & R Pipeline

## 📌 Overview
This repository contains a scalable **Nextflow** pipeline to predict Body Mass Index (BMI) from human gut microbiome data (Metagenomics). It utilizes the **Metalog** database (17,903 samples) and benchmarks multiple Machine Learning models:
*   **GLMNet** (Linear Baseline)
*   **Random Forest** (Non-Linear Ensemble)
*   **XGBoost** (Gradient Boosting)
*   **SVM** (Support Vector Machine)

---

## 🔬 Methodology & Experimental Design

### 1. Data Source & Preparation
*   **Source:** The analysis integrates metadata from the **Metalog Project** (`human_extended_wide.tsv`) with taxonomic profiles from **Metaphlan4** (`human_metaphlan4_species.tsv`).
*   **Sample Size:** The merged dataset contains **17,903 unique human samples**, representing a diverse global population.
*   **Target Variable:** `BMI` (Continuous).

### 2. Preprocessing Strategy (`mikropml`)
We employ the `mikropml` package (Schloss Lab), the gold standard for microbiome machine learning, to ensure robust and reproducible preprocessing:
*   **1% Prevalence Filter:** Bacterial species present in <1% of samples are removed. This reduced features from **10,701 → 1,799** (83% reduction), dramatically improving computational efficiency.
*   **Zero-Variance Removal:** Near-Zero Variance features are removed to reduce noise.
*   **Normalization:** Feature abundances are scaled and centered (Mean=0, SD=1) to ensure algorithm stability.
*   **Cross-Validation:** A strict **k-fold cross-validation** scheme is used to evaluate model generalizability.

### 3. Data Leakage Prevention (Critical)
To ensure the model learns *biological* signals rather than mathematical tautologies, we implemented strict leakage prevention:
*   **Weight Exclusion:** The `Weight` variable is explicitly removed. Since $BMI = Weight / Height^2$, including weight would constitute "Data Leakage" (giving the model the answer).
*   **Rigorous Separation:** Preprocessing parameters (scaling factors) are learned *only* on the training fold and applied to the test fold, preventing information from leaking between splits.

### 4. Study Design: The "Age & Sex" Exclusion
A key design decision in this study was to **exclude Age and Sex** from the feature set.
*   **Rationale:** Age and Sex are known strong confounders for BMI.
*   **Goal:** By training on *taxonomic features only*, we force the model to derive predictions solely from the **microbial composition**.
*   **Result:** This establishes a **Microbiome-Only Baseline**, proving that the gut ecosystem *itself* contains predictive information about host phenotype, independent of demographic proxies. This strengthens the biological validity of the findings.

---

## 📂 Repository Structure
*   `Nextflow/`: The core pipeline code.
    *   `main.nf`: The master workflow file.
    *   `bin/`: Helper scripts (R and Python) called by the pipeline.
    *   `results/`: Output folder for model performance (CSVs) and plots.
*   `Thesis/`: The academic manuscript.
    *   `thesis.Rmd`: The RMarkdown source code for the thesis.
    *   `thesis.html`: The compiled, readable thesis document.

---

## 🚀 How to Run (Local Computer)
### Prerequisites
1.  **Conda**: `miniconda` or `anaconda` installed.
2.  **Nextflow**: `curl -s https://get.nextflow.io | bash`

### Quick Start
```bash
# 1. Clone the repo
git clone https://github.com/Sadia12345/Microbiome_BMI_Thesis.git
cd Microbiome_BMI_Thesis

# 2. Setup Environment
conda env create -f environment.yml

# 3. Run Pipeline
cd Nextflow
nextflow run main.nf
```

---

## ⚡ How to Run on Supercomputer (CSC / Slurm)
This pipeline is designed to be **HPC-Ready**. You do **not** need to change the code (scripts).

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

---

## 📊 Results Summary (Latest)

| Model | R-Squared ($R^2$) | RMSE | Interpretation |
| :--- | :--- | :--- | :--- |
| **GLMNet (Lasso)** | `0.14` | `5.80` | Linear Baseline. Weak correlation. |
| **Random Forest** | **`0.325`** | **`5.15`** | **Non-Linear Victory.** Massive improvement. |

### 🧬 Key Findings
*   The microbiome has a **complex, non-linear relationship** with BMI.
*   Random Forest drastically outperformed the linear model, capturing interactions between species.
*   **Top Predictive Species:** *Adlercreutzia equolifaciens*, *Eisenbergiella tayi*, *Roseburia lenta*.

### 📈 Saturation Analysis (Learning Curve)
To address scalability limitations, we implemented a **Saturation Analysis**:
*   **Goal:** Determine if prediction performance plateaus before using the full dataset.
*   **Method:** Train RF on 1k, 5k, 10k, 15k, and 17k samples; plot $R^2$ vs. sample size.
*   **Script:** `bin/run_saturation.R`
*   **Output:** `saturation_r2.png`, `scaling_time.png`

---

## 📊 Detailed Artifacts
*   **Performance:** Check `results/model_comparison.png`.
*   **Models:** Trained model objects are saved as `.rds` files for feature extraction.
