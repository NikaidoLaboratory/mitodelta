# Snakefile
mitodelta = "."

rule all:
    input:
        "results/step3_deletions_afterfiltering_wt.tsv"

rule step2:
    input:
        "results/step1_wt.txt"
    output:
        "results/step2_deletions_beforefiltering_wt.tsv"
    params:
        script="./scripts/02_step2.sh",
        path=mitodelta,
        config="./config_human.txt"
    shell:
        """
        bash {params.script} {params.path} {params.config}
        touch {output}
        """

rule step3:
    input:
        "results/step2_wt.txt"
    output:
        "results/step3_deletions_afterfiltering_wt.tsv"
    params:
        script="./scripts/03_step3.sh",
        path=".",
        err="1.0",
        fdr="0.05"
    shell:
        """
        bash {params.script} {params.path} {params.out} {params.err} {params.fdr}
        """
