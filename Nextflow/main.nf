#!/usr/bin/env nextflow

nextflow.enable.dsl=2

params.dataset = "$baseDir/../Data/metalog_subset.csv"
params.outcome = "bmi"
params.outdir = "$baseDir/results"

process Preprocess {
    input:
    path dataset

    output:
    path "preprocessed.rds"

    script:
    """
    Rscript $baseDir/bin/preprocess.R --input $dataset --outcome ${params.outcome} --output preprocessed.rds
    """
}

process TrainModel {
    input:
    tuple val(method), path(preprocessed_data)

    publishDir params.outdir, mode: 'copy'

    output:
    path "${method}_results.csv"
    path "${method}_model.rds"

    script:
    """
    Rscript $baseDir/bin/train_ml.R --input $preprocessed_data --outcome ${params.outcome} --method $method --output ${method}_results.csv --model_output ${method}_model.rds
    """
}

workflow {
    data_ch = Channel.fromPath(params.dataset)
    preproc_ch = Preprocess(data_ch)
    
    // Define methods to run: SVM (Linear), XGBoost (Tree), GLMNet, Rpart. (RF is already active).
    methods_ch = Channel.from("svmLinear", "xgbTree", "glmnet", "rpart")
    
    // Combine method name with data for parallel execution
    train_input_ch = methods_ch.combine(preproc_ch)
    
    // TrainModel(train_input_ch)
    
    // Collect all results for plotting
    // Nextflow DSL2 allows accessing output channels
    // We collect all result CSVs
    // Collect all results for plotting
    // Nextflow DSL2 allows accessing output channels
    // We collect all result CSVs
    // results_ch = TrainModel.out[0].collect()
    
    // PlotResults(results_ch)

    // Run Saturation Analysis (Primary Thesis Objective)
    SaturationAnalysis(preproc_ch)
}

process PlotResults {
    publishDir params.outdir, mode: 'copy'
    
    input:
    path results_csvs

    output:
    path "model_comparison.svg"

    script:
    """
    Rscript $baseDir/bin/plot_comparison.R
    """
}

process SaturationAnalysis {
    publishDir "${params.outdir}/saturation", mode: 'copy'

    input:
    path preprocessed_data

    output:
    path "saturation_r2.svg"
    path "scaling_time.svg"
    path "saturation_results.csv"

    script:
    """
    Rscript $baseDir/bin/run_saturation.R --input $preprocessed_data --outdir ./ --outcome ${params.outcome}
    """
}
