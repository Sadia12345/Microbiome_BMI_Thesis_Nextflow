#!/usr/bin/env python3
"""
Plot the Random Forest prediction-error distribution (thesis Results figure).

Reads rf_cv_predictions.csv (produced by extract_rf_predictions.R from the saved model)
and draws the distribution of (predicted - actual) BMI. These are the genuine
cross-validated predictions of the thesis Random Forest model (n = 14,324;
MAE = 3.45, RMSE = 5.10 kg/m^2 -- the RMSE matches the reported cross-validation RMSE).

Usage:  python plot_prediction_error.py [path/to/rf_cv_predictions.csv]
Output: figures/prediction_error.png
"""
import os
import sys
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

CSV = sys.argv[1] if len(sys.argv) > 1 else "rf_cv_predictions.csv"
os.makedirs("figures", exist_ok=True)
OUT = "figures/prediction_error.png"
NAVY = "#1f3a93"

p = pd.read_csv(CSV)
err = (p["pred"] - p["obs"]).values
mae = np.mean(np.abs(err))
rmse = np.sqrt(np.mean(err ** 2))
w2 = (np.abs(err) <= 2).mean() * 100
w5 = (np.abs(err) <= 5).mean() * 100

fig, ax = plt.subplots(figsize=(8, 5))
ax.hist(err, bins=70, range=(-22, 22), color=NAVY, alpha=0.85, edgecolor="white", linewidth=0.2)
ax.axvline(0, color="#111", lw=1.4)
ax.axvspan(-mae, mae, color="#c0392b", alpha=0.12)
ax.axvline(-mae, color="#c0392b", ls="--", lw=1)
ax.axvline(mae, color="#c0392b", ls="--", lw=1)
top = ax.get_ylim()[1]
ax.annotate(f"mean absolute error\n= {mae:.1f} BMI units", xy=(mae, top * 0.55),
            xytext=(9.5, top * 0.8), fontsize=9.5, color="#c0392b", ha="left",
            arrowprops=dict(arrowstyle="->", color="#c0392b"))
ax.text(-21, top * 0.92, f"{w5:.0f}% within ±5 BMI units\n{w2:.0f}% within ±2",
        fontsize=9, va="top", color="#333",
        bbox=dict(boxstyle="round", fc="#eef1f8", ec="#ccd6ee"))
ax.set_xlabel("Prediction error  =  predicted BMI − actual BMI (kg/m$^2$)")
ax.set_ylabel("Number of samples")
ax.set_title(f"Random Forest prediction-error distribution (cross-validated, n={len(p):,})")
plt.tight_layout()
plt.savefig(OUT, dpi=160)
print(f"saved {OUT}  MAE={mae:.3f} RMSE={rmse:.3f} within5={w5:.1f}%")
