#!/usr/bin/env python3
"""
Study-population / BMI-target characterisation.

Describes the BMI distribution of the modelled cohort and investigates whether the
extreme low/high BMI values are data-entry errors or genuine cohort variation.

Outputs:
  figures/bmi_population.png      BMI histogram with clinical reference lines
  figures/bmi_vs_age.png          BMI versus age scatter (shows infants drive low tail)
  tables/bmi_extremes_profile.csv breakdown of the low/high extreme records

Data (not redistributed; download from https://metalog.embl.de/downloads):
  metalog_subset.csv                 modelled samples (sample_id, bmi, species...)
  human_extended_wide_2025-12-14.tsv harmonised metadata (gzip), keyed by sample_alias

Set the data directory with the METALOG_DATA environment variable, e.g.
  METALOG_DATA=/path/to/metalog python bmi_population.py
(defaults to ./data).
"""
import os
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

DATA = os.environ.get("METALOG_DATA", "data")
FIG, TAB = "figures", "tables"
os.makedirs(FIG, exist_ok=True)
os.makedirs(TAB, exist_ok=True)
NAVY = "#1f3a93"

# --- Modelled samples ---
model = pd.read_csv(os.path.join(DATA, "metalog_subset.csv"), usecols=["sample_id", "bmi"])
model["sample_id"] = model["sample_id"].astype(str)
print(f"Modelled samples: {len(model)}  "
      f"BMI {model.bmi.min():.1f}-{model.bmi.max():.1f}  "
      f"mean {model.bmi.mean():.2f}  SD {model.bmi.std():.2f}  median {model.bmi.median():.1f}")

# --- Metadata ---
meta_cols = ["sample_alias", "study_code", "age_years", "age_category",
             "geographic_location", "subject_disease_status", "sex",
             "weight_kg", "height_cm"]
meta = pd.read_csv(os.path.join(DATA, "human_extended_wide_2025-12-14.tsv"),
                   sep="\t", compression="gzip",
                   usecols=lambda c: c in meta_cols, low_memory=False)
meta["sample_alias"] = meta["sample_alias"].astype(str)

df = model.merge(meta, left_on="sample_id", right_on="sample_alias", how="left")
df["age_years"] = pd.to_numeric(df["age_years"], errors="coerce")
df["weight_kg"] = pd.to_numeric(df["weight_kg"], errors="coerce")
df["height_cm"] = pd.to_numeric(df["height_cm"], errors="coerce")

# --- Recompute BMI from weight/height as an internal-consistency check ---
mask = df.weight_kg.notna() & df.height_cm.notna() & (df.height_cm > 0)
df.loc[mask, "bmi_recomputed"] = df.loc[mask, "weight_kg"] / (df.loc[mask, "height_cm"] / 100) ** 2
chk = df[mask & df.bmi.notna()]
absdiff = (chk.bmi - chk.bmi_recomputed).abs()
print(f"\nBMI recompute check (n={len(chk)}): "
      f"median |diff| {absdiff.median():.3f}, "
      f"Pearson r {chk.bmi.corr(chk.bmi_recomputed):.3f}, "
      f"{(absdiff <= 1).mean():.1%} within 1 BMI unit")

# --- Profile the extreme tails ---
low = df[df.bmi < 15]
high = df[df.bmi > 50]
la = low[low.age_years.notna()]
print(f"\nLow tail (BMI<15): n={len(low)}; "
      f"{(la.age_years < 18).mean():.0%} aged <18, {(la.age_years < 5).mean():.0%} aged <5")
print("  top studies:\n   ", low.study_code.value_counts().head(3).to_dict())
print(f"High tail (BMI>50): n={len(high)}; median age {high.age_years.median():.0f}")
print("  top studies:\n   ", high.study_code.value_counts().head(3).to_dict())

keep = [c for c in ["sample_id", "bmi", "bmi_recomputed", "age_years", "age_category",
                    "sex", "weight_kg", "height_cm", "subject_disease_status",
                    "study_code", "geographic_location"] if c in df.columns]
pd.concat([low, high]).sort_values("bmi")[keep].to_csv(
    os.path.join(TAB, "bmi_extremes_profile.csv"), index=False)

# --- Figure: BMI histogram ---
fig, ax = plt.subplots(figsize=(8, 5))
ax.hist(df.bmi, bins=120, color=NAVY, alpha=0.85, edgecolor="white", linewidth=0.2)
for x, lab in [(15, "BMI 15"), (18.5, "18.5"), (25, "25"), (30, "30"), (50, "BMI 50")]:
    ax.axvline(x, color="#c0392b", ls="--", lw=0.8)
    ax.text(x, ax.get_ylim()[1] * 0.92, lab, rotation=90, va="top", ha="right",
            fontsize=7, color="#c0392b")
ax.set_xlabel("BMI (kg/m$^2$)")
ax.set_ylabel("Number of samples")
ax.set_title(f"BMI distribution of modelled samples (n={len(df):,})")
plt.tight_layout()
plt.savefig(os.path.join(FIG, "bmi_population.png"), dpi=160)
plt.close()

# --- Figure: BMI vs age ---
sub = df[df.age_years.notna()]
fig, ax = plt.subplots(figsize=(8, 5))
ax.scatter(sub.age_years, sub.bmi, s=4, alpha=0.25, color=NAVY)
ax.axhline(15, color="#c0392b", ls="--", lw=0.8)
ax.axhline(50, color="#c0392b", ls="--", lw=0.8)
ax.set_xlabel("Age (years)")
ax.set_ylabel("BMI (kg/m$^2$)")
ax.set_title(f"BMI vs age (n={len(sub):,} with recorded age)")
plt.tight_layout()
plt.savefig(os.path.join(FIG, "bmi_vs_age.png"), dpi=160)
plt.close()
print("\nWrote figures/ and tables/.")
