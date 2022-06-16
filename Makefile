.ONESHELL:
SHELL = /bin/bash
.SHELLFLAGS := -e -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# The conda env definition file "requirements.yml" is located in the project's root directory
CURRENT_CONDA_ENV_NAME = Twist_DNA_Solid
ACTIVATE_CONDA = source $$(conda info --base)/etc/profile.d/conda.sh
CONDA_ACTIVATE = $(ACTIVATE_CONDA) ; conda activate ; conda activate $(CURRENT_CONDA_ENV_NAME)

CPUS = 92
ARGS = --forceall

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
logs \
genefuse.json \
# $(REPORT)


SAMPLE_DATA = \
samples.tsv \
units.tsv

DIR = BC27
RESULTS_DIR = $(DIR)

FASTQ_INPUT_DIR = /data/PDM-MBC/samples
STORAGE = /archive/pgx/results

MAIN_SMK = workflow/Snakefile

## run: Run the main pipeline
run:
	$(CONDA_ACTIVATE)
	export SINGULARITY_LOCALCACHEDIR=/data/Twist_DNA_Solid/cache_dir
	snakemake --cores $(CPUS) \
	--use-singularity \
	--singularity-args "--bind /data/ --bind /data/Twist_Solid/DNA/SVBD/" \
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
	mv $(RESULTS) $(RESULTS_DIR)
	cp $(SAMPLE_DATA) $(RESULTS_DIR)
	cp Makefile $(RESULTS_DIR)

## archive: Move to larger storage location and create a symbolic link to it
archive:
	mkdir -p $(STORAGE)
	mv --verbose $(RESULTS_DIR) $(STORAGE)

## help: Show this message
help:
	@grep '^##' ./Makefile
