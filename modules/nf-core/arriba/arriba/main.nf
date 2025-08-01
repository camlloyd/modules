process ARRIBA_ARRIBA {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/27/27475cdcdbcc8c0ffb6b5ca8c2e6567dbe490edb96f5df4e8f01f4f95912dcd3/data' :
        'community.wave.seqera.io/library/arriba_wget:a3e48cf793a0b654' }"

    input:
    tuple val(meta),  path(bam)
    tuple val(meta2), path(fasta)
    tuple val(meta3), path(gtf)
    path(blacklist)
    path(known_fusions)
    path(cytobands)
    path(protein_domains)

    output:
    tuple val(meta), path("*.fusions.tsv")          , emit: fusions
    tuple val(meta), path("*.fusions.discarded.tsv"), emit: fusions_fail
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    def blacklist_arg       = blacklist       ? "-b ${blacklist}"       : "-f blacklist"
    def known_fusions_arg   = known_fusions   ? "-k ${known_fusions}"   : ""
    def cytobands_arg       = cytobands       ? "-d ${cytobands}"       : ""
    def protein_domains_arg = protein_domains ? "-p ${protein_domains}" : ""

    """
    arriba \\
        -x ${bam} \\
        -a ${fasta} \\
        -g ${gtf} \\
        -o ${prefix}.fusions.tsv \\
        -O ${prefix}.fusions.discarded.tsv \\
        ${blacklist_arg} \\
        ${known_fusions_arg} \\
        ${cytobands_arg} \\
        ${protein_domains_arg} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        arriba: \$(arriba -h | grep 'Version:' 2>&1 |  sed 's/Version:\s//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo stub > ${prefix}.fusions.tsv
    echo stub > ${prefix}.fusions.discarded.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        arriba: \$(arriba -h | grep 'Version:' 2>&1 |  sed 's/Version:\s//')
    END_VERSIONS
    """
}
