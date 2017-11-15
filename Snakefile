import inspect, os

__INSTALL_DIR__ = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
__PC_DIR__ = "%s/pipeline_components" % __INSTALL_DIR__

import json
dconfig = json.load(open("%s/defaults.json"% __PC_DIR__, "r"))
dconfig.update(config)


__RUN_DIR__ = os.path.abspath(dconfig["outdir"]) + "/run"
__BLAST_OUTDIR__ = "%s/blast" % __RUN_DIR__
__SCAFF_OUTDIR__ = "%s/rel_scaffolds" % __RUN_DIR__

from pipeline_components import utils

###############################################################################

rule blastDBPrep:
  input:
    genome = lambda wildcards: dconfig["data"]["genomes"][wildcards.genome]["genome"]
  output:
    genome = "%s/renamed.{genome}.fasta" % __BLAST_OUTDIR__
  shell: """
    cat "{input.genome}" \
     | sed -e 's/^>/&{wildcards.genome}|/' \
     > "{output.genome}"
  """
  

rule blastDB:
  input:
    genomes = expand("%s/renamed.{genome}.fasta" % __BLAST_OUTDIR__, genome=dconfig["data"]["genomes"].keys())
  output:
    db = "%s/blast.db" % __BLAST_OUTDIR__
  shell: """
    cat {input.genomes} > {output.db}.input
    makeblastdb -in {output.db}.input -out {output.db} -dbtype nucl
    touch {output.db}
  """

rule tblastn:
  input:
    mtl = dconfig["data"]["MTL_genes"],
    db  = rules.blastDB.output.db
  output:
    res = "%s/mtl_results.tsv"% __BLAST_OUTDIR__
  threads: 10
  shell: """
    tblastn -num_threads {threads} -query {input.mtl} -db {input.db} -outfmt 6 -out /dev/stdout \
     | sort -k1,1 -k12,12nr -k2,2nr \
     > {output.res}
  """

###############################################################################

rule relevantGenomeScaffold:
  input:
    genome = lambda wildcards: "%s/renamed.%s.fasta" % (__BLAST_OUTDIR__, wildcards.genome),
    res    = rules.tblastn.output.res
  output:
    scaff = "%s/scaff.{genome}.fasta" % __SCAFF_OUTDIR__,
    loci  = "%s/loci.{genome}.txt" % __SCAFF_OUTDIR__
  params:
    thresh = config["evalue_thresh"]
  run:
    fastaFile = input.genome # Fasta file
    blastFile = input.res # Blast results
  
    F = utils.loadFasta(fastaFile)
    B = utils.readColumnFile(blastFile, utils.blastFields, types=utils.blastFieldsType)
  
    scaffoldsSelected = []
    geneOrder = []
    for b in B:
      (genome, scaffold) = b.sseqid.split('|')

      if genome != wildcards.genome:
        continue
      #fi
  
      if float(b.evalue) > params.thresh:
        continue
      #fi
  
      scaffoldsSelected.append(b.sseqid)
      geneOrder.append( (scaffold, b.sstart, b.qseqid.split('|')[0]) )
      #print("%s, %s -> %s" % (genome, b.qseqid, scaffold))
  
    #efor
  
  
    prevScaffold = ""
    prevGene     = ""
    with open(output.loci, "w") as ofd:
      ofd.write("\n----------------\nGenome: %s\n" % wildcards.genome)
      for (scaffold, start, gene) in sorted(geneOrder, key=lambda x: (x[0], x[1])):
        if scaffold != prevScaffold:
          prevScaffold = scaffold
          ofd.write("\n")
          ofd.write("  %s: " % scaffold)
        #fi
        if prevGene != gene:
          ofd.write(" %s " % gene)
          prevGene = gene
        #fi
      #efor
      ofd.write("\n")
    #ewith

    OF = [ (seqID, F[seqID]) for seqID in set(scaffoldsSelected) ]
    utils.writeFasta(OF, output.scaff)

rule all:
  input:
    scaffs = expand("%s/scaff.{genome}.fasta" % __SCAFF_OUTDIR__, genome=config["data"]["genomes"].keys()),
    loci   = expand("%s/loci.{genome}.txt" % __SCAFF_OUTDIR__, genome=config["data"]["genomes"].keys())
  shell: """
    cat {input.loci}
  """
