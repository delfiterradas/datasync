process RCLONE {
    tag "${meta.id}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/6d/6d2dd2b3b0c1b1c6c8f7d5e3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4/data'
        : 'rclone/rclone:latest'}"

    input:
    tuple val(meta), path(source_path)
    val destination_path

    output:
    tuple val(meta), env(COPY_STATUS), emit: copy_status
    tuple val("${task.process}"), val('rclone'), env(RCLONE_VERSION), topic: versions, emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: '--verbose'
    """
    # Get rclone version
    RCLONE_VERSION=\$(rclone version | head -n1 | sed 's/rclone v//')

    # Prepare destination with same structure as source
    DEST="${destination_path}/\$(basename ${source_path})"

    # Run rclone copy command
    rclone copy ${args} "${source_path}" "\${DEST}"

    # Set status
    if [ \$? -eq 0 ]; then
        COPY_STATUS="success"
    else
        COPY_STATUS="failed"
    fi
    """

    stub:
    """
    RCLONE_VERSION="1.65.0"
    COPY_STATUS="success"
    """
}
