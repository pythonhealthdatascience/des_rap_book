FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# ============================================================
# STAGE 1: Install ALL system dependencies FIRST
# ============================================================
# This must happen before Conda to ensure R compiles against
# system libraries, not conda libraries
RUN set -eux; \
    # retry apt-get update a few times in case mirrors are mid-sync
    for i in 1 2 3; do \
      apt-get update && break; \
      echo "apt-get update failed, retrying ($i/3)..."; \
      sleep 5; \
    done; \
    apt-get install -y --no-install-recommends \
        # Basic utilities
        wget ca-certificates gnupg software-properties-common \
        dirmngr locales git \
        # R compilation dependencies
        build-essential gfortran \
        curl \
        libxml2-dev \
        libglpk-dev \
        libgmp-dev \
        libblas-dev \
        liblapack-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        libfontconfig1-dev \
        libfreetype6-dev \
        libharfbuzz-dev \
        libfribidi-dev \
        libpng-dev \
        libtiff5-dev \
        libjpeg-dev \
        # Chrome dependencies (for Kaleido/plotly)
        fonts-liberation \
        libasound2t64 \
        libatk-bridge2.0-0 \
        libatk1.0-0 \
        libatspi2.0-0 \
        libcups2 \
        libdbus-1-3 \
        libgbm1 \
        libgtk-3-0 \
        libnspr4 \
        libnss3 \
        libvulkan1 \
        libxcomposite1 \
        libxdamage1 \
        libxkbcommon0 \
        libxrandr2 \
        xdg-utils && \
    locale-gen en_GB.UTF-8 && \
    rm -rf /var/lib/apt/lists/*

# Set locale environment variables for Python and other tools
ENV LANG=en_GB.UTF-8
ENV LC_ALL=en_GB.UTF-8
ENV PYTHONIOENCODING=utf-8

# ============================================================
# STAGE 2: Install R 4.4.1 from CRAN (pinned)
# ============================================================
RUN wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | \
    gpg --dearmor -o /usr/share/keyrings/r-project.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/r-project.gpg] https://cloud.r-project.org/bin/linux/ubuntu noble-cran40/" \
        > /etc/apt/sources.list.d/r-project.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        r-base=4.4.1-1.2404.0 \
        r-base-core=4.4.1-1.2404.0 \
        r-base-dev=4.4.1-1.2404.0 \
        r-recommended=4.4.1-1.2404.0 && \
    rm -rf /var/lib/apt/lists/*

# ============================================================
# STAGE 3: Install Quarto
# ============================================================
RUN wget -qO /tmp/quarto.deb https://quarto.org/download/latest/quarto-linux-amd64.deb && \
    apt-get update && \
    apt-get install -y /tmp/quarto.deb && \
    rm /tmp/quarto.deb && \
    rm -rf /var/lib/apt/lists/*

# ============================================================
# STAGE 4: Install Google Chrome (required by Kaleido for plotly)
# ============================================================
RUN wget -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
apt-get update && \
apt-get install -y --no-install-recommends /tmp/chrome.deb && \
rm /tmp/chrome.deb && \
rm -rf /var/lib/apt/lists/*

# ============================================================
# STAGE 5: Install Miniconda (use explicit paths, not PATH)
# ============================================================
ENV CONDA_DIR=/opt/conda
RUN wget -qO /tmp/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash /tmp/miniconda.sh -b -p "$CONDA_DIR" && \
    rm /tmp/miniconda.sh

RUN $CONDA_DIR/bin/conda config --system --set always_yes yes && \
    $CONDA_DIR/bin/conda config --system --set changeps1 no

# ============================================================
# STAGE 6: Set up project and create conda environment
# ============================================================
WORKDIR /workspace
COPY . /workspace
RUN rm -f /workspace/.Renviron

# Accept Anaconda ToS for required channels (non-interactive)
RUN $CONDA_DIR/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    $CONDA_DIR/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

# Create conda environment using explicit path (NOT in PATH yet)
RUN $CONDA_DIR/bin/conda env create -f environment.yaml

# ============================================================
# STAGE 7: Install R packages WITHOUT conda in PATH
# ============================================================
# CRITICAL: R package compilation must happen with system
# libraries, NOT conda libraries in PATH
ENV RENV_PATHS_LIBRARY=/workspace/renv/library

RUN Rscript -e "install.packages(c('renv', 'pak'), repos = 'https://cloud.r-project.org')" && \
    Rscript -e "options(renv.config.pak.enabled = TRUE); renv::restore()"

# ============================================================
# STAGE 8: Activate conda environment for RUNTIME only
# ============================================================
# Now that R packages are installed, it's safe to add conda to PATH
ENV CONDA_DEFAULT_ENV=des-rap-book
ENV PATH="/opt/conda/envs/des-rap-book/bin:${PATH}"
ENV RETICULATE_PYTHON=/opt/conda/envs/des-rap-book/bin/python

RUN echo "conda activate des-rap-book" >> /root/.bashrc

CMD ["/bin/bash"]
