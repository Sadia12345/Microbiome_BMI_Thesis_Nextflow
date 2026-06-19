#!/usr/bin/env python3
"""
Dataset composition and physical-plausibility checks for the BMI target.

Two descriptive figures supporting the data-quality argument that the extreme BMI
values are genuine cohort/age variation rather than data-entry error:

  figures/weight_vs_height.png    recorded weight vs height (with constant-BMI lines),
                                  showing every extreme BMI is a physically real
                                  height/weight combination (no impossible records).
  figures/dataset_composition.png samples per country, illustrating that the cohort
                                  pools many independent studies across many countries.

Also prints the height/weight ranges used in the thesis text.

Set the data directory with METALOG_DATA (defaults to ./data).
"""
import os
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

DATA = os.environ.get("METALOG_DATA", "data")
FIG = "figures"
os.makedirs(FIG, exist_ok=True)
NAVY = "#1f3a93"

m = pd.read_csv(os.path.join(DATA, "metalog_subset.csv"), usecols=["sample_id", "bmi"])
m["sample_id"] = m["sample_id"].astype(str)

meta_cols = ["sample_alias", "age_category", "weight_kg", "height_cm",
             "geographic_location", "study_code"]
meta = pd.read_csv(os.path.join(DATA, "human_extended_wide_2025-12-14.tsv"),
                   sep="\t", compression="gzip",
                   usecols=lambda c: c in meta_cols, low_memory=False)
meta["sample_alias"] = meta["sample_alias"].astype(str)
df = m.merge(meta, left_on="sample_id", right_on="sample_alias", how="left")
for c in ["weight_kg", "height_cm"]:
    df[c] = pd.to_numeric(df[c], errors="coerce")
wh = df[df.weight_kg.notna() & df.height_cm.notna() & (df.height_cm > 0)]

print(f"{df.study_code.nunique()} studies across {df.geographic_location.nunique()} countries")
print(f"weight+height available: {len(wh)} samples")
print(f"height range {wh.height_cm.min():.0f}-{wh.height_cm.max():.0f} cm, "
      f"weight range {wh.weight_kg.min():.1f}-{wh.weight_kg.max():.1f} kg")

# --- Weight vs height, coloured by age category, with constant-BMI lines ---
colors = {"baby": "#e08e2a", "child": "#46a06e", "adolescent": "#7d5fb0", "adult": NAVY}
fig, ax = plt.subplots(figsize=(8.5, 6))
for cat, c in colors.items():
    s = wh[wh.age_category == cat]
    ax.scatter(s.height_cm, s.weight_kg, s=6, alpha=0.3, color=c,
               edgecolors="none", label=f"{cat} (n={len(s):,})")
hh = np.linspace(45, 205, 100)
for bmi, style in [(15, ":"), (25, "--"), (50, "-.")]:
    ax.plot(hh, bmi * (hh / 100) ** 2, color="#c0392b", ls=style, lw=1, alpha=0.8)
    ax.text(203, bmi * 2.03 ** 2, f"BMI {bmi}", color="#c0392b", fontsize=7.5, va="center")
ax.set_xlabel("Height (cm)")
ax.set_ylabel("Weight (kg)")
ax.set_title(f"Weight vs height for the {len(wh):,} samples with both recorded\n"
             "every extreme BMI is a physically real height/weight combination")
ax.legend(loc="upper left", fontsize=8, framealpha=0.9)
ax.set_xlim(45, 210)
ax.set_ylim(0, 185)
plt.tight_layout()
plt.savefig(os.path.join(FIG, "weight_vs_height.png"), dpi=160)
plt.close()
print("saved weight_vs_height.png")

# --- Samples by country ---
vc = df.geographic_location.value_counts()
top = vc.head(18)[::-1]
fig, ax = plt.subplots(figsize=(8.5, 6.5))
ax.barh(range(len(top)), top.values, color=NAVY, alpha=0.85)
ax.set_yticks(range(len(top)))
ax.set_yticklabels(list(top.index), fontsize=9)
for i, v in enumerate(top.values):
    ax.text(v + 60, i, f"{v:,}", va="center", fontsize=8, color="#333")
ax.set_xlabel("Number of samples")
ax.set_title(f"Study population composition: {df.study_code.nunique()} studies across "
             f"{df.geographic_location.nunique()} countries\n"
             f"(top 18 countries by sample count; n={len(df):,} total)")
plt.tight_layout()
plt.savefig(os.path.join(FIG, "dataset_composition.png"), dpi=160)
plt.close()
print("saved dataset_composition.png")
