# SynExtend Container

A container for using the R package SynExtend on the open science grid. The current SynExtend version is `1.14.0`, and the several additional bioinformatics tools are included as well. With this current update, the container versioning has been edited to match the Bioconductor version.

## Usage

This container is built to be a toolbox for working with genomic data in R on the Open Science Grid. It's current major package list includes:

* DECIPHER
* SynExtend
* dendextend
* ape
* igraph
* Samtools
* SRAToolkit
* SPAdes
* Unicycler
* Megahit
* SKESA
* bowtie2
* TreeDist
* deSolve
* Flye
* Canu
* Mash
* CWL

It contains several additional R packages as well as many required dependencies. BLAST, HMMER, and MCL are included as well, and their executables have been added to the default PATH. This container also has the NCBI EDirect tools, though users will need to supply their own API key. The read simulator tools pbsim and ART have also been recently added. This container is currently built from `r-base:4.3.1`.

Versions:
1. BLAST `2.14.0`
2. HMMER `3.3.2`
3. MCL `22-282`
4. Bioconductor `3.18`
5. SRAToolkit `3.0.5`

Details on SynExtend can be found [here](http://bioconductor.org/packages/release/bioc/html/SynExtend.html), and details on DECIPHER can be found [here](https://www.bioconductor.org/packages/release/bioc/html/DECIPHER.html).

This container can be tested and used locally with `docker pull npcooley/synextend:1.18.0` and `docker run -i -t --rm npcooley/synextend sh`. The container hypothetically supports plotting to the local display from `R`, but this functionality has only been tested on macOS, the localhost must be enabled with `xhost`. This can be done with `xhost +${HOSTNAME}`, and the display specified in the call to docker with `docker run -it --rm -e DISPLAY=${HOSTNAME}:0 npcooley/synextend:1.18.0 sh`. If these instructions work, in R `capabilities()["X11"]` should return `TRUE`. This feature currently isn't the most stable, but does allow for interactive plotting.

This container can be used as a singularity container on the Open Science Grid by specifying:

`+SingularityImage = "/cvmfs/singularity.opensciencegrid.org/npcooley/synextend:1.18.0"`

in your submit file.

If an installed tool is not working as expected, explicitly add the executable to the path with `export`:

* `export PATH=$PATH:/path/to/your/executable`

in your wrapper script.

## Contact

Nicholas Cooley
npc19@pitt.edu






