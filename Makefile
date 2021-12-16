.ONESHELL:
SHELL = /bin/bash
.SHELLFLAGS := -e -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# The conda env definition file "requirements.yml" is located in the project's root directory
CURRENT_CONDA_ENV_NAME = Twist_DNA_Solid
CONDA_ACTIVATE = source $$(conda info --base)/etc/profile.d/conda.sh ; conda activate ; conda activate $(CURRENT_CONDA_ENV_NAME)

CPUS = 90
ARGS = --forceall

.PHONY: \
run \
clean \
help

REPORT = report.html

RESULTS = \
alignment \
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
RESULTS_DIR = LI_VAL_1-8

STORAGE = /data/Twist_DNA_Solid/results

MAIN_SMK = /home/lauri/Desktop/Twist_DNA_Solid/workflow/Snakefile

## run: Run the main pipeline
run:
	$(CONDA_ACTIVATE)
	snakemake --cores $(CPUS) --use-singularity --singularity-args "--bind /home/lauri/ --bind /data/" -s $(MAIN_SMK) $(ARGS)

## clean: Remove all the latest results
clean:
	rm -rf $(RESULTS)

## help: Show this message
help:
	@grep '^##' ./Makefile
