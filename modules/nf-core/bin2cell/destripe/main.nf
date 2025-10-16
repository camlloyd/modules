process BIN2CELL_DESTRIPE {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/5d/5d739da7b9f6375c29035504fb45d1c21b2fda4824b2d63cd098132cb0c2a992/data':
        'community.wave.seqera.io/library/bin2cell:0.3.3--58c40b0a050aa0a7' }"

    input:
    tuple val(meta), path(binned), path(image), path(spatial)

    output:
    tuple val(meta), path("*.h5ad"), emit: adata
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    template('destripe.py')

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '0.3.3'
    """
    echo $args

    touch ${prefix}.h5ad

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bin2cell: ${VERSION}
    END_VERSIONS
    """
}
