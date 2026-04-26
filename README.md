# Microbiome-Based Body Mass Index Prediction: Nextflow Workflow

This repository contains the code-only Nextflow workflow used in the master's thesis **"Microbiome-Based Body Mass Index Prediction: A Scalable Machine Learning Benchmark for Large-Scale Metagenomic Data"** (University of Turku, ICT / Data Analytics).

**Author:** Sadia Zaman  
**Supervisors:** Professor Leo Lahti; Geraldson Muluh

The repository documents a reproducible, local-hardware-oriented benchmarking workflow for microbiome-only BMI prediction from large-scale human gut metagenomic taxonomic profiles. It focuses on preprocessing, sample-size scaling, model comparison, and feature-ranking outputs under the implementation constraints described in the thesis.

## Scope of the Repository

The workflow supports:
- merging Metalog-derived metadata and MetaPhlAn 4 species profiles into a working matrix
- prevalence filtering and variance-based feature reduction
- microbiome-only BMI regression benchmarking across increasing sample sizes
- generation of model-comparison, saturation, scalability, and feature-ranking figures
- exploratory scripts for additional model families and interpretation routines

This repository is a **code-only** release. Large Metalog-derived input tables, private local run artifacts, and the thesis manuscript itself are not redistributed here.

## Study Context

In the thesis benchmark, the Nextflow workflow was used to evaluate whether species-level gut microbiome composition alone contains enough information to support population-scale BMI prediction under realistic local-computing constraints. The workflow emphasized:
- transparent preprocessing order
- scalable execution on consumer-grade hardware
- comparison of linear and non-linear model behavior
- empirical learning-curve analysis across sample sizes

The benchmark should be read as a workflow-based predictive study, not as a claim of causal inference or a clinically deployable BMI model.

## Main Benchmark Characteristics

The interpreted Nextflow benchmark in the thesis used:
- an 80/20 train-test split inside `mikropml::run_ml()`
- 3-fold cross-validation with one cross-validation repeat
- one random subset draw at each sample-size step from 2,000 to 16,000 samples
- a microbiome-only predictor set with non-microbial metadata excluded from model fitting
- a 1% prevalence filter followed, when needed, by a variance-based top-500 feature filter

Random Forest was the strongest retained model in the main Nextflow benchmark, outperforming the retained linear baselines under the implemented settings. The learning-curve analysis suggested diminishing predictive gains after roughly 12,000 samples, rather than indefinite improvement with larger taxonomic input alone.

These findings are specific to the implemented workflow, the Metalog-derived analysis matrix, and the species-level relative-abundance representation used in the thesis.

## XGBoost Status

The repository contains exploratory XGBoost scripts because boosting was investigated during development. However, XGBoost was not retained as a stable interpreted result in the final thesis benchmark from this workflow. Platform-specific compatibility and stability issues on the Apple Silicon environment prevented a consistent retained benchmark output for the final write-up.

## Repository Layout

```text
.
|-- Nextflow/
|   |-- main.nf
|   |-- nextflow.config
|   |-- bin/
|   |   |-- merge_metalog.py
|   |   |-- preprocess.R
|   |   |-- train_ml.R
|   |   |-- run_saturation.R
|   |   |-- plot_comparison.R
|   |   |-- extract_features*.R
|   |   |-- run_shap.R
|   |   |-- run_xgboost_light.R
|   |   `-- run_xgboost_native.R
|   `-- results/
|       |-- feature_importance.png
|       |-- model_comparison.png
|       `-- saturation/
|           |-- saturation_r2.png
|           `-- scaling_time.png
|-- README.md
`-- inspect_log*.txt
```

## Input Data

The workflow expects two Metalog-derived inputs before matrix construction:
- `human_extended_wide.tsv` for metadata
- `human_metaphlan4_species.tsv` for species-level taxonomic abundances

These are merged by sample identifier using the repository's preprocessing utilities. Access to the underlying data remains subject to the relevant dataset-governance constraints.

## Technical Execution Guide

### 1. Environment Setup

Ensure that Nextflow and Conda are available in your environment.

### 2. Data Placement

Place the required input tables in the local data location used by the workflow.

### 3. Matrix Construction

Before the main run, merge metadata and species profiles into a working matrix:

```bash
python Nextflow/bin/merge_metalog.py
```

### 4. Pipeline Execution

Basic run:

```bash
nextflow run Nextflow/main.nf -profile conda
```

Resume a cached run:

```bash
nextflow run Nextflow/main.nf -profile conda -resume
```

Optional DAG output:

```bash
nextflow run Nextflow/main.nf -profile conda -with-dag pipeline_dag.html
```

## Output Artifacts

The workflow produces benchmark artifacts under `Nextflow/results/`, including:
- model-comparison plots
- saturation and scaling plots
- feature-ranking outputs
- intermediate results used for the interpreted workflow summaries

## Reproducibility Note

The thesis cites this public repository as a reproducibility resource rather than as a full data release. This identifies the exact public code state associated with the thesis documentation.

## Interpretation Boundaries

The outputs generated by this repository should be interpreted cautiously:
- stronger predictive performance by a non-linear model is consistent with non-linear or interaction-rich structure, but does not prove a specific ecological mechanism
- feature-ranking outputs are descriptive and do not establish causality
- internal benchmark performance does not by itself establish external transportability to independent cohorts

For the full methodological interpretation, limitations, and discussion of workflow trade-offs, use the thesis text together with this repository.
