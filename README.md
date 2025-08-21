<div align="center">

![](images/stars_banner.png)

# DES RAP Book: Reproducible Discrete-Event Simulation in Python and R

[![Python](https://img.shields.io/badge/-Python_3.9.22-a8902b?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
![R 4.4.1](https://img.shields.io/badge/-R_4.4.1-276DC2?style=for-the-badge&logo=r&logoColor=white)
![Code licence](https://img.shields.io/badge/🛡️_Code_licence-MIT-8a00c2?style=for-the-badge&labelColor=gray)
![Text licence](https://img.shields.io/badge/🛡️_Text_licence-CC--BY--SA--4.0-b100cd?style=for-the-badge&labelColor=gray)
[![ORCID](https://img.shields.io/badge/ORCID_Amy_Heather-0000--0002--6596--3479-A6CE39?style=for-the-badge&logo=orcid&logoColor=white)](https://orcid.org/0000-0002-6596-3479)

</div>

<br>

Step-by-step guide for building simulation models as part of a reproducible analytical pipeline (RAP). Check it out at: **https://pythonhealthdatascience.github.io/des_rap_book/**.

<br>

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

## Citation

To cite this work, see the `CITATION.cff` file in this repository or use the "Cite this repository" button on GitHub.

<br>

## Linting

To lint active Python and R code:

```{.bash}
bash lint.sh
```

Note: inactive code (i.e. code that does not get run when building the book) will not be linted - though the R linter will enforce a terminal newline at the end of each `.qmd` file.

<br>

## Funding

This project is supported by the Medical Research Council [grant number [MR/Z503915/1](https://gtr.ukri.org/projects?ref=MR%2FZ503915%2F1)].