#!/usr/bin/env python3
"""
Direction of association: bacterial relative abundance versus BMI.

Plots abundance (y) against BMI (x) for the eight highest-ranked predictive species
and reports the Spearman correlation per taxon, so the direction (positive/negative)
of each association is explicit. Spearman is used because the abundance distributions
are sparse and zero-inflated. Associations are weak and distributed: no single species
drives BMI, which is consistent with tree-based models outperforming linear ones.

The eight species are the top seven by Random Forest IncNodePurity plus Ruminococcus
gnavus (Bifidobacterium longum is included as a commonly studied gut commensal).

Outputs:
  figures/bacteria_bmi_scatter.png    multi-panel abundance-vs-BMI scatter
  tables/bacteria_bmi_correlations.csv Spearman/Pearson per taxon

Set the data directory with METALOG_DATA (defaults to ./data).
"""
import os
import numpy as np
import pandas as pd
from scipy import stats
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

DATA = os.environ.get("METALOG_DATA", "data")
CSV = os.path.join(DATA, "metalog_subset.csv")
FIG, TAB = "figures", "tables"
os.makedirs(FIG, exist_ok=True)
os.makedirs(TAB, exist_ok=True)
NAVY = "#1f3a93"

TAXA = [
    "s__GGB9512_SGB14909",        # rank 1 (uncharacterised SGB)
    "s__Enterococcus_faecalis",   # rank 2
    "s__Cutibacterium_acnes",     # rank 3
    "s__Rothia_mucilaginosa",     # rank 4
    "s__Veillonella_dispar",      # rank 5
    "s__Escherichia_coli",        # rank 6
    "s__Bifidobacterium_longum",  # rank 7
    "s__Ruminococcus_gnavus",     # rank 12
]

header = pd.read_csv(CSV, nrows=0).columns.tolist()
present = [t for t in TAXA if t in header]
df = pd.read_csv(CSV, usecols=["bmi"] + present)
print(f"Loaded {len(df)} samples, {len(present)} taxa")

rows = []
for t in present:
    x, y = df["bmi"].values, df[t].values
    rho, p = stats.spearmanr(x, y)
    pearson = stats.pearsonr(x, y).statistic
    rows.append(dict(taxon=t.replace("s__", ""), spearman_rho=rho, spearman_p=p,
                     pearson_r=pearson, pct_present=(y > 0).mean() * 100))
summary = pd.DataFrame(rows).sort_values("spearman_rho")
summary.to_csv(os.path.join(TAB, "bacteria_bmi_correlations.csv"), index=False)
print(summary.to_string(index=False))

n = len(present)
nrow = int(np.ceil(n / 2))
fig, axes = plt.subplots(nrow, 2, figsize=(11, 3.2 * nrow))
axes = np.array(axes).reshape(-1)
for ax, t in zip(axes, present):
    x, y = df["bmi"].values, df[t].values
    ax.scatter(x, y, s=5, alpha=0.18, color=NAVY, edgecolors="none")
    m, b = np.polyfit(x, y, 1)
    xs = np.linspace(x.min(), x.max(), 50)
    ax.plot(xs, m * xs + b, color="#c0392b", lw=1.6)
    rho, p = stats.spearmanr(x, y)
    direction = "positive" if rho > 0 else "negative"
    ax.set_title(f"{t.replace('s__', '')}\nSpearman "
                 rf"$\rho$={rho:+.3f} ({direction}), p={p:.1e}", fontsize=9)
    ax.set_xlabel("BMI (kg/m$^2$)", fontsize=8)
    ax.set_ylabel("Relative abundance (%)", fontsize=8)
    ax.tick_params(labelsize=7)
for ax in axes[n:]:
    ax.set_visible(False)
fig.suptitle("Top predictive species: relative abundance vs BMI", fontsize=12, y=1.0)
plt.tight_layout()
plt.savefig(os.path.join(FIG, "bacteria_bmi_scatter.png"), dpi=160, bbox_inches="tight")
plt.close()
print("saved figures/bacteria_bmi_scatter.png")
