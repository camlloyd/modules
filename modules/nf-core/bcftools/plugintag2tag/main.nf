process BCFTOOLS_PLUGINTAG2TAG {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/5a/5acacb55c52bec97c61fd34ffa8721fce82ce823005793592e2a80bf71632cd0/data':
        'community.wave.seqera.io/library/bcftools:1.21--4335bec1d7b44d11' }"

    input:
    tuple val(meta), path(vcf), path(index)
    path(regions)
    path(targets)

    output:
    tuple val(meta), path("*.{vcf,vcf.gz,bcf,bcf.gz}"), emit: vcf
    tuple val(meta), path("*.tbi")                    , emit: tbi, optional: true
    tuple val(meta), path("*.csi")                    , emit: csi, optional: true
    path "versions.yml"                               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def regions_file = regions ? "--regions-file ${regions}" : ""
    def targets_file = targets ? "--targets-file ${targets}" : ""
    def extension = args.contains("--output-type b") || args.contains("-Ob") ? "bcf.gz" :
                    args.contains("--output-type u") || args.contains("-Ou") ? "bcf" :
                    args.contains("--output-type z") || args.contains("-Oz") ? "vcf.gz" :
                    args.contains("--output-type v") || args.contains("-Ov") ? "vcf" :
                    "vcf"
    """
    bcftools plugin tag2tag \\
        --output ${prefix}.${extension} \\
        ${regions_file} \\
        ${targets_file} \\
        $args \\
        --threads $task.cpus \\
        ${vcf} \\
        -- \\
        $args2

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def extension = args.contains("--output-type b") || args.contains("-Ob") ? "bcf.gz" :
                    args.contains("--output-type u") || args.contains("-Ou") ? "bcf" :
                    args.contains("--output-type z") || args.contains("-Oz") ? "vcf.gz" :
                    args.contains("--output-type v") || args.contains("-Ov") ? "vcf" :
                    "vcf"
    def stub_index = args.contains("--write-index=tbi") || args.contains("-W=tbi") ? "tbi" :
                     args.contains("--write-index=csi") || args.contains("-W=csi") ? "csi" :
                     args.contains("--write-index")     || args.contains("-W") ? "csi" :
                     ""
    def create_cmd = extension.endsWith(".gz") ? "echo '' | gzip >" : "touch"
    def create_index = extension.endsWith(".gz") && stub_index.matches("csi|tbi") ? "touch ${prefix}.${extension}.${stub_index}" : ""
    """
    ${create_cmd} ${prefix}.${extension}
    ${create_index}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """
}
