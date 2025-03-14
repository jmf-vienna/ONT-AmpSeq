rule cluster_ID:
    input:
        os.path.join(
            config["output_dir"],
            "polish",
            "samples_relabeled",
            "merged_polished_relabeled.fasta",
        ),
    output:
        otu_table=os.path.join(
            config["output_dir"], "cluster", "{id}", "otu_cluster_{id}.tsv"
        ),
        otu_centroids=os.path.join(
            config["output_dir"], "cluster", "{id}", "otu_{id}.fa"
        ),
    wildcard_constraints:
        id="97|99",
    threads: config["max_threads"]
    resources:
        mem_mb=2048,
        runtime=1440,
    conda:
        "../envs/vsearch.yml"
    log:
        os.path.join(config["log_dir"], "07-clustering_identity", "otu_{id}.log"),
    params:
        id=lambda wildcards: float(wildcards.id) / 100,
    shell:
        """
        {{
        vsearch \
            --cluster_size {input} \
            --id {params.id} \
            --threads {threads} \
            --relabel_sha1 \
            --sizeout \
            --otutabout {output.otu_table} \
            --centroids {output.otu_centroids}
        }} > {log} 2>&1
        """


rule cluster_unoise:
    input:
        os.path.join(
            config["output_dir"],
            "polish",
            "samples_relabeled",
            "merged_polished_relabeled.fasta",
        ),
    output:
        otu_table=os.path.join(
            config["output_dir"], "cluster", "unoise", "otu_cluster_unoise.tsv"
        ),
        otu_centroids=os.path.join(
            config["output_dir"], "cluster", "unoise", "otu_unoise.fa"
        ),
    threads: config["max_threads"]
    resources:
        mem_mb=2048,
        runtime=1440,
    conda:
        "../envs/vsearch.yml"
    log:
        os.path.join(config["log_dir"], "07-clustering_identity", "otu_unoise.log"),
    shell:
        """
        {{
        vsearch \
            --cluster_unoise {input} \
            --minsize 1 \
            --threads {threads} \
            --relabel_sha1 \
            --sizeout \
            --otutabout {output.otu_table} \
            --centroids {output.otu_centroids}
        }} > {log} 2>&1
        """


rule cluster_ID_unpolished:
    input:
        os.path.join(config["output_dir"], "merged_filtered_relabeled.fasta"),
    output:
        otu_table=os.path.join(
            config["output_dir"], "cluster", "{id}_unpolished", "otu_cluster_{id}_unpolished.tsv"
        ),
        otu_centroids=os.path.join(
            config["output_dir"], "cluster", "{id}_unpolished", "otu_{id}_unpolished.fa"
        ),
    wildcard_constraints:
        id="97|99",
    threads: config["max_threads"]
    resources:
        mem_mb=2048,
        runtime=1440,
    conda:
        "../envs/vsearch.yml"
    log:
        os.path.join(config["log_dir"], "07-clustering_identity", "otu_{id}_unpolished.log"),
    params:
        id=lambda wildcards: float(wildcards.id) / 100,
    shell:
        """
        {{
        vsearch \
            --cluster_size {input} \
            --id {params.id} \
            --threads {threads} \
            --relabel_sha1 \
            --sizeout \
            --otutabout {output.otu_table} \
            --centroids {output.otu_centroids}
        }} > {log} 2>&1
        """


rule cluster_unoise_unpolished:
    input:
        os.path.join(config["output_dir"], "merged_filtered_relabeled.fasta"),
    output:
        otu_table=os.path.join(
            config["output_dir"], "cluster", "unoise_unpolished", "otu_cluster_unoise_unpolished.tsv"
        ),
        otu_centroids=os.path.join(
            config["output_dir"], "cluster", "unoise_unpolished", "otu_unoise_unpolished.fa"
        ),
    threads: config["max_threads"]
    resources:
        mem_mb=2048,
        runtime=1440,
    conda:
        "../envs/vsearch.yml"
    log:
        os.path.join(config["log_dir"], "07-clustering_identity", "otu_unoise_unpolished.log"),
    shell:
        """
        {{
        vsearch \
            --cluster_unoise {input} \
            --minsize 1 \
            --threads {threads} \
            --relabel_sha1 \
            --sizeout \
            --otutabout {output.otu_table} \
            --centroids {output.otu_centroids}
        }} > {log} 2>&1
        """