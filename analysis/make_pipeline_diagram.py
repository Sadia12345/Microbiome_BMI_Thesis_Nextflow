#!/usr/bin/env python3
"""
Render the Nextflow pipeline diagram used in the thesis Methods chapter.

Pure matplotlib (no data dependency). Writes figures/nextflow_pipeline.png.
"""
import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

FIG = "figures"
os.makedirs(FIG, exist_ok=True)
NAVY = "#1f3a93"
LIGHT = "#e8edf7"

fig, ax = plt.subplots(figsize=(7.4, 9.7))
ax.set_xlim(0.4, 9.6)
ax.set_ylim(1.4, 22.2)
ax.axis("off")


def box(y, text, h=1.4, w=8.8, fc=LIGHT, tc="#10204a", bold=False, fs=10.5):
    ax.add_patch(FancyBboxPatch((5 - w / 2, y), w, h,
                 boxstyle="round,pad=0.08,rounding_size=0.18", fc=fc, ec=NAVY, lw=1.7))
    ax.text(5, y + h / 2, text, ha="center", va="center", fontsize=fs,
            color=tc, weight="bold" if bold else "normal")


def arrow(y1, y2):
    ax.add_patch(FancyArrowPatch((5, y1), (5, y2), arrowstyle="-|>",
                 mutation_scale=18, lw=1.8, color=NAVY))


steps = [
    ("Metalog resource (2025-12-14 snapshot)\nmetadata + MetaPhlAn 4 species profiles", NAVY, "white", True),
    ("Merge by sample ID  →  17,903 gut metagenomes\noutcome: BMI;  predictors: species abundance only", LIGHT, "#10204a", False),
    ("Prevalence filter (≥1% of samples)\n10,701 → 1,799 species", LIGHT, "#10204a", False),
    ("Variance-based top-500 filter\n1,799 → 500 species", LIGHT, "#10204a", False),
    ("Near-zero-variance removal + centre/scale\n(not CLR — see Limitations)", LIGHT, "#10204a", False),
    ("Model training via mikropml / caret\nRandom Forest, Elastic Net, Linear SVM, rpart", LIGHT, "#10204a", False),
    ("Sample-size ladder 2k–16k  ·  3-fold CV\nsaturation + feature importance", LIGHT, "#10204a", False),
    ("Outputs: R² / RMSE, saturation curve,\nfeature ranking, predicted-vs-actual BMI", NAVY, "white", True),
]

top, gap, y = 18.8, 2.2, 18.8
for i, (txt, fc, tc, bold) in enumerate(steps):
    box(y, txt, fc=fc, tc=tc, bold=bold)
    if i < len(steps) - 1:
        arrow(y - 0.05, y - gap + 1.4 + 0.05)
    y -= gap

ax.text(5, 21.4, "Nextflow pipeline (primary workflow)",
        ha="center", va="center", fontsize=13.5, weight="bold", color=NAVY)

plt.savefig(os.path.join(FIG, "nextflow_pipeline.png"), dpi=180,
            bbox_inches="tight", pad_inches=0.05)
print("saved figures/nextflow_pipeline.png")
