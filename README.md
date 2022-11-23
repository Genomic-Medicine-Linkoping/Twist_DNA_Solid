# Twist_Solid
Pipeline for Solid tumours

Goto the wiki page for more information on how to run and configure the pipeline


# How to run in Linköping
Create the conda environment:
```
conda env create -f env.yml
conda activate Twist_Solid
conda env export --no-builds | grep -v "^prefix: " > env_LiU.yml
```

Create samples and units input files:
```
hydra-genetics create-input-files -d DATA/DNA/ -n '_R([12]{1})\.' -b ATTACTCG --force
hydra-genetics create-input-files -d DATA/RNA/ -t R -n '_R([12]{1})\.' --force
```

Generate STAR index:
```
STAR --runThreadN 8 --runMode genomeGenerate --genomeDir star_index --genomeFastaFiles Human_genome.fasta
```

Run:
```

snakemake --cores 64 --use-singularity --singularity-args "--bind /mnt/WD1/ref" -s workflow/Snakefile --configfile config/config_liu.yaml --forceall --rerun-incomplete
```

