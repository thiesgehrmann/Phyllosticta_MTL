import errno
import os
import csv
import gzip
from collections import namedtuple

###############################################################################

def loadFasta(fastaFile):

  F = {'': 0}

  current_seq = ""
  buffer_seq  = ""
  
  with (gzip.open(fastaFile, "r") if fastaFile[-2:] == "gz" else open(fastaFile, "r")) as fd:
    for line in fd:
      line = line.strip()
      if len(line) == 0:
        continue
      #fi
      if line[0] == '>':
        F[current_seq] = buffer_seq
        current_seq = line[1:].split(' ')[0]
        buffer_seq = ""
      else:
        buffer_seq = buffer_seq + line.strip()
      #fi
  #ewith
  F[current_seq] = buffer_seq
  F.pop("", None)
  return F
#edef

###############################################################################

def writeFasta(fasta, outFile, linelength=80):
  with open(outFile, "w") as ofd:
    for  (name, sequence) in fasta:
      ofd.write(">%s\n" % name)
      ofd.write("%s\n" % '\n'.join([sequence[i:i+linelength] for i in range(0, len(sequence), linelength)]))
    #efor
  #ewith
#edef

###############################################################################

blastFields = "qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore slen qlen"
blastFieldsType = "str str float int int int int int int int float float int int"

def readColumnFile(filename, columnNames, delimiter='\t', types="", skip=0):
  import csv
  L = []
  typeFunctions = { "str" : lambda x: str(x),
                    "int" : lambda x: int(x),
                    "float" : lambda x: float(x) }

  if types != "":
    types = [ typeFunctions[c] for c in types.split(" ") ]
  #fi

  nColumns = len(columnNames.split(" "))

  lineType = namedtuple("lineType", columnNames)
  skipped = 0
  with open(filename, "r") as ifd:
    reader = csv.reader(ifd, delimiter=delimiter)
    for row in reader:
      if (row[0][0] == '#') or (skipped < skip):
        skipped += 1
        continue
      #fi
      if len(types) == len(row):
        row = [ tf(v) for (tf, v) in zip(types, row) ]
      #fi
      rowLen = len(row)
      if rowLen < nColumns:
        row = [ row[i] if i < rowLen else ""  for i in range(nColumns) ]
      #fi
      L.append(lineType(*row))
    #efor
  #ewith
  return L
#edef

###############################################################################
