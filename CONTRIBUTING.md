# Contributing

## View locally

This website is created using Quarto and hosted on GitHub pages. You can view the site locally. With quarto installed, you will need to:

**1. Build the python environment**

```
conda env create --file environment.yaml
conda activate des-rap-book
```

**2. Build the R environment**

```
renv::init()
renv::restore()
```

**3. Create the book.**

```
quarto render
```

### Common `reticulate` error and solution

When rendering a Quarto document containing executable python code with `reticulate`, you might encounter:

```
Error in `use_condaenv()`:
! Unable to locate conda environment 'des-rap-book'.
Backtrace:
    ▆
 1. └─reticulate::use_condaenv("des-rap-book", required = TRUE)
```

This can occur when multiple Conda or Mamba installations exist (e.g. `mambgaforge`, `miniconda3`), or if R is using a different search path than the shell. By default, `reticulate` only looks in one location for environments, which can cause problems when environments are not where `reticulate` expects.

To fix this, **set the `RETICULATE_CONDA` environment variable** to the correct Conda or Mamba executable. To find the path to your executable, run:

```
conda env list
```

Look for your environment in the list. For example, if your environment is at `/home/amy/mambaforge/envs/des-rap-book`, then your Conda executable is likely at `/home/amy/mambaforge/bin/conda`.

Set the environment variable like so:

```
export RETICULATE_CONDA=/home/amy/mambaforge/bin/conda
```

Now render your book:

```
quarto render
```

To avoid needing to set `RETICULATE_CONDA` every time you open a new terminal, add the export command to an `.Renviron` file in your project directory. This file is not tracked by Git, and is specific to you. Create the file and add:

```
RETICULATE_CONDA=/home/amy/mambaforge/bin/conda
```

<br>

## Linting

To lint active Python and R code:

```{.bash}
bash lint.sh
```

Note: inactive code (i.e. code that does not get run when building the book) will not be linted - though the R linter will enforce a terminal newline at the end of each `.qmd` file.

<br>

## Pre-commit

To activate the pre-commit hook...

1. Make the bash script executable - from command line, run:

```{.bash}
chmod +x .pre-commit-hooks/check-no-quarto-r-include.sh
```

2. Run the following from your python environment on the command line:

```{.python}
pre-commit install
```

<br>

## Contributors

If your name or contributions are missing from the README, or if you contributed in ways not captured by the current role emojis, please create an issue and use: 

```
@all-contributors please add @githubuser for ...
```

Then list appropriate contribution types from [allcontributors.org/docs/en/emoji-key](https://allcontributors.org/docs/en/emoji-key) (e.g., code, review, doc, content, bug, ideas, infra).