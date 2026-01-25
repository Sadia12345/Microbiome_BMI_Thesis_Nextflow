# Microbiome-Based BMI Prediction Thesis

This repository contains the complete computational workflow for the Master's Thesis: **"Predicting BMI from Human Gut Microbiome Composition using Machine Learning"**.

## Project Overview
This repository contains the complete computational workflow and thesis manuscript for analyzing human gut microbiome data to predict **BMI (Body Mass Index)** and **Physical Activity Levels**.

The core objective is to identify robust microbial biomarkers using interpretable machine learning models while ensuring methodological rigor (prevention of data leakage) and computational reproducibility.

---

## Repository Structure
This project is organized into two main components: the computational analysis (Nextflow) and the scientific manuscript (LaTeX).

```
Thesis_Project/
├── Nextflow/                  # AUTOMATED ANALYSIS PIPELINE
│   ├── main.nf                # Master workflow script
│   ├── nextflow.config        # Resource configuration (Sequential for 8GB RAM)
│   ├── bin/                   # R/Python scripts
│   │   ├── preprocess.R       # Data cleaning & Variance filtering
│   │   ├── train_ml.R         # ML Training (RF, XGBoost, SVM)
│   │   └── plot_comparison.R  # Visualization (SVG)
│   └── results/               # Output plots and model files
│

├── Data/
│   └── metalog_subset.csv     # Input Microbiome dataset
│
└── thesis_final.pdf           # Final compiled thesis document
```

---

## Methodology & Data Strategy

### 1. Data Selection & Preprocessing
To handle high-dimensional microbiome data (~10,000 species) on standard hardware, we implement a two-step filtering strategy:
*   **Prevalence Filtering:** Taxa present in <1% of samples are removed to eliminate noise.
*   **Variance Filtering (Top 1000):** We select the **Top 1000 features** with the highest variance. This is a standard bioinformatics approach to retain features that carry the most information while reducing dimensionality.

### 2. Leakage Prevention
**Data leakage** (using testing data during training) is a critical risk in ML. We prevent this by:
*   **Separation:** Preprocessing (Scaling/Centering) is calculated *within* the workflow.
*   **Cross-Validation:** We use **5-Fold Cross-Validation** (k=5). The model is trained on 80% of the data and validated on a distinct 20% in each iteration. Hyperparameter tuning happens strictly within the training folds.

### 3. Machine Learning Models
We benchmarked three distinct algorithms to evaluate performance trade-offs:
*   **Random Forest (rf)**: Ensemble of decision trees. Robust to overfitting and handles non-linear interactions well.
*   **XGBoost (xgbTree)**: Gradient boosting framework. Highly efficient and often achieves state-of-the-art accuracy.
*   **Linear SVM (svmLinear)**: Support Vector Machine with a linear kernel. chosen for its memory efficiency (O(n)) compared to Radial kernels (O(n^2)) for this feature size.

---

## Technical Stack

*   **Workflow Engine:** [Nextflow](https://www.nextflow.io) (DSL2)
*   **Language:** R (v4.x)
*   **Libraries:** `mikropml` (pipeline), `caret` (training), `data.table` (fast I/O), `svglite` (vector graphics).
*   **Version Control:** Git & GitHub.

---

## How to Run (Usage)

### System Requirements
*   **OS:** macOS (Apple Silicon M2/M3) or Linux.
*   **RAM:** Minimum 8GB (Pipeline is optimized for sequential execution).
*   **Dependencies:** Nextflow, R, Conda.

### Execution
1.  Navigate to the workflow directory:
    ```bash
    cd Nextflow
    ```
2.  Run the pipeline:
    ```bash
    nextflow run main.nf
    ```
3.  **Outputs:**
    *   `results/model_comparison.svg`: Final publication-ready plot.
    *   `results/*.rds`: Trained model objects.

---


