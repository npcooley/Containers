FROM r-base:4.4.1

# file edits on 2024 11 04
# 'docker build --no-cache -t npcooley/synextend:latest -t npcooley/synextend:1.20.0 .'
# version after the bioconductor release -- this makes more sense i think ...
# 'docker push npcooley/synextend:1.20.0'
# singularity containers may need have their paths adjusted, i.e. 'export PATH=/blast/ncbi-blast-x.y.z+/bin:$PATH'
# 'docker run -i -t --rm npcooley/synextend:1.20.0' will run image locally
# 'docker run -i -t --rm  -v ~/localdata/:/mnt/mydata/ npcooley/synextend:1.20.0' and remove once it's been closed -- use to check packages, functions, etc...

# order of operations:
# 1 -- get system packages and dependencies
# 2 -- grab base R packages
# 3 -- grab bioc packages and install from source
# 4 -- things install or compiled from tarballs
# 5 -- pip things
# 6 -- conda things
# 7 -- commented out prior pieces of prior installations

# version things:
# blast
# hmmer
# MCL
# BiocVersion
# SPADES
ENV BLAST_VERSION "2.16.0"
ENV HMMER_VERSION "3.3.2"
ENV MCL_VERSION "14-137"
ENV BIOC_VERSION "3.20"
ENV SRA_VERSION "3.0.5"

