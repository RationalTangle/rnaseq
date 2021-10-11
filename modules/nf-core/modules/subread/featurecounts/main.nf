process SUBREAD_FEATURECOUNTS {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::subread=2.0.1" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/subread:2.0.1--hed695b0_0"
    } else {
        container "quay.io/biocontainers/subread:2.0.1--hed695b0_0"
    }

    input:
    tuple val(meta), path(bams), path(annotation)

    output:
    tuple val(meta), path("*featureCounts.txt")        , emit: counts
    tuple val(meta), path("*featureCounts.txt.summary"), emit: summary
    path "versions.yml"                                , emit: versions

    script:
    def prefix     = task.ext.suffix ? "${meta.id}${task.ext.suffix}" : "${meta.id}"
    def args       = task.ext.args ?: ''
    def paired_end = meta.single_end ? '' : '-p'

    def strandedness = 0
    if (meta.strandedness == 'forward') {
        strandedness = 1
    } else if (meta.strandedness == 'reverse') {
        strandedness = 2
    }
    """
    featureCounts \\
        $args \\
        $paired_end \\
        -T $task.cpus \\
        -a $annotation \\
        -s $strandedness \\
        -o ${prefix}.featureCounts.txt \\
        ${bams.join(' ')}

    cat <<-END_VERSIONS > versions.yml
    SUBREAD_FEATURECOUNTS:
        subread: \$( echo \$(featureCounts -v 2>&1) | sed -e "s/featureCounts v//g")
    END_VERSIONS
    """
}
