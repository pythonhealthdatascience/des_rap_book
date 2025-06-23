#!/bin/bash

# Note: I have used ```{r} #| file: file.R``` instead of
# ```{r}{{< include file.R >}}```, and likewise for python, as the latter
# breaks lintr (false positive messages, and missing other messages) and breaks
# pylint (returns an error Parsing failed: 'invalid syntax'). It doesn't break
# if used in non-active code chunks as linters ignore those.

echo "Linting R code..."
Rscript -e 'lintr::lint("index.qmd")'
Rscript -e 'lintr::lint_dir("pages")'
Rscript -e 'lintr::lint_dir("tests")'

echo "------------------------------------------------------------------"

echo "Linting Python code..."

# Lint .qmd files
pylintqmd index.qmd
pylintqmd pages

# Lint .py files in tests/
pylint tests

# Lint .py files in pages/
pylint pages