#!/bin/bash

# Linting R code
# Note: I have used ```{r file="file.R"}``` instead of ```{r}{{< include file.R >}}```, as the latter breaks lintr
echo "Linting R code..."
Rscript -e 'lintr::lint("index.qmd")'
Rscript -e 'lintr::lint_dir("pages")'
Rscript -e 'lintr::lint_dir("tests")'

echo "------------------------------------------------------------------"

# Linting Python code in qmd files
echo "Linting Python code..."
bash pylintqmd.sh .
