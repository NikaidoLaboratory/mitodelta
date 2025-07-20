FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    wget \
    curl \
    bash \
    unzip \
    tar \
    bzip2 \
    build-essential \
    libncurses5-dev \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    python3 \
    python3-dev \
	python3-pip \
    perl \
    r-base \
    r-base-dev \
    git \
    gcc \
    vim-common \
    libc6 \
    libc6-dev \
    make \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

RUN ln -sf /usr/bin/python3 /usr/bin/python
RUN pip3 install pysam pandas numpy

RUN wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh \
    && chmod +x ./Miniforge3-Linux-x86_64.sh \
    && ./Miniforge3-Linux-x86_64.sh -b -p /opt/miniforge \
    && rm ./Miniforge3-Linux-x86_64.sh
ENV PATH="$PATH:/opt/miniforge/bin"

RUN conda update -y -n base -c conda-forge conda \
 && conda install -y -n base -c conda-forge -c bioconda \
 last seqtk samtools bedtools ucsc-bedgraphtobigwig ucsc-fasomerecords ucsc-fasize \
 snakemake pysam pandas numpy scipy statsmodels

RUN /opt/miniforge/bin/conda init bash
CMD ["/bin/bash", "-l"]
