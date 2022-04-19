.ONESHELL:
SHELL = /bin/bash
.SHELLFLAGS := -e -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# The conda env definition file "requirements.yml" is located in the project's root directory
CURRENT_CONDA_ENV_NAME = v0_1_5-alpha
ACTIVATE_CONDA = source $$(conda info --base)/etc/profile.d/conda.sh
CONDA_ACTIVATE = $(ACTIVATE_CONDA) ; conda activate ; conda activate $(CURRENT_CONDA_ENV_NAME)

CPUS = 92
# ARGS = --forceall

.PHONY: \
create_inputs \
run \
clean \
collection \
archive \
help

REPORT = report.html

RESULTS = \
alignment \
annotation \
biomarker \
cnv_sv \
fusions \
prealignment \
qc \
results \
snv_indels \
genefuse.json \
# $(REPORT)


SAMPLE_DATA = \
samples.tsv \
units.tsv

DIR = 20220419_Twist_DNA_Solid_v0.1.5-alpha_VAL_01-40

# In this directory is gathered all results when you run command make archive
RESULTS_DIR = $(DIR)
# FASTQ_INPUT_DIR = /data/Twist_DNA_Solid/temp/BC/$(DIR)
# FASTQ_INPUT_DIR = /data/bcl2fastq/results/BC/220308_NB501689_0250_AHL7MJBGXL/Data/Intensities/BaseCalls
FASTQ_INPUT_DIR = /data/Twist_DNA_Solid/temp/BC/BC_17-24

STORAGE = /archive/Twist_DNA_Solid/results

#MAIN_SMK = /home/lauri/Desktop/Twist_DNA_Solid/workflow/Snakefile_v0.0.1.smk
MAIN_SMK = /data/Twist_DNA_Solid/Twist_DNA_Solid/workflow/Snakefile

## run: Run the main pipeline
run:
	$(CONDA_ACTIVATE)
	export SINGULARITY_LOCALCACHEDIR=/data/Twist_DNA_Solid/cache_dir
	snakemake --cores $(CPUS) \
	--use-singularity \
	--singularity-args "--bind /data/Twist_DNA_Solid/ref --bind /data/Twist_DNA --bind /data/Twist_DNA_Solid/VEP --bind /data" \
	-s $(MAIN_SMK) \
	$(ARGS)

## create_inputs: Create input metadata files based on files residing in a given fastq-file directory
create_inputs:
	$(CONDA_ACTIVATE)
	hydra-genetics create-input-files \
	-d $(FASTQ_INPUT_DIR) \
	--force

## update_env: Update conda environment to the latest version defined by env.yml file
update_env:
	$(ACTIVATE_CONDA)
	mamba env update --file env.yml

## hydra_help: Produce help message for hydra-genetics utility
hydra_help:
	$(CONDA_ACTIVATE)
	hydra-genetics create-input-files --help

## clean: Remove all the latest results
clean:
	rm --verbose --recursive --force $(RESULTS)

## report: Make snakemake report
report:
	$(CONDA_ACTIVATE)
	snakemake -j 1 --report $(REPORT) -s $(MAIN_SMK)

## collection: Collect all results from the last run into own directory
collection:
	mkdir -p $(RESULTS_DIR)
	cp $(SAMPLE_DATA) $(RESULTS_DIR)
	mv $(RESULTS) $(RESULTS_DIR)

## archive: Move to larger storage location and create a symbolic link to it
archive:
	mkdir -p $(STORAGE)
	mv --verbose $(RESULTS_DIR) $(STORAGE)

## help: Show this message
help:
	@grep '^##' ./Makefile
