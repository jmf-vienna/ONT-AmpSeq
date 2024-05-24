# Snakemake workflow: `ONT-AmpSeq`

[![Snakemake](https://img.shields.io/badge/snakemake-≥7.18.2-brightgreen.svg)](https://snakemake.github.io)
[![GitHub actions status](https://github.com/MathiasEskildsen/ONT-AmpSeq/workflows/Tests/badge.svg?branch=main)](https://github.com/MathiasEskildsen/ONT-AmpSeq/actions?query=branch%3Amain+workflow%3ATests)

## Description
ONT-AmpSeq is a snakemake workflow, designed to generate OTU-tables from demultiplexed amplicon data. Developed using the following [snakemake template](https://github.com/cmc-aau/snakemake_project_template). The final product of the pipeline is OTU tables formatted to be directly compatiable with the R-packages [ampvis2](https://kasperskytte.github.io/ampvis2/index.html) and [phyloSeq](https://github.com/joey711/phyloseq), enabling further analysis and visualisation of the microbial composition of the processed samples. ONT-AmpSeq expects the input files to be demultiplexed and basecalled prior to running the workflow, using programs such as [dorado](https://github.com/nanoporetech/dorado). The workflow filters data based on user-defined thresholds, which are set in the configuration file `config/config.yaml`, which allows for changes to filter thresholds related to amplicon length and quality, using [chopper](https://github.com/wdecoster/chopper). The amplicon thresholds for each dataset can be assessed using the bash [statistics script](#usage-of-stats-script) located at `~/ONT-AmpSeq/workflow/scripts/nanoplot.sh`. An user guide for preliminary visualisation and analysis to estimate the user-defined thresholds can be found [here](#usage-of-stats-script).
Then ONT-AmpSeq pipeline creates biologically meaningful consensus OTU's from each sample, by initially clustering the reads into OTU's using [Vsearch](https://github.com/torognes/vsearch) and denoised using the [UNOISE3](https://doi.org/10.1093/bioinformatics/btv401) algorithm. OTU's from every sample are then merged and polished using [Racon](https://github.com/isovic/racon) to minimise sequence errors. Taxonomy is annotated to the OTU's using either the [SINTAX](https://drive5.com/usearch/manual/sintax_algo.html) algorithm or the [BLAST](https://blast.ncbi.nlm.nih.gov/Blast.cgi) algorithm (more information on taxonomy and databases can be found [here](#databases)).
NOTE:
This workflow is actively improved and supported, with new features continuously being implemented.

## Table of Contents
- [Requirements](#requirements)
- [Usage of Workflow with Snakedeploy](#usage-of-workflow-snakedeploy)
- [Uage of Workflow AAU Biocloud Users](#usage-of-workflow-aau-biocloud-hpc-users)
- [Outputs](#outputs)
- [Stats script](#usage-of-stats-script)
- [Database Choice](#databases)

## Requirements
### Hardware requirements
As a general recommendation for running ONT-AmpSeq whilst producing every possible output, at least 32 threads and 40 GB of memory are advised. THese high requirements stem from the multithreading capabilities of the various software and tools used in the pipeline, as well as the need/possibility to handle very large datasets/databases. While the pipeline has been successfully run with 1 thread and as little as 4 GB of memory using smaller datasets `~/ONT-AmpSeq/.test/test_data` and the MiDAS v5.3 [SINTAX database](https://www.midasfieldguide.org/guide/downloads), using large datasets may cause minimap2 to run out of memory. Additionally, in order to load the general BLAST-formatted [GenBank database](https://www.ncbi.nlm.nih.gov/genbank/) requires ~40 GB of memory, see [BLAST database formatting](#databases).

### Software requirements
To run ONT-AmpSeq, Linux OS or WSL is required. Installation of software/tools utilized in the workflow is based on and requires conda. Using snakemake, the correct versions of the tools will automatically be installed to ensure version compatibility. However, prior to installing ONT-AmpSeq, conda and the subsequent conda environment are required to facilitate the installation of the various utilised tools for both the snakemake and SnakeDeploy installations. For more details, see [SnakeDeploy installation](#usage-of-workflow-snakedeploy).

Conda can be installed by following this [guide](https://conda.io/projects/conda/en/latest/user-guide/install/index.html) or Mamba can be installed by following this [guide](https://mamba.readthedocs.io/en/latest/installation/mamba-installation.html).
It is recommended to follow the original documentation. However, below are the commands used to freshly install the software on a Linux machine as per their documentation (14-05-2024).
Latest version of Miniconda:
```
mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm -rf ~/miniconda3/miniconda.sh
```  
Initialize Miniconda:
```
~/miniconda3/bin/conda init bash
~/miniconda3/bin/conda init zsh
```
Add channels (for fresh install):
```
conda config --add channels conda-forge
conda config --add channels bioconda
```

Now your conda install is correctly configured and you're ready to create your conda environment for snakemake.

## Usage of ONT-AmpSeq using SnakeDeploy
The usage of this workflow is also described in the [Snakemake Workflow Catalog](https://snakemake.github.io/snakemake-workflow-catalog?usage=MathiasEskildsen/ONT-AmpSeq).
### Step 1: Install Snakemake and SnakeDeploy
Compatible versions of snakemake and SnakeDeploy for this guide are installed via the [Mamba package manager](https://github.com/mamba-org/mamba) (a package manager alternative for conda). If you have neither Conda nor Mamba, it can be installed via [Mambaforge](https://github.com/conda-forge/miniforge#mambaforge) or refer to the Miniconda installation and setup in [Requirements](#software-requirements).
Given that Mamba (If Miniconda is installed, then mamba can be changed for conda) is installed, a compatible conda environment for snakemake and SnakeDeploy can be created by running:
```
mamba create -c conda-forge -c bioconda --name snakemake snakemake=7.18.2 snakedeploy
```
This installs both snakemake and SnakeDeploy in the same environment called `snakemake`. For running ONT-AmpSeq using the SnakeDeploy method, this environment is required to be activated via `mamba activate snakemake`, prior to running any of the following commands for the workflow.
### Step 2: Deploy workflow
Given that Snakemake and Snakedeploy are installed and activated in [step 1](#step-1-install-snakemake-and-snakedeploy), the workflow can now be deployed through the following steps.
First: Create an appropriate project working directory on your system and change your location to said directory:
```
mkdir -p path/to/ONT-AmpSeq
cd path/to/ONT-AmpSeq
```
In the following steps, it is assumed that you have set your working directory to `path/to/ONT-AmpSeq`.
Second: Run the SnakeDeploy command for ONT-AmpSeq:
```
snakedeploy deploy-workflow https://github.com/MathiasEskildsen/ONT-AmpSeq . --branch main
```

SnakeDeploy will then create two folders `workflow` and `config`. The `workflow` folder contains the deployment of the chosen workflow (ONT-AmpSeq) in the form of a [Snakemake module](https://snakemake.readthedocs.io/en/stable/snakefiles/deployment.html#using-and-combining-pre-exising-workflows). The `config` folder contains configuration files, which can be modified using the next step, in order to configure the workflow, depending on the user-defined criteria and individual analysed datasets. Later, when executing the workflow, Snakemake will automatically find the main `Snakefile` in the `workflow` subfolder. 

Third (optional): Consider to put this directory under version control, e.g. by managing it [via a (private) Github repository](https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/adding-locally-hosted-code-to-github)

### Step 3: Configure the workflow
The workflow needs to be configured according to the individual dataset content and requirements. Below is a thorough explaination of the settings that can be configured. These can either be changed directly in the config file located at `path/to/ONT-AmpSeq/config/config.yaml` or changed by command line arguments:
* `input_dir`: Path to the input folder, containing fastq files in compressed `file.fastq.gz` or decompressed `file.fastq` format. The pipeline expects the input files to conform to one of two directory structures, see [here](#usage-of-stats-script) for more information on directory structures.
* `output_dir`: Name and path to the output directory with the final OTU tables created by ONT-AmpSeq and a few important intermediary files, which may prove useful for other purposes.
* `tmp_dir`: A required directory for temporary files. Temporary files will be removed after a succesful run.
* `log_dir`: Directory for log files for all invoked rules, which may prove useful for debugging.
* `db_path_sintax`: Path to a [SINTAX formatted database](https://drive5.com/usearch/manual/sintax_algo.html), used to annotate consensus OTU's. For more information regarding SINTAX formatted databases, algorithm and how to find/create then, see [databases](#sintax-database).
* `db_path_blast`: Path to a nucleotide formatted [BLAST database](https://blast.ncbi.nlm.nih.gov/Blast.cgi). For more information regarding BLAST formatted databases, algorithm and how to find/create them, see [databases](#blast-database).
* `evalue`: E-value cutoff for blast. Defaultvalue = 1e-10. See [databases](#blast-database).
* `length_lower_limit`: Lower threshold length for filtering of amplicons. Default = 1200 bp. The amplicon filtering length should be changed, depending on the individual amplicon length for the given dataset. See [stats script](#usage-of-stats-script) for a guide to setting an appropriate length treshold using the script `ONT-AmpSeq/workflow/scripts/nanoplot.sh`.
* `length_upper_limit`: Upper threshold length for filtering of amplicons. Default = 1600 bp. The amplicon filtering length should be changed, depending on the individual amplicon length for the given dataset. See [stats script](#usage-of-stats-script) for a guide to setting an appropriate length treshold using the script `ONT-AmpSeq/workflow/scripts/nanoplot.sh`.
* `quality_cut_off`: Phred-quality score threshold (Q-score). Default = 23. To select an appropriate Q-score for a dataset, see [stats script](#usage-of-stats-script) for a more detailed guide for choosing appropriate Q-score and the effects hereof.
* `max_threads`: Maximum number of threads that can be used for any given rule.
* `include_blast_output`: Default = true. If true, ONT-AmpSeq will annotate the final OTU-table using the [BLAST](https://blast.ncbi.nlm.nih.gov/Blast.cgi) algorithm and a BlASTn formatted database.
* `include_sintax_output`: Default = true. If true, ONT-AmpSeq will annotate the final OTU-table using the SINTAX algorithm and a [SINTAX formatted database](https://drive5.com/usearch/manual/sintax_algo.html).

The workflow configurations can also be changed directly via the command line. When specifying the configuration parameters through the command line, default values will be used unless otherwise specified, as written in `path/to/ONT-AmpSeq/config/config.yaml`. To specify changed values for the config through the command line, use the following structure:
```
cd path/to/ONT-AmpSeq
mamba activate snakemake
snakemake --cores all --use-conda --config include_blast_output=False db_path_sintax=/path/to/SINTAX_DATABASE.fa length_lower_limit=400 length_upper_limit=800 quality_cut_off=20
```
The code snippet above will change your working directory to the project dir, enabling snakemake to locate the snakefile and configuration file. Activate your conda environment containing snakemake, as described in [step 1](#step-1-install-snakemake-and-snakedeploy). Finally, it will run the snakemake workflow, filtering out reads shorter than 400bp, longer than 800bp and with a Q-score <20. It will output OTU-tables with taxonomy annotated by a sintax database. 
### Step 4: Run the workflow
Given that the workflow has been properly deployed and configured, it can be executed as follows.
For running the workflow while deploying any necessary software via conda using the [Mamba package manager](https://github.com/mamba-org/mamba), run Snakemake with:
```
snakemake --cores all --use-conda
```
Given that you have chosen your project working-directory as previously stated. Snakemake will automatically detect the main `Snakefile` in the `workflow` subfolder and execute the workflow module that has been defined by the deployment in step 2.

For further options, fx. for cluster and cloud execution, see [the docs](https://snakemake.readthedocs.io/en/stable/). If you are an AAU user, see [this](#usage-of-workflow-through-slurm-aau-biocloud-users) section.
### Step 5: Generate report
After finalizing your data analysis, you can automatically generate an interactive visual HTML report for inspection of results together with parameters and code inside of the browser using:
```
snakemake --report report.zip
```
The resulting `report.zip` file can be passed on to collaborators, provided as a supplementary file in publications, or uploaded to a service like [Zenodo](https://zenodo.org/) in order to obtain a citable [DOI](https://en.wikipedia.org/wiki/Digital_object_identifier).

## Usage of workflow (AAU BioCloud HPC users)
AAU BioCloud HPC users can also use the snakedeploy [step-by-step](#usage-with-snakedeploy), however it is recommended to follow the guide below as this will include scripts to help you submit jobs via. SLURM. If you want further guidance on snakemake and BioCloud usage refer to the [user guide](https://cmc-aau.github.io/biocloud-docs/guides/snakemake/intro/).

Change the path to your project-directory
```
cd /path/to/project-dir
wget -O https://github.com/MathiasEskildsen/ONT-AmpSeq/archive/refs/heads/main.tar.gz | tar -xz
```
Install dependencies (BioCloud users already have mamba installed natively)
```
cd ONT-AmpSeq-main
mamba env create -f environment.yml
```
Configure `config/config.yaml` as described [previously](#step-3-configure-the-workflow). Then simply run `snakemake --profile profiles/biocloud` or submit a SLURM job using the `slurm_submit.sbatch` example script. If running the pipeline through `slurm_submit.sbatch`, remember to change the `#SBATCH` arguments at the top of the script, to fit your run (--job-name, --mail and --time). Snakemake will automatically queue jobs with the necesarry ressources so you do not need to change ressources specified in `slurm_submit.sbatch`.

## Outputs
NOTE: `{id}` refers to the percentage identity which reads should be similar in order to be clustered into an OTU. Defaults = [97%, 99%]. Outputs can be annotated with either a blastn or SINTAX formatted database or both.
* `OTUtable_tax_{id}_sintax.tsv`: Matrix containing number of reads per sample per OTU. Taxonomy of each OTU is annotated by a SINTAX formatted [database](#databases). The OTU table is formatted to be ready for data analysis using [Ampvis2](https://kasperskytte.github.io/ampvis2/index.html).
* `phyloseq_tax_{id}_sintax.tsv`: Matrix containing taxonomy for each OTU annotated by a SINTAX formatted [database](#databases).
* `phyloseq_abundance_{id}_sintax.tsv`: Matrix containing OTU abundance information for each sample.
* `OTUtable_tax_{id}_blast.tsv`: Matrix containing number of reads per sample per OTU. Taxonomy of each OTU is annotated by a blastn formatted [database](#databases). The OTU table is formatted to be ready for data analysis using [Ampvis2](https://kasperskytte.github.io/ampvis2/index.html). NOTE: Blastn results can give a lot of edge-cases in relation to the formatting of output taxonomy. Be sure to double check annotated taxonomy when using this approach. 
* `phyloseq_tax_{id}_blast.tsv`: Matrix containing taxonomy for each OTU annotated by a blast formatted [database](#databases).
* `phyloseq_abundance_{id}_blast.tsv`: Matrix containing OTU abundance information for each sample.
* `total_reads.tsv`: Number of reads in each sample pre- and post-filtering.
## Usage of stats script
The stats script can be used to visualize read characteristics of the amplicon-sequencing data produced by ONT. The script works on both compressed and decompressed `.fastq` files. The files can be located in the same directory or individual sub-directores. However, if the files are located in the same directory, files originating from the same barcode have to be merged before running the script. 
Input directory structure examples:
```
../data
└── samples
    ├── barcode01
    │   ├── PAQ88430_pass_barcode01_807aee6b_5f7fc5bf_0.fastq
    │   ├── PAQ88430_pass_barcode01_807aee6b_5f7fc5bf_1.fastq
    │   └── PAQ88430_pass_barcode01_807aee6b_5f7fc5bf_2.fastq
    ├── barcode02
    │   ├── PAQ88430_pass_barcode02_807aee6b_5f7fc5bf_0.fastq
    │   ├── PAQ88430_pass_barcode02_807aee6b_5f7fc5bf_1.fastq
    │   └── PAQ88430_pass_barcode02_807aee6b_5f7fc5bf_2.fastq
    └── barcode03
        ├── PAQ88430_pass_barcode03_807aee6b_5f7fc5bf_0.fastq
        ├── PAQ88430_pass_barcode03_807aee6b_5f7fc5bf_1.fastq
        └── PAQ88430_pass_barcode03_807aee6b_5f7fc5bf_2.fastq
```
```
../data
└── samples
    ├── PAQ88430_pass_barcode01_807aee6b.fastq
    ├── PAQ88430_pass_barcode02_807aee6b.fastq
    └── PAQ88430_pass_barcode03_807aee6b.fastq
```


Usage:
```
-- insert full pipeline name: Nanopore Statistics with NanoPlot
usage: nanoplot [-h] [-o path] [-i path] [-t value] [-j value]

where:
    -h Show this help message.
    -o Path where directories should be created and files should be stored
    -i Full path to .fastq.gz files from Nanopore, example: /Full/Path/to/nanopore_data/ONT_RUN_ID/fastq_pass  
    -j Number of parallel jobs [default = 1]
    -t Number of threads [default = 1]
    Important note:
    Remember to activate your conda environment, containing nanoplot version 1.42.0, before running the script.
    If installed through stats.yml, activate the environment with mamba activate stats.
```
Example command:

```
mamba activate stats
bash ../scripts/nanoplot.sh -o ../out_dir -i ../data/samples -t 1 -j 1 
```
The command will create a directory under your chosen directory (or to a full path) called `out_dir` containing three sub-directories `stats`, `fastqs` and `joblog`. The `stats` sub-directory will contain plots for each sample, in their respective sub-directory, the `LengthvsQualityScatterPlot_dot.png` provides a great overview of the reads. `fastqs` contains unzipped merged fastq files, can be removed. `joblog` contains a text file with the command-line output. Can be useful for debugging.

## Databases
MiDAS SINTAX database can be downloaded [here](https://www.midasfieldguide.org/guide/downloads)

For more information regarding blastn databases look [here](https://www.ncbi.nlm.nih.gov/books/NBK279684/table/appendices.T.makeblastdb_application_opt/)

### SINTAX database

### BLAST database

# TODO
* Add release version
* Add description of final outputs
* Flesh out readme with database choice
* Add split_taxonomy.py script to better handle edge case annotation from blast
* Add .test to pass linting test