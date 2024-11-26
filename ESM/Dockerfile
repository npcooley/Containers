FROM r-base:4.4.0

# 'docker build --no-cache -t npcooley/esm:0.0.1 .'

ENV BIOC_VERSION "3.19"

RUN apt-get update && \
   apt-get -y install nano \
    bash-completion \
    build-essential \
    software-properties-common \
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
    python3-setuptools \
    wget \
    pigz \
    ca-certificates \
    libconfig-yaml-perl \
    libwww-perl \
    psmisc \
    flex \
    libfl-dev \
    default-jdk \
    cwltool && \
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
   torch \
   reticulate

# grab torch dependencies
RUN Rscript -e "torch::install_torch()"

# Ensure correct bioc version for DECIPHER and SynExtend
RUN Rscript -e "BiocManager::install(version = '$BIOC_VERSION') ; BiocManager::install(c('DECIPHER', 'SynExtend', 'rtracklayer', 'Rsamtools'), type = 'source')"


# CONDA install
ENV CONDA_DIR /opt/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
   /bin/bash ~/miniconda.sh -b -p /opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH

RUN pip install esm

ENTRYPOINT ["bash"]
