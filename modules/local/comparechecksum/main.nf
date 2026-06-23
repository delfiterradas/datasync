process COMPARECHECKSUM {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/f7/f7934a95be2b2e704032cadba8f19685f32d1cebc8febad71e20b43c4f896a7f/data':
        'community.wave.seqera.io/library/bioconductor-anndatar_bioconductor-rhdf5_r-base_r-leidenbase_pruned:4e3c0f41d63a217a' }"

    input:
    tuple val(meta), path(input_checksum), path(generated_checksum)

    output:
    tuple val(meta), path("*.csv"), emit: report
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
