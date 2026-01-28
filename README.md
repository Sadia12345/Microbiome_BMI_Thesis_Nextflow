# Microbiome-BMI Prediction Pipeline

**Master's Thesis Project (2025-2026)**
**University of Turku**

**Advisor:** Professor Leo Lahti

## Project Overview
This repository contains the **computational pipeline** developed for a Master's Thesis study investigating **machine learning approaches for predicting BMI from human gut microbiome data**.

It provides a fully reproducible Nextflow workflow to:
1.  **Preprocess** large-scale metagenomic data (Metalog Consortium).
2.  **Train** machine learning models (Random Forest, SVM) to predict BMI.
3.  **Analyze** performance scaling via Saturation Analysis.

...

## Detailed Execution Guide (Technical)

To reproduce the analysis from scratch, follow these engineering steps:

### 1. Environment Initialization
Ensure you have `Nextflow` (v23+) and `Conda` installed. The pipeline handles all dependency resolution automatically via the `environment.yml` file.

### 2. Data Staging
This pipeline requires data from the Metalog Consortium, split into Metadata and Taxonomy.
*   **Files Required:**
    1.  `human_extended_wide.tsv` (Metadata: ID, BMI, Age, etc.)
    2.  `human_metaphlan4_species.tsv` (Taxonomy: Species Abundance)
*   **Action:** Copy both files to the `Data/` directory.

### 3. Data Preparation (Merge)
Before running the pipeline, you must merge the metadata and taxonomy into a single input CSV.
```bash
# This creates 'Data/metalog_subset.csv'
python Nextflow/bin/merge_metalog.py
```

### 3. Pipeline Execution
Run the following command in your terminal. This will trigger the entire workflow (Preprocessing $\rightarrow$ Training $\rightarrow$ Plotting).

```bash
# Basic Run
nextflow run Nextflow/main.nf -profile conda

# To Resume a Failed Run (Cached)
nextflow run Nextflow/main.nf -profile conda -resume

# To Visualize the DAG (Workflow Graph)
nextflow run Nextflow/main.nf -profile conda -with-dag pipeline_dag.html
```

### 4. Output Artifacts
Results are automatically published to the `Nextflow/results/` directory:
*   **Saturation Curve:** `Nextflow/results/saturation/saturation_r2.svg` (The final evaluation plot).
*   **Top Biomarkers:** `Nextflow/results/feature_importance.png`.
*   **Model Objects:** `Nextflow/results/*.rds` (Serialized R models for future prediction).

### 5. Cleaning
To save disk space after analysis:
```bash
nextflow clean -f
```
This repository contains the computational workflow for the Master's Thesis titled **"Predicting BMI from Human Gut Microbiome Composition using Machine Learning"**. The study rigorously benchmarks four machine learning algorithms (Random Forest, Linear SVM, Decision Trees, and XGBoost) on a dataset of 18,000 human gut microbiome samples (Metaphlan4 profiles). The primary objective was to determine the feasibility of microbiome-based BMI prediction and to identify the optimal sample size required for robust model generalization through a comprehensive saturation analysis.

## Key Findings
1.  **Random Forest Performance:** The Random Forest algorithm proved to be the most robust model for this high-dimensional task, achieving an $R^2$ of **0.387** and an RMSE of **5.06**.
2.  **Feasibility & Saturation:** A **Saturation Analysis** (Performance vs. Sample Size) demonstrated that model performance follows a logarithmic growth curve, reaching a plateau at **16,000 samples**. This critical finding suggests that future studies should prioritize large-scale data aggregation (>10k samples) to maximize predictive power.
3.  **Non-Linearity:** The significant performance gap between Random Forest (Non-Linear, $R^2=0.387$) and Linear SVM ($R^2 \approx 0.04$) strongly indicates that the relationship between gut microbiota and host BMI is fundamentally non-linear and driven by complex interactions rather than additive effects.
4.  **Biological Signatures:** Feature importance analysis identified *Enterococcus faecalis*, *Veillonella dispar*, and *Acidaminococcus intestini* as the top microbial predictors of BMI.

## Repository Structure
This repository maintains a **Code-Only** policy to ensure privacy compliance and lightweight distribution. Data files and compiled manuscripts are excluded.

```
.
├── Nextflow/                   # Core Computational Pipeline
│   ├── main.nf                 # Main Nextflow Workflow Orchestrator
│   ├── nextflow.config         # Environment & Resource Configuration
│   ├── bin/                    # Analysis Methodology (R/Python)
│   │   ├── preprocess.R        # Variance Filtering (Top 1000 Features)
│   │   ├── train_ml.R          # ML Training Engine (Caret/XGBoost)
│   │   ├── run_saturation.R    # Saturation Analysis & Subsampling Logic
│   │   └── plot_comparison.R   # Visualization Scripts
│   └── results/                # Generated Artifacts (Plots, CSVs)
│       └── saturation/         # Saturation Analysis Results
│
├── Thesis/                     # Technical Reports
│   ├── thesis.html             # Pipeline Execution Report (Nextflow)
│   └── thesis_technical_summary.html # Detailed Run Summary
│
└── README.md                   # Project Documentation
```

## Computational Methodology
The analysis pipeline is built using **Nextflow** for reproducibility and scalability.
1.  **Univariate Filtering:** To handle high-dimensionality, we apply a variance-based filter, selecting the top 1,000 most variable inter-individual features.
2.  **Cross-Validation:** Models are validated using **3-Fold Cross-Validation** to ensure robust error estimation while maintaining computational feasibility on large datasets (N=18,000).
3.  **Saturation Analysis:** We iteratively train models on subsamples ranging from 2,000 to 16,000 samples (step=2,000) to empirically derive the learning curve and determine data sufficiency.

## Usage
To reproduce the analysis:
1.  **Prerequisites:** Install `nextflow` and `conda`.
2.  **Data Placement:** Place the input matrix (`metaphlan4_species.tsv`) in the `Data/` directory.
3.  **Execution:**
    ```bash
    nextflow run Nextflow/main.nf -profile conda
    ```

## Artifacts & Visualization
- **Saturation Curve (Figure 4):** A visualization of model stability across sample sizes can be found in `Nextflow/results/saturation/saturation_r2.svg` and `saturation_curve_final.png`.
- **Feature Importance:** Top predictive taxa are visualized in `Nextflow/results/feature_importance.png`.
