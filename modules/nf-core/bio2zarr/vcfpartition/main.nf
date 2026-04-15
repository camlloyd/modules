process BIO2ZARR_VCFPARTITION {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/e5/e59f436b2c0a983ed5f6dd9e2f3e6dbae29f2485eed7619eecf95728a21452bc/data':
        'community.wave.seqera.io/library/bio2zarr:0.2.0--2753abf84a960f5e' }"

    input:
    tuple val(meta), path(vcf), path(index)

    output:
    tuple val(meta), path("*.tsv"), emit: partitions
    tuple val("${task.process}"), val('vcfpartition'), eval("vcfpartition --version | sed 's/.* //'"), topic: versions, emit: versions_vcfpartition

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    vcfpartition \\
        ${args} \\
        ${vcf} \\
        > ${prefix}.tsv
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.tsv
    """
}
