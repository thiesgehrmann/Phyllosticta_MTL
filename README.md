# Phyllosticta_MTL
Analysis of Phyllosticta mating type loci

Identifiers fragments of MTLs, reconstructs the order on each scaffold, and selects out the scaffolds to put into another tool, such as [SimpleSynteny](https://www.dveltri.com/simplesynteny/).

## Dependencies

 * Snakemake
 * BLAST (specifically tblastn)

## Analysis

To run the analysis:

    ./run.sh example/config.json
