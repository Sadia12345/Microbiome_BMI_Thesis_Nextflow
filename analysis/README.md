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
