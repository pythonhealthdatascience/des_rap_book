#!/bin/bash

# Linting R code
echo "------------------------------------------------------------------"
echo "Linting R code..."
Rscript -e 'lintr::lint_dir(".")'
echo "------------------------------------------------------------------"

# Linting Python code in qmd files
echo "------------------------------------------------------------------"
echo "Linting Python code..."
find . -type f -name "*.qmd" -print0 | while IFS= read -r -d '' file; do
    bash pylintqmd.sh "${file%.qmd}"
echo "------------------------------------------------------------------"
done