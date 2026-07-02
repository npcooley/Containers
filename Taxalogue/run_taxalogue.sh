#!/bin/bash

#SBATCH --job-name=taxalogue
#SBATCH --output=taxalogue_%j.log
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --time=48:00:00

###### -- overhead notes and things -------------------------------------------
# notes and things

# brief description:
# run_taxalogue.sh
# use slurm to run the taxalogue container (https://github.com/nwnoll/taxalogue)
# via apptainer

# typical invocations:
#   first run - builds the NCBI/GBIF taxonomy database (~2hr, only needed once
#   per taxalogue_data directory):
#     sbatch <this_script.sh> docker://npcooley/taxalogue:0.0.1
#
#   subsequent runs - anything after the container reference is taxalogue's
#   own argv, passed through untouched. see 'apptainer exec <container>
#   bundle _2.4.10_ exec ruby taxalogue.rb --help' for the full syntax:
#     sbatch <this_script.sh> docker://npcooley/taxalogue:0.0.1 --taxon Arthropoda download --gbol --midori

# notes:
# - the taxonomy database, downloads, and results all persist in
#   ${HOME}/taxalogue_data across separate job submissions - only the first
#   run (or the first run after starting from an empty taxalogue_data
#   directory) pays the ~2 hour taxonomy import cost.
# - the `download`/`setup` subcommands need outbound internet access from
#   the compute node (BOLD/GenBank/GBOL/NCBI/GBIF). if this cluster's
#   compute nodes are firewalled off from the internet, this script will
#   hang or fail at that step - confirm with your cluster admins first.
# - notes cannot be placed above the #SBATCH block.
# - this script intentionally does NOT use `set -e` (see below).

# dependencies / requirements:
# Environment Modules or Lmod .. https://modules.readthedocs.io/en/latest/
# apptainer ..................... https://apptainer.org/docs/user/latest/
# slurm ......................... https://slurm.schedmd.com/sbatch.html
# taxalogue ..................... https://github.com/nwnoll/taxalogue

# a note on `set -e`:
# container_init_RHSwL.sh deliberately checks `$?` by hand after each
# meaningful command instead of using `set -e`. That turns out to matter
# here too: under `set -e`, a bare function call (like load_target_module
# below) or a `var=$(cmd)` assignment that fails triggers an IMMEDIATE
# script exit, bypassing any `if [ $? -ne 0 ]` handling written after it -
# the error message and cleanup you wrote never run. Manual checking, as
# below, is the more reliable pattern for this structure. `pipefail` is
# kept on since it doesn't have this problem and makes pipeline exit codes
# meaningful for the manual checks that follow them.
set -uo pipefail

###### -- clean up and trap ---------------------------------------------------

cleanup() {
  echo "cleaning up temporary files..."
  rm -f "${mod_avl_tmp:-}"
  echo "done"
}
trap cleanup EXIT SIGTERM SIGINT

###### -- user args -----------------------------------------------------------

container_name=${1:-""}

if [ -z "${container_name}" ]; then
  echo "======"
  echo "container reference is *required* as the first argument, e.g.:"
  echo "  sbatch ${0} docker://npcooley/taxalogue:0.0.1"
  echo "  sbatch ${0} docker://npcooley/taxalogue:0.0.1 --taxon Arthropoda download --gbol --midori"
  echo "======"
  exit 1
fi

# should drop the first arg from the ingested positional arguments
shift

