FROM ubuntu:18.04
LABEL Chosen Obih
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y g++ \
		build-essential \
		make \
		git \
		unzip \
		libcurl4 \
		libcurl4-openssl-dev \
		libssl-dev \
		libncurses5-dev \
		libsodium-dev \
		libmariadb-client-lgpl-dev \
		libssl-dev \
		zlib1g-dev \
		openssl \
		lbzip2 \
		bzip2 \
		perl \
		wget \
		curl \
		bcftools \
		python-matplotlib \
		python-numpy \
        	python3-pandas \
                python3 \
                python3-pip

# Install Biopython
RUN pip3 install biopython

# Downlaod and install conda
RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-py39_23.11.0-2-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh
ENV PATH /opt/conda/bin:$PATH

# Conda channels
RUN conda config --add channels conda-forge && \
    conda config --add channels bioconda

# Conda packages
RUN conda install numpy -y && \
    conda install pandas -y && \
    conda install bedops==2.4.41 -c bioconda -y && \
    conda install bedtools==2.31.1 -c bioconda -y && \
    conda install samtools==1.19.1 -c bioconda -y && \
    conda install htslib==1.19.1 -c bioconda -y && \
    conda install last==1454-0 -c bioconda -y && \
    conda install transdecoder==5.5.0 -c bioconda -y && \
    conda install diamond==0.9.10 -c bioconda && \
    conda install matplotlib-base -c conda-forge -y && \
    conda install python -y

# Cufflinks
RUN wget -O- http://cole-trapnell-lab.github.io/cufflinks/assets/downloads/cufflinks-2.2.1.Linux_x86_64.tar.gz | tar xzvf -

ENV BINPATH /usr/bin
WORKDIR /evolinc_docker

# cpan
RUN curl -L http://cpanmin.us | perl - App::cpanminus
RUN cpanm URI/Escape.pm

RUN apt-get update && apt-get install -y \
    pkg-config \
    apt-utils \
    libpq-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    curl \
    build-essential \
    gfortran

# Install R packages using Conda
RUN conda install -c r r-RPostgreSQL r-httr

# R libraries
RUN apt-get update && apt-get upgrade -y && \
    apt-get -y install ca-certificates software-properties-common gnupg2 gnupg1 gnupg && \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && \
    gpg --export E298A3A825C0D65DFD57CBB651716619E084DAB9 | apt-key add - && \
    add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/" && \
    apt-get install -y r-base && \
    Rscript -e 'install.packages("splitstackshape", dependencies = TRUE, repos="http://cran.rstudio.com/");' && \
    # Rscript -e 'install.packages("splitstackshape", dependencies = TRUE, repos="http://cran.rstudio.com/");' && \
    Rscript -e 'install.packages("dplyr", dependencies = TRUE, repos="http://cran.rstudio.com/");' && \
    Rscript -e 'install.packages("tidyr", dependencies = TRUE, repos="http://cran.rstudio.com/");' && \
    Rscript -e 'install.packages("data.table", dependencies = TRUE, repos="http://cran.rstudio.com/");' && \
    Rscript -e 'install.packages("BiocManager", dependencies = TRUE, repos="http://cran.rstudio.com/");' && \
    Rscript -e "BiocManager::install('Biostrings')" && \
    # Rscript -e "options(repos = list(CRAN = 'https://cloud.r-project.org/')); install.packages('BiocManager')" && \
    # Rscript -e "BiocManager::install('Biostrings')" && \
    Rscript -e 'install.packages("openssl", dependencies = TRUE,  repos="http://cran.rstudio.com/")' && \
    Rscript -e 'install.packages("getopt", dependencies = TRUE, repos="http://cran.rstudio.com/");'

# Remove the existing symbolic link (if it exists), create a symbolic link to make 'python' refer to 'python3',
# And make Python 3 the default Python 
RUN rm /usr/bin/python && \
    ln -sf /usr/bin/python3 /usr/bin/python && \
    apt-get update && apt-get install -y python3 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# Uniprot database
ADD https://github.com/iPlantCollaborativeOpenSource/docker-builds/releases/download/evolinc-I/uniprot_sprot.dmnd.gz /evolinc_docker/
RUN gzip -d /evolinc_docker/uniprot_sprot.dmnd.gz

# rFAM database
ADD https://de.cyverse.org/dl/d/12EF1A2F-B9FC-456D-8CD9-9F87197CACF2/rFAM_sequences.fasta /evolinc_docker/

# CPC2
ADD CPC2-beta /evolinc_docker/CPC2-beta
WORKDIR /evolinc_docker/CPC2-beta/libs/libsvm/
RUN tar xvf libsvm-3.22.tar.gz
WORKDIR libsvm-3.22
RUN make clean && make
WORKDIR /

# Evolinc wrapper scripts
ADD *.sh *.py *.R /evolinc_docker/
RUN chmod +x /evolinc_docker/evolinc-part-I.sh && cp /evolinc_docker/evolinc-part-I.sh $BINPATH
WORKDIR /

RUN conda install gffread==0.12.1 -c bioconda -y

# Setting paths to all the softwares
ENV PATH /evolinc_docker/cufflinks-2.2.1.Linux_x86_64/:$PATH
ENV PATH /evolinc_docker/bin/:$PATH
ENV PATH /evolinc_docker/CPC2-beta/bin/:$PATH
ENV PATH /usr/bin/:$PATH
ENV PATH /evolinc_docker/:$PATH

# Entrypoint
ENTRYPOINT ["evolinc-part-I.sh"]
CMD ["-h"]
