#!/usr/bin/env python3
"""
Descriptive box-plots of BMI by age category and by cohort.

Shows that the extreme BMI values are age- and cohort-driven rather than random
data-entry error: the low tail is babies/children, the high tail is adults, and the
extremes cluster within specific contributing studies.

Outputs:
  figures/bmi_by_agecategory.png  BMI per age category (baby/child/adolescent/adult)
  figures/bmi_by_cohort.png       BMI for the 14 largest studies, ordered by median

Set the data directory with METALOG_DATA (defaults to ./data).
Requires matplotlib >= 3.9.
"""
import os
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

meta = pd.read_csv(os.path.join(DATA, "human_extended_wide_2025-12-14.tsv"),
                   sep="\t", compression="gzip",
                   usecols=lambda c: c in ["sample_alias", "age_category", "study_code"],
                   low_memory=False)
meta["sample_alias"] = meta["sample_alias"].astype(str)
df = m.merge(meta, left_on="sample_id", right_on="sample_alias", how="left")


def boxplot(ax, data, labels, **kw):
    """Compatibility wrapper: matplotlib renamed 'labels' to 'tick_labels' in 3.9."""
    try:
        return ax.boxplot(data, tick_labels=labels, **kw)
    except TypeError:
        return ax.boxplot(data, labels=labels, **kw)


# --- BMI by age category ---
order = ["baby", "child", "adolescent", "adult"]
data = [df[df.age_category == c].bmi.dropna().values for c in order]
counts = [len(d) for d in data]
fig, ax = plt.subplots(figsize=(8, 5))
bp = boxplot(ax, data, [f"{c}\n(n={n:,})" for c, n in zip(order, counts)],
             patch_artist=True, widths=0.6,
             flierprops=dict(marker='o', ms=3, mfc=NAVY, alpha=0.25, mec='none'),
             medianprops=dict(color=NAVY, lw=2))
for b in bp['boxes']:
    b.set(facecolor="#dce3f7", edgecolor=NAVY)
ax.axhline(15, color="#c0392b", ls="--", lw=0.9)
ax.axhline(50, color="#c0392b", ls="--", lw=0.9)
ax.text(0.6, 15.5, "BMI 15", color="#c0392b", fontsize=8, va="bottom")
ax.text(0.6, 50.8, "BMI 50", color="#c0392b", fontsize=8, va="bottom")
ax.set_ylabel("BMI (kg/m$^2$)")
ax.set_xlabel("Age category")
ax.set_title("BMI distribution by age category — the low tail is infants")
plt.tight_layout()
plt.savefig(os.path.join(FIG, "bmi_by_agecategory.png"), dpi=160)
plt.close()
print("saved bmi_by_agecategory.png  counts:", dict(zip(order, counts)))

# --- BMI by cohort (14 largest studies) ---
top = df.study_code.value_counts().head(14).index.tolist()
sub = df[df.study_code.isin(top)]
ordr = sub.groupby("study_code").bmi.median().sort_values().index.tolist()
data = [sub[sub.study_code == s].bmi.dropna().values for s in ordr]
counts = [len(d) for d in data]
fig, ax = plt.subplots(figsize=(9, 6.5))
bp = boxplot(ax, data, [f"{s}  (n={n:,})" for s, n in zip(ordr, counts)],
             vert=False, patch_artist=True, widths=0.6,
             flierprops=dict(marker='o', ms=2.5, mfc=NAVY, alpha=0.2, mec='none'),
             medianprops=dict(color="#c0392b", lw=2))
for b in bp['boxes']:
    b.set(facecolor="#dce3f7", edgecolor=NAVY)
for xv in (18.5, 25, 30):
    ax.axvline(xv, color="#888", ls=":", lw=0.8)
ax.set_xlabel("BMI (kg/m$^2$)")
ax.set_title("BMI by cohort (14 largest studies) — extremes cluster by cohort")
plt.tight_layout()
plt.savefig(os.path.join(FIG, "bmi_by_cohort.png"), dpi=160)
plt.close()
print("saved bmi_by_cohort.png")
