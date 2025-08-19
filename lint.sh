#!/bin/bash

print_section() {
    echo "--------------------------------------------------------------------"
    echo "Linting $1 code ($2)..."
    echo "--------------------------------------------------------------------"
}

# Note: I have used ```{r} #| file: file.R``` instead of
# ```{r}{{< include file.R >}}```, and likewise for python, as the latter
# breaks lintr (false positive messages, and missing other messages) and breaks
# pylint (returns an error Parsing failed: 'invalid syntax'). It doesn't break
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

print_section "python" "tests/"
pylint pages tests
flake8 pages tests