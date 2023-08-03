# MAP TO GENOME WITH MINIMAP2
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

# * * * * * Map with minimap2

rule map_to_genome_cDNA:
    input:
        fastq = "data/{sample}.fastq.gz",
        index = config["genome_index"],
        anno  = config["annotation"]["bed"]
    output:
        bam  = "mapping/all/{sample}.sorted.bam",
        ubam = temp("mapping/all/{sample}.unsorted.bam")
    params:
        preset = '-ax splice',
        opts   = config["minimap2_opts"],
        msec   = config["maximum_secondary"],
        psec   = config["secondary_score_ratio"]
    conda:
        "../envs/drs_mapping.yml"
    threads:
        config["minimap2_threads"]
    log:
        "mapping/all/{sample}.log"
    shell:
        """
        minimap2 -y -t {threads} {params.preset} --junc-bed {input.anno} -p {params.psec} -N {params.msec} {params.opts} {input.index} {input.fastq} 2> {log} | samtools view -b - > {output.ubam}
        samtools sort -@ {threads} -o {output.bam} {output.ubam}
        samtools index {output.bam}
        """

rule filter_mappings_by_qual:
    input:
        "mapping/all/{sample}.sorted.bam",
    output:
        "mapping/qual/{sample}.sorted.bam",
    params:
        config["min_mapping_qual"]
    conda:
        "../envs/drs_mapping.yml"
    threads:
        config["threads"]
    log:
        "mapping/qual/{sample}.log"
    shell:
        """
        samtools view -@ {threads} -q {params} -b {input} > {output}
        samtools index {output}
        """

rule count:
    input:
        bam = "mapping/qual/{sample}.sorted.bam",
        anno = config["annotation"]["gtf"]
    output:
        "counting/{sample}.tsv",
    params:
        preset = "-L -D 1000000 -t exon -g gene_id",
        opts   = config["featurecounts_opts"]
    conda:
        "../envs/drs_mapping.yml"
    threads:
        config["threads"]
    log:
        "counting/{sample}.log"
    shell:
        """
        featureCounts -T {threads} {params.preset} {params.opts} \
        -a {input.anno} -o {output} {input.bam} 2> {log}
        """

#
