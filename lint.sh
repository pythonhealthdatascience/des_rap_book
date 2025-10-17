#!/bin/bash

print_section() {
    echo "--------------------------------------------------------------------"
    echo "Linting $1 code ($2)..."
    echo "--------------------------------------------------------------------"
}

# Note: For R, I have used ```{r} #| file: file.R``` instead of
# ```{r}{{< include file.R >}}```, as the latter breaks lintr (false positive
# messages, and missing other messages) and breaks. It doesn't break
# if used in non-active code chunks as linters ignore those.

print_section "R" "index.qmd"
Rscript -e 'lintr::lint("index.qmd")'

print_section "R" "pages/"
Rscript -e 'lintr::lint_dir("pages")'

print_section "R" "tests/"
Rscript -e 'lintr::lint_dir("tests")'

echo "--------------------------------------------------------------------"

print_section "python" "index.qmd and pages/"
lintquarto -l pylint flake8 -p index.qmd pages/

print_section "python" "pages/ and tests/"

echo "============================================================="
echo "Running pylint..."
echo "============================================================="
IGNORE_LIST=(
  linting_resources
  outputs_resources
  replications_resources
  parallel_resources
  tests_resources
)

RESOURCE_PATHS=(
  pages/output_analysis/outputs_resources
  pages/output_analysis/replications_resources
  pages/output_analysis/parallel_resources
  pages/verification_validation/tests_resources
)
# Lint all, skipping ignores
pylint pages tests --ignore=$(IFS=,; echo "${IGNORE_LIST[*]}")
# Lint resource-specific paths with disables
pylint "${RESOURCE_PATHS[@]}" --disable=missing-module-docstring,undefined-variable

echo "============================================================="
echo "Running flake8..."
echo "============================================================="
flake8 pages tests --exclude linting_resources,replications_resources