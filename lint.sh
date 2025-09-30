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

pylint pages tests --ignore=linting_resources,outputs_resources,replications_resources
pylint pages/output_analysis/outputs_resources pages/output_analysis/replications_resources --disable=missing-module-docstring,undefined-variable

flake8 pages tests --exclude linting_resources,replications_resources