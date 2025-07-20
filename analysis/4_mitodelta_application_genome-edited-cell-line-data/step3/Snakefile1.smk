# Snakefile
#mitodelta = "."
#out_dir = "./outputs"

rule all:
    input:
        "outputs/1_del.tsv"

rule step3:
    input:
        "results/step2.txt"
    output:
        "outputs/step3_deletions_afterfiltering_del.tsv"
    params:
        script="./scripts/03_step3.sh",
        path=".",
        out="./outputs",
        err="1.0",
        fdr="0.05"
    shell:
        """
        bash {params.script} {params.path} {params.out} {params.err} {params.fdr}
        """
