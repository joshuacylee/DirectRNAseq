#Merging fastq files generated from sequencing experiment
## Samples details can be found at sample sheet (.csv) located in sample subfolder

samples = pd.read_csv(config["sample_sheet"], dtype = str).set_index(["sample"], drop = False)

rule cat_fastq:
    input:
        lambda wildcards: samples.loc[wildcards.sample]["raw_data_dir"]
    output:
        "data/{sample}.fastq.gz"
    conda:
        "../envs/cdna_mapping.yml"
    shell:
        """
        catfishq -r {input} | gzip > {output}
        """
