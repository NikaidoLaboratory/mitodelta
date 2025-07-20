# Snakefile
mitodelta = "/mitodelta_abs"


rule all:
    input:
        "./step3_deletions_afterfiltering.tsv"


rule step1:        
    output:
        "results/step1.txt"
    params:
        script=f"{mitodelta}/scripts/01_step1.sh",
        path=mitodelta,
        bam="./0_bamfile",
        label="./0_metafile"
    shell:
        """
        mkdir -p results
        bash {params.script} {params.path} {params.bam} {params.label}
        touch {output}
        """


rule step2:
    input:
        "results/step1.txt"
    output:
        "results/step2_deletions_beforefiltering.tsv"
    params:
        script=f"{mitodelta}/scripts/02_step2.sh",
        path=mitodelta,
        config=f"{mitodelta}/config_mouse.txt"
    shell:
        """
        bash {params.script} {params.path} {params.config}
        touch {output}
        """


rule step3:
    input:
        "results/step2_deletions_beforefiltering.tsv"
    output:
        "results/step3_deletions_afterfiltering.tsv"
    params:
        script=f"{mitodelta}/scripts/3_filter_variant.py",
        path=mitodelta,
        err="1.0",
        fdr="0.05"
    shell:
        """
        python {params.script} {input} {output} --err {params.err} --fdr {params.fdr}
        """
