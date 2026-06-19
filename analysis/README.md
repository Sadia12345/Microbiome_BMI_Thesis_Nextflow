# Revision analysis scripts

Descriptive analyses and figures for the BMI-target characterisation and the
bacteria–BMI association, supporting the thesis *Microbiome-Based Body Mass Index
Prediction: A Scalable Machine Learning Benchmark for Large-Scale Metagenomic Data*.

## Scripts

| Script | Produces |
|---|---|
| `bmi_population.py` | BMI histogram, BMI-vs-age scatter, and the weight/height recompute check; extreme-records table |
| `adult_subset_sensitivity.py` | adult-only (age ≥ 18) BMI distribution and species–BMI correlations |
| `bmi_by_cohort_and_agecategory.py` | box-plots of BMI by age category and by cohort |
| `bacteria_bmi_scatter.py` | abundance-vs-BMI scatter and per-species Spearman/Pearson correlations |
| `dataset_composition_and_plausibility.py` | weight-vs-height plausibility plot and samples-by-country composition |
| `make_pipeline_diagram.py` | the Nextflow pipeline diagram (no data needed) |
| `extract_rf_predictions.R` | extracts the real cross-validated predictions from the saved `rf_model.rds` (writes `rf_cv_predictions.csv`) |
| `plot_prediction_error.py` | plots the Random Forest prediction-error distribution from `rf_cv_predictions.csv` |

## Requirements

```
python >= 3.9
pandas
numpy
scipy
matplotlib
```

```
pip install pandas numpy scipy matplotlib
```

## Data

The scripts read two Metalog tables, which are **not** redistributed here because of
their size and data-governance terms. They are publicly downloadable from
<https://metalog.embl.de/downloads>:

- `metalog_subset.csv` — the modelled samples (`sample_id`, `bmi`, species columns)
- `human_extended_wide_2025-12-14.tsv` — harmonised metadata (gzip-compressed), keyed
  by `sample_alias`

Point the scripts at the directory containing those files with the `METALOG_DATA`
environment variable (it defaults to `./data`):

```
METALOG_DATA=/path/to/metalog python bmi_population.py
```

Figures are written to `figures/` and tables to `tables/`. Running the scripts on the
same Metalog tables reproduces the figures and the reported correlation values exactly.

## Prediction-error figure (optional)

`extract_rf_predictions.R` and `plot_prediction_error.py` regenerate the prediction-error
distribution from the trained model. They require **R** (with the saved `rf_model.rds`)
and Python, respectively. The model file is large and not redistributed here; point the
R script at it with the `RF_MODEL` environment variable:

```
RF_MODEL=path/to/rf_model.rds Rscript extract_rf_predictions.R
python plot_prediction_error.py        # reads rf_cv_predictions.csv -> figures/prediction_error.png
```
