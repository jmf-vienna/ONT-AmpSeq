configfile: "config/config.yaml"
if config['taxonomy_sintax']:
    rule fix_otu_table_sintax:
        input: 
            otu_txt =  os.path.join(config['output_dir'], "taxonomy", "{id}", "otu_taxonomy_{id}_sintax.txt"),
            otu_tsv = os.path.join(config['output_dir'], "cluster", "{id}", "otu_cluster_{id}.tsv")
        output:
            output_all = os.path.join(config["output_dir"], "OTU-tables", "{id}", "otu_table_all_{id}_sintax.tsv"),
            output_temp = temp(os.path.join(config["tmp_dir"], "{id}", "otu_taxonomy_{id}_cut_temp_sintax.txt"))
        threads:
            1
        resources:
            mem_mb = 1024,
            runtime = "01:00:00"
        log:
            os.path.join(config["log_dir"], "fix_otu_table_sintax", "otu_table_all_{id}.log")
        shell:
            """
                awk -F "\t" 'OFS="\t"{{gsub(/;.*/," ",$1);print $1 $4}}' {input.otu_txt} | awk -F ' ' '{{print $1"\t"$2}}' > {output.output_temp}
                awk 'BEGIN {{FS=OFS="\t"}} NR==FNR {{hold[$1]=$2; next}} {{print $0, hold[$1]}}' {output.output_temp} "{input.otu_tsv}" > {output.output_all}
            """
if config['taxonomy_blast']:
    rule prep_input_blast:
        input:
            os.path.join(config['output_dir'], "taxonomy", "{id}", "otu_taxonomy_{id}_blast.txt")
        output:
            os.path.join(config["output_dir"], "OTU-tables", "{id}", "otu_taxonomy_{id}_blast_trimmed.txt")
        threads:
            1
        resources:
            mem_mb = 1024,
            runtime = "01:00:00"
        log:
            os.path.join(config["log_dir"], "prep_input_blast", "otu_taxonomy_{id}_blast.log")
        shell:
            """
            #trim the blast output to only include the OTU and the taxonomy
            awk -F'\t' '{{print $1 "\t" $2}}' {input} > {output}
            sed -i 's/;size=[0-9]\\+\t/\t/' {output}
            """