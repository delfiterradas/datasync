process COMPARECHECKSUM {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/48/483e9d9b3b07e5658792d579e230ad40ed18daf7b9ebfb4323c08570f92fd1d5/data':
        'community.wave.seqera.io/library/r-base:4.2.1--b0b5476e2e7a0872' }"

    input:
    tuple val(meta), path(input_checksum), path(generated_checksum)

    output:
    tuple val(meta), path("*.csv"), emit: report
    tuple val(meta), path("*.csv"), emit: summary_report
    path "versions.yml"           , emit: versions_comparechecksum, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    template 'comparechecksum.R'

    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(Rscript -e "cat(as.character(getRversion()))")
    END_VERSIONS
    """
}
