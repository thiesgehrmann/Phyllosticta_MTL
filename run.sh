#!/usr/bin/env bash

# Make sure that we know where the Snakefile is!
SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

action="all"
sm_params=""
validate=0
sm_file="$SCRIPTDIR/Snakefile"
threads=10

###############################################################################

function usage() {
  echo "Pipeline to identify Mating Type Loci in fungal strains"
  echo ""
  echo " run.sh [options] <configFile.json>"
  echo ""
  echo "Options:"
  echo " -a <action>: Action to perform. Default $action"
  echo " -s <str>: Additional arguments to snakemake"
  echo " -t <int>: Number of cores to use. Default $threads"
  echo " -v: Only validate input, don't run pipeline"
  echo " -h: Print this help screen"
  echo ""
}

###############################################################################


# Parse the arguments to the pipeline
while getopts ":a:s:t:vh" opt; do
  case $opt in
    s)
      sm_params="$OPTARG"
      ;;
    a)
      action="$OPTARG"
      ;;

    v)
      validate=1
      ;;
    t)
     threads="$OPTARG"
     ;;
    h)
      usage
      exit 0
      ;;
    \?)
      echo "Invalid option: $OPTARG" >&2
      usage
      exit 1
      ;;
    :)
      echo "Missing argument for option $OPTARG"
      usage
      exit 1
      ;;
  esac
done


# Skip through the other parameters to be left with the JSON file that the user provides
for i in `seq $((OPTIND-1))`; do
  shift
done
configfile=$1


# Check if the users JSON file exists
if [ ! -e "$configfile" ]; then
  echo "Error: configFile missing"
  usage
  exit 1
fi


# If it does, then validate the input
$SCRIPTDIR/pipeline_components/check_input.py "$configfile" "$action"
checkres=$?
if [ ! $checkres -eq 0 ]; then
  exit $checkres
fi


###############################################################################


# If everything is ok, then run the pipeline
if [ $validate -eq 0 ]; then
  snakemake --snakefile "$sm_file" \
            --cores "$threads" \
            --use-conda \
            --configfile "$configfile" \
            --conda-prefix "$SCRIPTDIR/.snakemake/conda" \
            $sm_params $action
fi

