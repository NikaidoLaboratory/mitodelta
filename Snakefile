# Snakefile
mitodelta = "/path/to/mitodelta"
out_dir = "/path/to/outputdir"


rule all:
    input:
        f"{out_dir}/step3_deletions_afterfiltering.tsv"


rule step1:        
    output:
        "results/step1.txt"
    params:
        script=f"{mitodelta}/scripts/01_step1.sh",
        path=mitodelta,
        bam="/path/to/bam_dir",
        label="/path/to/label_dir",
        out=out_dir
    shell:
        """
        mkdir -p results
        bash {params.script} {params.path} {params.bam} {params.label} {params.out}
        touch {output}
        """


rule step2:
    input:
        "results/step1.txt"
    output:
        "results/step2.txt"
    params:
        script=f"{mitodelta}/scripts/02_step2.sh",
        path=mitodelta,
        config=f"{mitodelta}/config_human.txt",
        out=out_dir
    shell:
        """
        bash {params.script} {params.path} {params.config} {params.out}
        touch {output}
        """


rule step3:
    input:
        "results/step2.txt"
    output:
        f"{out_dir}/step3_deletions_afterfiltering.tsv"
    params:
        script=f"{mitodelta}/scripts/03_step3.sh",
        path=mitodelta,
        out=out_dir,
        err="1.0",
        fdr="0.05"
    shell:
        """
        bash {params.script} {params.path} {params.out} {params.err} {params.fdr}
        """
