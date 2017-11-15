#!/usr/bin/env python

import json
import sys
import inspect, os

import utils as utils

###############################################################################

__INSTALL_DIR__ = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))

if len(sys.argv) < 3:
  print("Error, incomplete arguments to checkInput.py")
  sys.exit(1)
#fi

configFile = sys.argv[1];
action     = sys.argv[2];

config = {}
if not(os.path.isfile(sys.argv[1])):
  errors.append("ConfigFile '%s'doesn't exist!"% sys.argv[1])
else:
  config = json.load(open(sys.argv[1],"r"))
#fi
dconfig = json.load(open("%s/defaults.json" % __INSTALL_DIR__,"r"))

###############################################################################

errors = []
warnings = []

###############################################################################
  # VALIDATE THE USER’s INPUT HERE!!!!

if "data" not in dconfig:
  errors.append("No data section in JSON file!")
else:
  if "genomes" not in config["data"]:
    errors.append("No genomes defined!")
  else:
    for genome in config["data"]["genomes"]:
      if "genome" not in config["data"]["genomes"][genome]:
        errors.append("No genome file specified for genome '%s'." % genome)
      else:
        if not(os.path.isfile(config["data"]["genomes"][genome]["genome"])):
          errors.append("Genome file specified for genome '%s' does not exist." % genome)
        #fi
      #fi
    #efor
  #fi

  if "MTL_genes" not in config["data"]:
   errors.append("No MTL file specified.")
  else:
    if not(os.path.isfile(config["data"]["MTL_genes"])):
      errors.append("MTL file specified does not exist.")
    #fi
  #fi
#fi

if "outdir" not in config:
  warnings.append("Outdir is not specified. Defaulting to '%s'." % dconfig["outdir"])
#fi

###############################################################################

for error in errors:
  print("ERROR: %s" % error)
#efor

for warning in warnings:
  print("WARNING: %s" % warning)
#efor


# Exit with a positive return code if we had errors
sys.exit(len(errors))

