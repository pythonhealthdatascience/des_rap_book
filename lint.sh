#!/bin/bash

# Linting R code
echo "Linting R code..."
Rscript -e 'lintr::lint_dir(".")'

echo "------------------------------------------------------------------"

# Linting Python code in qmd files
echo "Linting Python code..."
bash pylintqmd.sh .