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
    
    // Define methods to run
    // Define methods to run
    methods_ch = Channel.from("xgbTree")
    
    // Combine method name with data for parallel execution
    train_input_ch = methods_ch.combine(preproc_ch)
    
    TrainModel(train_input_ch)
}
