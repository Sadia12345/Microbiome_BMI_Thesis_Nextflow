# Thesis Project: Technical Summary & Defense Guide

## 1. The Research Goal
**Objective:** To determine if we can predict a person's Body Mass Index (BMI) solely by looking at the bacteria in their gut (the Microbiome).
**Why?** If we can predict BMI from bacteria, it proves that the microbiome is deeply linked to metabolic health and obesity.

## 2. The Data: "Metalog"
We used the **Metalog Database**, a standardized collection of human microbiome samples.
*   **Raw Data Source:** Thousands of public studies aggregated into one database.
*   **The "Cleaning" Process (Why 17,903?):**
    *   **Step 1 (The Filter):** We only selected samples that had *both* high-quality genetic sequencing *and* clinical BMI data.
    *   **Step 2 (The Merge):** We performed an **Inner Join** between the species table (bacteria) and the metadata table (BMI).
    *   **Result:** 17,903 unique samples.
    *   **Significance:** This is a **massive** dataset for this field. Most microbiome studies have <500 samples. Using 17k samples gives our machine learning models huge statistical power to find real patterns.

## 3. The Methodology: "Nextflow" Pipeline
We didn't just run a script; we built a **Pipeline**.
*   **Tool:** Nextflow.
*   **Why Nextflow?**
    *   **Reproducibility:** Anyone can download our code and get the *exact* same results.
    *   **Scalability:** If we later get 100,000 samples, or want to run on a Supercomputer (CSC), this pipeline handles it automatically.
    *   **Resumability:** If the computer crashes, we don't start from zero.

## 4. The Machine Learning Models
We compared different "ways of thinking" (Algorithms) to see which fits the biology best.

### A. GLMNet (The Linear Baseline)
*   **What is it?** A Generalized Linear Model (Elastic Net).
*   **How it thinks:** "If Bacteria X goes up, BMI goes up (or down) by a fixed amount."
*   **Why use it?** It is simple, fast, and easy to interpret. It selects only the most important bacteria (Feature Selection).
*   **Performance:** $R^2 = 0.14$ (Moderate).
*   **Conclusion:** There is a signal, but a simple linear line can't explain the whole story.

### B. Random Forest (The Non-Linear Champion)
*   **What is it?** A decision tree ensemble. It builds hundreds of "Yes/No" flowcharts and averages them.
*   **How it thinks:** "If Bacteria A is high AND Bacteria B is low, THEN large effect." (Interactions).
*   **Why use it?** Biology is complex. Bacteria talk to each other. Random Forest captures these non-linear interactions.
*   **Performance:** $R^2 = 0.325$ (Excellent).
*   **Conclusion:** $R^2$ more than doubled! This proves that the **interaction** between bacteria is more important than any single bacteria alone.

### C. Advanced Models (XGBoost & SVM) - *Running Now*
*   **XGBoost:** Similar to Random Forest but "learns from its mistakes" (Gradient Boosting). Often the state-of-the-art.
*   **SVM (Support Vector Machine):** Good at separating complex high-dimensional data.
*   **Goal:** To see if we can squeeze out even more accuracy than Random Forest.

## 5. Technical Challenges & Solutions
### The "Sleep" Issue & Runtime
*   **Challenge:** Training Random Forest on 17,000 samples with 20,000 features is incredibly heavy. It takes days.
*   **Solution (The "Fast Track"):** We reduced the specific precision setting (k-fold Cross-Validation) from 5 to 2.
*   **Justification:** For a Master's Thesis, proving the *concept* (RF > GLMNet) is more important than getting the decimal point perfect. This allowed us to get results in 12 hours instead of 4 days.

## 6. Future Studies
Where could this go next?
1.  **Feature Importance:** Extract exactly *which* 20 bacteria are driving the Random Forest prediction.
2.  **Stratification:** Does the model work better on Women vs Men? Young vs Old?
3.  **Supercomputer:** Run the full 10-fold cross-validation on the CSC cluster for publication-quality rigor.

## Summary for Comparison
"I built a scalable Nextflow pipeline to analyze one of the largest microbiome datasets available (17k samples). I demonstrated that non-linear machine learning (Random Forest) vastly outperforms traditional linear methods, explaining 32.5% of BMI variation compared to just 14%. This suggests the gut microbiome influences obesity through complex, interactive community structures."
