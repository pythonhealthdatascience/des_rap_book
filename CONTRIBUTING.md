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

When rendering a Quarto document containing executable Python code with `reticulate`, configuration errors can occur if R is not using the same Python as your conda/mamba environment.

Whilst you can use `reticulate::use_condaenv()` on each page, this caused errors for our GitHub action - and anyway, a more robust approach is to configure which Python interpreter reticulate should use.

1. Identify the Python binary for your environment:

```
conda env list
```

For example, if you environment is at `/home/amy/mambaforge/envs/des-rap-book`, the Python binary will typically be `/home/amy/mambaforge/envs/des-rap-book/bin/python`.

2. Create a `.Renviron` file. This is not tracked by Git and is user-specific. In it, specify your Python binary and conda/mamba executable. For example:

```
RETICULATE_PYTHON=/home/amy/mambaforge/envs/des-rap-book/bin/python
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

Alternatively, you can update it from the command line. This may be preferable, as the bot will create GitHub issues that email people when they are added.

You'll need to install the [All-Contributors CLI tool](https://allcontributors.org/cli/installation/):

```
npm i -D all-contributors-cli
```

You can then run the following and select/enter relevant information when prompted:

```
npx all-contributors
```

If you want to remove specific contributions or people, edit the `.all-contributorsrc` file then run the following to regenerate the table in `README.md`. (Don't edit `README.md`, as it is just generated based on `.all-contributorsrc`).

```
npx all-contributors generate
```

<br>

## Docker

The GitHub action to build the website uses docker, as this avoids needing to install all the required Python and R packages and system dependencies with every deployment (unless there are environment changes).

If you wish to build the docker image locally to test it out, run this command from the project directory:

```{.bash}
sudo docker build -t desrapbookdocker .
```

To view your available images, run:

```{.bash}
sudo docker images
```

Open the container interactively:

```{.bash}
sudo docker run -it desrapbookdocker /bin/bash
```

Restore R environment:

```{.bash}
Rscript -e "renv::restore()"
```

Edit the conda location in `.Renviron` (if present) to `RETICULATE_CONDA=/opt/conda/bin/conda`:

```{.bash}
apt-get update && apt-get install nano
nano .Renviron
```

Build the website:

```{.bash}
quarto render
```

To close the container: `Ctrl+P` then `Ctrl+Q`.

To delete the image:

```{.bash}
sudo docker image rm -f desrapbookdocker
```

## Accessibility

You can run automated accessibility checks on the site using axe, configured via the Quarto project settings:

```{.yaml}
format:
  html:
    axe:
      output: console
```

To view any accessibility issues, preview the site (`quarto preview`), open the browser's developer tools (e.g., right click + "Inspect"), and look at the **Console** tab.

If you prefer to see a full report overlaid on the page itself while you are working on accessibility fixes, you can temporarily change the configuration to:

```{.yaml}
format:
  html:
    axe:
      output: document
```

**Note:** It does flag several quarto defaults / built-ins as problems. Things to ignore include:

* Role supports its ARIA attributed `.collapsed` (flags for any collapsed callouts).
* Ensure the contrast between foreground and background colors `figcaption` (doesn't like Quarto's default figure caption colour).

## Findability checks

To support the FAIR principles for training materials, we keep a light-weight record of how easy it is for learners to discover the DES RAP Book via web search and chatbots. This helps us see whether changes to the site or metadata (for example, adding structured metadata or registering in training registries) actually improve real-world discoverability.

If you’d like to help with this, please see `findability_checks.md`. That file explains:

- Which example queries to use.
- Where to run them (e.g. search engines, chatbots).
- How to record the results in the simple log.

You are welcome to run these checks occasionally, for example:

- After major changes to the site or its metadata.
- After registering the resource in a new training registry.
- Or just periodically (e.g. once or twice a year) as part of general maintenance.

Even occasional contributions to the findability log are helpful for tracking whether learners can still easily find the resource over time.
