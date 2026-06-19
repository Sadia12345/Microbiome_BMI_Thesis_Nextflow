#!/usr/bin/env python3
"""
Adult-only sensitivity analysis (age >= 18).

Recomputes the BMI distribution and the species-BMI Spearman correlations on an
adult-only subset, to test whether the extreme low tail (infants) and the named
species-BMI associations are driven by the age structure of the pooled cohort.

Prints a full-vs-adults comparison; no figures are written.

Set the data directory with METALOG_DATA (defaults to ./data).
"""
import os
import pandas as pd
import numpy as np
from scipy import stats

DATA = os.environ.get("METALOG_DATA", "data")
CSV = os.path.join(DATA, "metalog_subset.csv")

TAXA = ["s__GGB9512_SGB14909", "s__Enterococcus_faecalis", "s__Cutibacterium_acnes",
        "s__Rothia_mucilaginosa", "s__Veillonella_dispar", "s__Escherichia_coli",
        "s__Bifidobacterium_longum", "s__Ruminococcus_gnavus"]

header = pd.read_csv(CSV, nrows=0).columns.tolist()
present = [t for t in TAXA if t in header]
df = pd.read_csv(CSV, usecols=["sample_id", "bmi"] + present)
df["sample_id"] = df["sample_id"].astype(str)

meta = pd.read_csv(os.path.join(DATA, "human_extended_wide_2025-12-14.tsv"),
                   sep="\t", compression="gzip",
                   usecols=lambda c: c in ["sample_alias", "age_years"], low_memory=False)
meta["sample_alias"] = meta["sample_alias"].astype(str)
meta["age_years"] = pd.to_numeric(meta["age_years"], errors="coerce")
df = df.merge(meta, left_on="sample_id", right_on="sample_alias", how="left")

adults = df[df.age_years >= 18]
print(f"Full: {len(df)}  Adults (age>=18): {len(adults)} "
      f"({len(adults) / len(df):.0%})  dropped: {len(df) - len(adults)}")
print(f"BMI median   full {df.bmi.median():.1f}   adults {adults.bmi.median():.1f}")
print(f"BMI<15 count full {int((df.bmi < 15).sum())}   adults {int((adults.bmi < 15).sum())}")
print(f"BMI>50 count full {int((df.bmi > 50).sum())}   adults {int((adults.bmi > 50).sum())}")

print("\nSpearman rho (full vs adults-only):")
print(f"{'taxon':30s} {'full':>8s} {'adults':>8s}")
for t in present:
    r_full = stats.spearmanr(df.bmi, df[t]).statistic
    r_ad = stats.spearmanr(adults.bmi, adults[t]).statistic
    print(f"{t.replace('s__', ''):30s} {r_full:+8.3f} {r_ad:+8.3f}")