# everything after the container reference is taxalogue's own argv. if
# nothing further was supplied, default to the one-time taxonomy setup.
# this deliberately calls the specific setup flags rather than
# --reset_taxonomies, which prompts for interactive Y/n confirmation and
# would hang forever in a non-interactive SLURM job.
if [ $# -eq 0 ]; then
  echo "======"
  echo "no taxalogue arguments supplied; running the one-time taxonomy setup"
  echo "(setup --ncbi_taxonomy --gbif_taxonomy --gbif_homonyms)."
  echo "this can take close to two hours the first time."
  echo "======"
  TAXALOGUE_ARGS=(setup --ncbi_taxonomy --gbif_taxonomy --gbif_homonyms)
else
  TAXALOGUE_ARGS=("$@")
fi

echo "taxalogue arguments for this run: ${TAXALOGUE_ARGS[*]}"

###### -- other functions for this script -------------------------------------

# accept a keyword pattern and a file listing available modules (one per
# line), and load the most recent matching version. mirrors the helper in
# container_init_RHSwL.sh, trimmed down since this script only needs to
# resolve apptainer (taxalogue has no GPU/CUDA requirement).
load_target_module() {
  local curr_modules=$1
  local default_pattern=$2
  local pattern_hit

  # `|| true` matters under `pipefail`: if grep finds nothing, the pipeline
  # exits non-zero, which would otherwise make this assignment itself
  # report failure before we ever get to check whether pattern_hit is set.
  pattern_hit=$(grep -oE "${default_pattern}" "${curr_modules}" | sort -V | tail -1) || true

  if [ -n "${pattern_hit}" ]; then
    echo "  ======"
    echo "  ${pattern_hit} was found matching a default pattern and will be loaded!"
    echo "  ======"
    module load "${pattern_hit}"
    return $?
  else
    echo "  ======"
    echo "  the pattern '${default_pattern}' failed to return any hits, please check 'module avail'!"
    echo "  ======"
    return 1
  fi
}

###### -- module loading -------------------------------------------------------

# only apptainer, and we probably don't need to specify a version...
mod_avl_tmp=$(mktemp)
module avail 2>&1 | tr ' ' '\n' | grep -v '^$' > "${mod_avl_tmp}"

load_target_module "${mod_avl_tmp}" "apptainer/[0-9]+\.[0-9]+\.[0-9]+"
if [ $? -ne 0 ]; then
  echo "======"
  echo "failed to load an appropriate apptainer module"
  echo "======"
  exit 1
fi

if command -v apptainer >/dev/null 2>&1; then
  CONTAINER_CMD="apptainer"
elif command -v singularity >/dev/null 2>&1; then
  CONTAINER_CMD="singularity"
else
  echo "======"
  echo "neither apptainer nor singularity is available even after module load"
  echo "======"
  exit 1
fi
echo "======"
echo "using container runtime: ${CONTAINER_CMD} ($(${CONTAINER_CMD} --version))"
echo "======"

###### -- persistent data paths and apptainer bind args ------------------------

# taxalogue.rb uses relative paths internally (`require './.requirements'`,
# `.db/database.db`, `base_dir: 'results'`), so it must be run with its
# working directory set to the container's install root (/opt/taxalogue),
# and persistent state must be bind-mounted onto the exact paths it expects
# there - see the Dockerfile comments for how those paths were confirmed.
DB_DIR="${HOME}/taxalogue_data/db"                 # NCBI/GBIF taxonomy database + its config
DOWNLOADS_DIR="${HOME}/taxalogue_data/downloads"   # raw downloaded sequence data
RESULTS_DIR="${HOME}/taxalogue_data/results"       # final output files
 
mkdir -p "${DB_DIR}" "${DOWNLOADS_DIR}" "${RESULTS_DIR}"
if [ $? -ne 0 ]; then
  echo "======"
  echo "failed to create ${HOME}/taxalogue_data subdirectories"
  echo "======"
  exit 1
fi


# SQLite needs to create journal/WAL files *alongside* database.db during
# writes, so the whole .db directory needs to be writable - binding only
# database.db itself (a prior version of this script did that) leaves the
# containing directory part of the read-only SIF image, and every write
# fails with "attempt to write a readonly database".
#
# The .db directory ships more than one file inside the image though - at
# least database.yaml and database_schema.rb are both committed to the repo
# (only database.db itself is gitignored/runtime-generated - see the
# Dockerfile comments). Seeding just the one filename we happened to know
# about (an earlier version of this script did that) meant the bind mount
# hid every *other* shipped file, breaking taxalogue with a LoadError the
# first time it needed one we hadn't copied. So rather than naming files
# individually, tar up and extract the whole directory tree once, the same
# "read from the container, cache on host" idea container_init_RHSwL.sh
# uses for rstudio-prefs.json, just generalized to a full directory.
if [ -z "$(ls -A "${DB_DIR}" 2>/dev/null)" ]; then
  echo "======"
  echo "seeding ${DB_DIR} from the container image's .db directory (first run only)"
  echo "======"
  apptainer exec "${container_name}" tar -C /opt/taxalogue -cf - .db \
    | tar -C "${DB_DIR}" --strip-components=1 -xf -
  if [ $? -ne 0 ] || [ -z "$(ls -A "${DB_DIR}" 2>/dev/null)" ]; then
    echo "======"
    echo "failed to extract the .db directory from the container image"
    echo "======"
    exit 1
  fi
  echo "seeded files:"
  ls -A "${DB_DIR}"
fi

# building this as a single APPTAINER_BIND variable
# rather than repeating --bind flags on the
# apptainer call below. only database.db is bound (a specific file, not the
# whole .db directory) so the image's shipped .db/database.yaml config
# stays visible rather than being hidden underneath a directory bind.
export APPTAINER_BIND="\
${DB_DIR}:/opt/taxalogue/.db,\
${DOWNLOADS_DIR}:/opt/taxalogue/downloads,\
${RESULTS_DIR}:/opt/taxalogue/results"

###### -- call apptainer --------------------------------------------------------

echo "======"
echo "container:  ${container_name}"
echo "starting taxalogue at $(date)"
echo "======"

apptainer exec --cleanenv \
  --pwd /opt/taxalogue \
  "${container_name}" \
  bundle _2.4.10_ exec ruby taxalogue.rb \
    "${TAXALOGUE_ARGS[@]}"

taxalogue_exit=$?

if [ ${taxalogue_exit} -ne 0 ]; then
  echo "======"
  echo "taxalogue exited with a non-zero status: ${taxalogue_exit}"
  echo "======"
  exit ${taxalogue_exit}
fi

echo "======"
echo "taxalogue finished successfully at $(date)"
echo "======"
