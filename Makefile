.ONESHELL:
SHELL = /bin/bash
.SHELLFLAGS := -e -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# The conda env definition file "requirements.yml" is located in the project's root directory
CURRENT_CONDA_ENV_NAME = Twist_DNA_Solid
CONDA_ACTIVATE = source $$(conda info --base)/etc/profile.d/conda.sh ; conda activate ; conda activate $(CURRENT_CONDA_ENV_NAME)

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
filtering \
fusions \
prealignment \
qc \
results \
snv_indels \
genefuse.json \
$(REPORT)


SAMPLE_DATA = \
samples.tsv \
units.tsv

# In this directory is gathered all results when you run command make archive
FASTQ_INPUT_DIR = /data/bcl2fastq/results/GMS_560_VAL_01-40/211203_NB501689_0228_AHV3GFBGXK/Data/Intensities/BaseCalls

STORAGE = /data/Twist_DNA_Solid/results

MAIN_SMK = /home/lauri/Desktop/Twist_DNA_Solid/workflow/Snakefile

## create_inputs:
create_inputs:
	$(CONDA_ACTIVATE)
	hydra-genetics create-input-files -d $(FASTQ_INPUT_DIR)

## run: Run the main pipeline
run:
	$(CONDA_ACTIVATE)
	snakemake --cores $(CPUS) \
	--use-singularity \
	--singularity-args "--bind /home/lauri/ --bind /data/" \
	-s $(MAIN_SMK) \
	$(ARGS)

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

## archive: Move to larger storage location and create a symbolic link to it
archive:
	mkdir -p $(STORAGE)
	mv --verbose $(RESULTS_DIR) $(STORAGE)

## help: Show this message
help:
	@grep '^##' ./Makefile
