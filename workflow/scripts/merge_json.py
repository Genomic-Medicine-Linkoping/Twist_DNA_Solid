from collections import defaultdict
import cyvcf2
import json


def parse_fai(filename, skip=None):
    with open(filename) as f:
        for line in f:
            chrom, length = line.strip().split()[:2]
            if skip is not None and chrom in skip:
                continue
            yield chrom, int(length)


def parse_annotation_bed(filename, skip=None):
    with open(filename) as f:
        for line in f:
            chrom, start, end, name = line.strip().split()[:4]
            if skip is not None and chrom in skip:
                continue
            yield chrom, int(start), int(end), name


def get_vaf(vcf_filename, skip=None):
    vcf = cyvcf2.VCF(vcf_filename)
    for variant in vcf:
        if skip is not None and variant.CHROM in skip:
            continue
        yield variant.CHROM, variant.POS, variant.INFO.get("AF", None)


def get_svdb_cnvs(vcf_filename, skip=None):
    cnvs = defaultdict(list)
    vcf = cyvcf2.VCF(vcf_filename)
    for variant in vcf:
        if skip is not None and variant.CHROM in skip:
            continue
        caller = variant.INFO.get("CALLER")
        genes = variant.INFO.get("Genes")
        if genes is None:
            continue
        cnvs[caller].append(
            dict(
                chromosome=variant.CHROM,
                genes=sorted(genes.split(",")),
                start=variant.POS,
                length=variant.INFO.get("SVLEN"),
                type=variant.INFO.get("SVTYPE"),
                copy_number=variant.INFO.get("CORR_CN"),
            )
        )
    return cnvs


def merge_cnv_dicts(dicts, vaf, annotations, chromosomes, svdb_cnvs):
    callers = list(map(lambda x: x["caller"], dicts))
    caller_labels = dict(
        cnvkit="cnvkit",
        gatk="GATK",
    )
    cnvs = {}
    for chrom, chrom_length in chromosomes:
        cnvs[chrom] = dict(
            chromosome=chrom,
            label=chrom,
            length=chrom_length,
            vaf=[],
            annotations=[],
            callers={c: dict(name=c, label=caller_labels.get(c, c), ratios=[], segments=[], cnvs=[]) for c in callers},
        )

    for a in annotations:
        for item in a:
            cnvs[item[0]]["annotations"].append(
                dict(
                    start=item[1],
                    end=item[2],
                    name=item[3],
                )
            )

    for v in vaf:
        cnvs[v[0]]["vaf"].append(
            dict(
                pos=v[1],
                vaf=v[2],
            )
        )

    for d in svdb_cnvs:
        for caller, cnv_list in d.items():
            for c in cnv_list:
                cnvs[c["chromosome"]]["callers"][caller]["cnvs"].append(
                    dict(
                        genes=c["genes"],
                        start=c["start"],
                        length=c["length"],
                        type=c["type"],
                        cn=c["copy_number"],
                    )
                )

    for d in dicts:
        for r in d["ratios"]:
            cnvs[r["chromosome"]]["callers"][d["caller"]]["ratios"].append(
                dict(
                    start=r["start"],
                    end=r["end"],
                    log2=r["log2"],
                )
            )
        for s in d["segments"]:
            cnvs[s["chromosome"]]["callers"][d["caller"]]["segments"].append(
                dict(
                    start=s["start"],
                    end=s["end"],
                    log2=s["log2"],
                )
            )

    for v in cnvs.values():
        v["callers"] = list(v["callers"].values())

    return list(cnvs.values())


def main():
    annotation_beds = snakemake.input["annotation_bed"]
    fasta_index_file = snakemake.input["fai"]
    germline_vcf = snakemake.input["germline_vcf"]
    json_files = snakemake.input["json"]
    svdb_vcf_files = snakemake.input["svdb_vcfs"]

    output_file = snakemake.output["json"]

    skip_chromosomes = snakemake.params["skip_chromosomes"]

    cnv_dicts = []
    for fname in json_files:
        with open(fname) as f:
            cnv_dicts.append(json.load(f))

    fai = parse_fai(fasta_index_file, skip_chromosomes)
    vaf = get_vaf(germline_vcf)
    annotations = []
    for filename in annotation_beds:
        annotations.append(parse_annotation_bed(filename, skip_chromosomes))

    svdb_cnvs = []
    for filename in svdb_vcf_files:
        # Parse VCF file and get annotated, called CNVs. If there are none,
        # create an empty list for each caller. In this case, no table will
        # be presented in the final report.
        svdb_cnvs.append(get_svdb_cnvs(filename, skip_chromosomes))

    cnvs = merge_cnv_dicts(cnv_dicts, vaf, annotations, fai, svdb_cnvs)

    with open(output_file, "w") as f:
        print(json.dumps(cnvs), file=f)


if __name__ == "__main__":
    main()