# Start from a base R image
FROM rocker/r-ver:4.4.1

# Install system dependencies for R and Python packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libharfbuzz-dev \
        libfribidi-dev \
        libfontconfig1-dev \
        wget \
        curl \
        git \
        libpng-dev \
        libxml2-dev \
        libssl-dev \
        libcurl4-openssl-dev \
        python3-pip \
        python3-venv \
        build-essential \
        && rm -rf /var/lib/apt/lists/*

# Install Quarto CLI
RUN wget -qO- https://quarto.org/download/latest/quarto-linux-amd64.deb > /tmp/quarto.deb && \
    dpkg -i /tmp/quarto.deb && \
    rm /tmp/quarto.deb

# Install Miniconda (for Python/Conda envs)
ENV CONDA_DIR=/opt/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p $CONDA_DIR && \
    rm /tmp/miniconda.sh
ENV PATH=$CONDA_DIR/bin:$PATH

# Copy environment files and source code
WORKDIR /workspace
COPY . /workspace

# Create the conda environment
RUN conda env create -f environment.yaml

# Activate the conda environment and set as the Python path
RUN echo "conda activate des-rap-book" >> ~/.bashrc
ENV PATH=/opt/conda/envs/des-rap-book/bin:$PATH

# Install renv and restore R packages
RUN Rscript -e "install.packages('renv', repos='https://cloud.r-project.org')" \
    && Rscript -e "renv::restore()"

# Set conda environment as default for reticulate
ENV RETICULATE_PYTHON=/opt/conda/envs/des-rap-book/bin/python

# Default command: render the book
CMD ["/bin/bash", "-c", "source activate des-rap-book && quarto render"]
