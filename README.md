<div align="center">
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-2-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

# DES RAP Book: Reproducible Discrete-Event Simulation in Python and R

[![Python](https://img.shields.io/badge/-Python_3.9.22-a8902b?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
![R 4.4.1](https://img.shields.io/badge/-R_4.4.1-276DC2?style=for-the-badge&logo=r&logoColor=white)
![Code licence](https://img.shields.io/badge/🛡️_Code_licence-MIT-8a00c2?style=for-the-badge&labelColor=gray)
![Text licence](https://img.shields.io/badge/🛡️_Text_licence-CC--BY--SA--4.0-b100cd?style=for-the-badge&labelColor=gray)
[![ORCID](https://img.shields.io/badge/ORCID_Amy_Heather-0000--0002--6596--3479-A6CE39?style=for-the-badge&logo=orcid&logoColor=white)](https://orcid.org/0000-0002-6596-3479)
[![All Contributors](https://img.shields.io/github/all-contributors/pythonhealthdatascience/des_rap_book?color=ee8449&style=for-the-badge)](#contributors)

</div>

<br>

**DES RAP Book** is an open resource and website for building discrete-event simulation (DES) models within a **reproducible analytical pipline (RAP)**, supporting the healthcare simulation community.

The resource demonstrates practical, code-based workflows and tools to help researchers and practitioners develop, validate, and share DES models in Python (SimPy) and R (simmer), ensuring models are reproducible.

Check it out at: **https://pythonhealthdatascience.github.io/des_rap_book/**.

<br>

## Who is this for?

* **Researchers, analysts, practitioners, and students** in simulation modeling - especially those in healthcare and operations research.

* **Anyone using Python or R** who is seeking practical guidance on best practices for reproducibility, with many of the sections (e.g. environments, version control, documentation, testing) being broadly relevant to any research software and data science projects.

* **Accessible to a range of experience levels**. The material is designed to be approachable, though some familiarity with Python or R, and basic command line usage, is recommended. Prior experience with simulation modeling is also helpful.

<br>

## What's covered?

* **Getting started:** introduction to reproducibility and open-source.

* **Building models:** Structured guidance on model inputs, implementation, experimentation, and analysis with clear, reproducible code examples in Python and R. This includes recommendations for experimentation, output analysis, and verification and validation.

* **Best practices:** Code packaging, environment management, version control, linting, testing, and documentation for robust and transparent workflows.

* **Reporting and collaboration:** Generating tables/figures, licensing, sharing, peer review, archiving, citation, and changelogs.

<br>

## Getting started/Navigation

* Visit the [DES RAP Book website](https://pythonhealthdatascience.github.io/des_rap_book/) for all tutorials and resources (also viewable locally as described below).

* The example model repositories linked from the book are:
    * [Python M/M/s example](https://github.com/pythonhealthdatascience/pydesrap_mms)
    * [Python stroke example](https://github.com/pythonhealthdatascience/pydesrap_stroke)
    * [R M/M/s example](https://github.com/pythonhealthdatascience/rdesrap_mms)
    * [R stroke example](https://github.com/pythonhealthdatascience/rdesrap_stroke)

<br>

## STARS

This resource has been developed as part of the project **STARS: Sharing Tools and Artefacts for Reproducible Simulations in healthcare**.

![](images/stars_banner.png)

The project tackles the challenges of sharing, reusing, and reproducing discrete event simulation (DES) models in healthcare. Our goal is to create open resources using the two most popular open-source languages for DES: Python and R.

We have been developing tutorials, code examples, and tools to help researchers and practitioners develop, validate, and share DES models more effectively.

For more information on this project, check out the [STARS page](https://pythonhealthdatascience.github.io/des_rap_book/pages/project/stars.html) in the DES RAP Book.

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

You can also cite the archived version of this work on Zenodo: https://doi.org/10.5281/zenodo.17094155.

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

## Funding

This project is supported by the Medical Research Council [grant number [MR/Z503915/1](https://gtr.ukri.org/projects?ref=MR%2FZ503915%2F1)].

<br>

## Contributors

Thanks goes to all of the following people ([emoji key](https://allcontributors.org/docs/en/emoji-key)).

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/amyheather"><img src="https://avatars.githubusercontent.com/u/92166537?v=4?s=100" width="100px;" alt="Amy Heather"/><br /><sub><b>Amy Heather</b></sub></a><br /><a href="#bug-amyheather" title="Bug reports">🐛</a> <a href="#code-amyheather" title="Code">💻</a> <a href="#content-amyheather" title="Content">🖋</a> <a href="#doc-amyheather" title="Documentation">📖</a> <a href="#design-amyheather" title="Design">🎨</a> <a href="#ideas-amyheather" title="Ideas, Planning, & Feedback">🤔</a> <a href="#infra-amyheather" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="#tutorial-amyheather" title="Tutorials">✅</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://experts.exeter.ac.uk/19244-thomas-monks"><img src="https://avatars.githubusercontent.com/u/881493?v=4?s=100" width="100px;" alt="Tom Monks"/><br /><sub><b>Tom Monks</b></sub></a><br /><a href="#review-TomMonks" title="Reviewed Pull Requests">👀</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!