# OS Dependencies
# libtbb2 -- requested by bowtie2, seems to be deprecated, replaced with libtbbmalloc2
RUN apt-get update && \
    apt-get -y install nano \
    bash-completion \
    build-essential \
    software-properties-common \
    libgsl-dev \
    libgmp-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    openmpi-common \
    libopenmpi-dev \
    libzmq3-dev \
    curl \
    libxml2-dev \
    git \
    libboost-all-dev \
    cmake \
    python3 \
    python3-pip \
    # python3-distutils \
    # wget \
    pigz \
    ca-certificates \
    libconfig-yaml-perl \
    libwww-perl \
    psmisc \
    samtools \
    bcftools \
    bowtie2 \
    flex \
    libfl-dev \
    default-jdk \
    cwltool \
    libtbbmalloc2 \
    libglib2.0-dev \
    libglib2.0-dev-bin \
    libgirepository-2.0 \
    # libglib2.0 \
    x11-apps \
    xvfb \
    xauth \
    xfonts-base \
    libcairo2-dev \
    libxt-dev \
    libx11-dev \
    libgtk2.0-dev \
    libglpk-dev \
    libxslt-dev \
    spades \
    megahit \
    abyss \
    flye \
    canu \
    unicycler \
    pilon \
    cat-bat \
    minimap2 \
    hisat2 \
    diamond-aligner \
    mmseqs2 \
    mash && \
   apt-get -y autoclean && \
   rm -rf /var/lib/apt/lists/*
   
# R initial dependencies from CRAN
RUN install.r remotes \
   BiocManager \
   igraph \
   dendextend \
   ape \
   httr \
   stringr \
   phytools \
   phangorn \
   TreeDist \
   nlme \
   cluster \
   deSolve \
   rvest \
   Cairo \
   aricode \
   Rfast \
   data.table \
	 dplyr \
	 argparser

# Ensure correct bioc version for DECIPHER and SynExtend
RUN Rscript -e "BiocManager::install(version = '$BIOC_VERSION') ; BiocManager::install(c('DECIPHER', 'SynExtend', 'rtracklayer', 'Rsamtools'), type = 'source')"

# EDirect
RUN sh -c "$(curl -fsSL ftp://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/install-edirect.sh)" && \
   cp -r /root/edirect/ /edirect/
ENV PATH=$PATH:/edirect

# BLAST
WORKDIR /blast/
# grab BLAST tarball from NCBI
RUN wget https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/$BLAST_VERSION/ncbi-blast-$BLAST_VERSION+-x64-linux.tar.gz && \
   tar -zxvpf ncbi-blast-$BLAST_VERSION+-x64-linux.tar.gz && \
   cd / && \
   rm /blast/ncbi-blast-$BLAST_VERSION+-x64-linux.tar.gz

# PATH will need to updated on the OSG, but is present here for regular docker use...
ENV PATH=/blast/ncbi-blast-$BLAST_VERSION+/bin:$PATH

# HMMER
WORKDIR /hmmer/
RUN wget http://eddylab.org/software/hmmer/hmmer-$HMMER_VERSION.tar.gz
RUN tar -zxvf hmmer-$HMMER_VERSION.tar.gz
RUN cd hmmer-$HMMER_VERSION && \
   ./configure --prefix /hmmer/hmmer-$HMMER_VERSION && \
   make && \
   make install && \
   cd / && \
   rm /hmmer/hmmer-$HMMER_VERSION.tar.gz
   
WORKDIR /

ENV PATH=/hmmer/hmmer-$HMMER_VERSION/bin:$PATH

# SRATools
# COPY sratoolkit.$SRA_VERSION-ubuntu64.tar.gz ./sratoolkit.$SRA_VERSION-ubuntu64.tar.gz
RUN wget https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/$SRA_VERSION/sratoolkit.$SRA_VERSION-ubuntu64.tar.gz && \
  tar -xzvf sratoolkit.$SRA_VERSION-ubuntu64.tar.gz && \
  rm sratoolkit.$SRA_VERSION-ubuntu64.tar.gz

ENV PATH=$PATH:/sratoolkit.$SRA_VERSION-ubuntu64/bin

# SRA tools are weird and have an interactive setup step that needs to be circumvented
# I don't remember where this fix came from ... github maybe?
# OSG containers open in a /srv and not root this matters

RUN mkdir /root/sra-repository && \
   mkdir /root/ncbi
COPY user-settings.mkfg ./root/.ncbi/user-settings.mkfg
COPY user-settings.mkfg /root/ncbi/user-settings.mkfg
COPY user-settings.mkfg /root/.ncbi/user-settings.mkfg
COPY user-settings.mkfg /sratoolkit.$SRA_VERSION-ubuntu64/bin/ncbi/user-settings.mkfg

# ANICalculator has some weird permissions that need to be edited for use on the OSG
# without the chown commands it should work fine in a local docker container, i think...
COPY ANIcalculator_v1.tgz .
RUN tar -zxvf ANIcalculator_v1.tgz
ENV PATH=$PATH:/ANIcalculator_v1
RUN chown root:root ANIcalculator_v1 && \
  chown root:root ANIcalculator_v1/* && \
  chmod 00755 ANIcalculator_v1 && \
  chmod 00755 ANIcalculator_v1/* && \
  rm ANIcalculator_v1.tgz

# mcl's install script references $HOME, which in this container is the 
# directory /root ... this is fine for local docker jobs,
# but is not fine on the OSG when this is run as a singularity containers
# I do not know where else $HOME is referenced, but it doesn't appear to be anywhere else
# so we just change it and see what happens...
ENV HOME=/usr

RUN mkdir installmcl && \
  cd installmcl && \
  wget https://raw.githubusercontent.com/micans/mcl/main/install-this-mcl.sh -o install-this-mcl && \
  chmod u+x install-this-mcl.sh && \
  ./install-this-mcl.sh && \
  cd ..

ENV HOME=/root

ENV PATH=$PATH:/usr/local/bin

RUN git clone https://github.com/eXascaleInfolab/LFR-Benchmark_UndirWeightOvp.git && \
  cd LFR-Benchmark_UndirWeightOvp && \
  make && \
  cd ..

ENV PATH=$PATH:/LFR-Benchmark_UndirWeightOvp

RUN git clone https://github.com/pylelab/USalign.git && \
  cd USalign && \
  make && \
  cd ..

ENV PATH=$PATH:/USalign

# PIP dependencies
RUN pip3 install --break-system-packages biopython \
   plotly \
   pandas \
   numpy \
   reportlab \
   checkm-genome \
   pysam

# this is not necessarily the right choice for a container that gets passed around the OSG
# but this can be stashed and sent along as needed
# this command will tell checkM where it's DB / DBs are located:
# checkm data setRoot <checkm_data_dir>
# checkm isn't necessarily the simplest plug and play tool, see github:
# https://github.com/Ecogenomics/CheckM
# RUN wget https://data.ace.uq.edu.au/public/CheckM_databases/checkm_data_2015_01_16.tar.gz

# CONDA install
ENV CONDA_DIR /opt/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
   /bin/bash ~/miniconda.sh -b -p /opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH

# CONDA dependencies
# ncurses installed explicitly because it doesn't seem to behave correctly as a dependency
# https://stackoverflow.com/questions/72103046/libtinfo-so-6-no-version-information-available-message-using-conda-environment
RUN conda config --add channels defaults && \
   conda config --add channels bioconda && \
   conda config --add channels conda-forge && \
   conda update -n base -c defaults conda && \
   conda install -c bioconda clinker-py && \
   conda install -c bioconda fastqc


WORKDIR /

CMD ["bash"]
