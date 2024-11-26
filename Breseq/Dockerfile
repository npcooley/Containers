FROM r-base:4.3.1

ENV BRESEQ_VERSION "0.38.3"

# OS Dependencies
# libtbb2 -- requested by bowtie2, seems to be deprecated, replaced with libtbbmalloc2
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
    python3-distutils \
    wget \
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
    bioperl \
    spades \
    pilon \
    cat-bat \
    minimap2 \
    hisat2 \
    diamond-aligner \
    mmseqs2 \
    mash && \
   apt-get -y autoclean && \
   rm -rf /var/lib/apt/lists/*
   
RUN wget https://github.com/barricklab/breseq/releases/download/v$BRESEQ_VERSION/breseq-$BRESEQ_VERSION-Linux-x86_64.tar.gz && \
  tar -xzvf breseq-$BRESEQ_VERSION-Linux-x86_64.tar.gz && \
  rm breseq-$BRESEQ_VERSION-Linux-x86_64.tar.gz

ENV PATH=$PATH:/breseq-$BRESEQ_VERSION-Linux-x86_64/bin

CMD ["bash"]
