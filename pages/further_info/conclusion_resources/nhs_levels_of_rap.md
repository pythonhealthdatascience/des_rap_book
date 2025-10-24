# NHS Levels of RAP Maturity Framework

The following framework has been directly copied from the RAP Community of Practice repository/website: [NHS RAP Levels of RAP Framework](https://nhsdigital.github.io/rap-community-of-practice/introduction_to_RAP/levels_of_RAP/).

This framework is maintained by the NHS RAP Community of Practice and is © 2024 Crown Copyright (NHS England), shared by them under the terms of the [Open Government 3.0 licence](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).

The specific version of the framework copied below is that from commit [2549256](https://github.com/NHSDigital/rap-community-of-practice/commit/2549256498886d6d7ea4cdb736e2a2864c8bb461) (9th September 2024).

## 🥉 Baseline

RAP fundamentals offering resilience against future change.

| Criteria | Completion | Further details |
| - | - | - |
| Data produced by code in an open-source language (e.g., Python, R, SQL). | | |
| Code is version controlled (see [Git basics](https://nhsdigital.github.io/rap-community-of-practice/training_resources/git/introduction-to-git/) and [using Git collaboratively](https://nhsdigital.github.io/rap-community-of-practice/training_resources/git/using-git-collaboratively/) guides). | | |
| Repository includes a README.md file (or equivalent) that clearly details steps a user must follow to reproduce the code (use [NHS Open Source Policy section on Readmes](https://github.com/nhsx/open-source-policy/blob/main/open-source-policy.md#b-readmes) as a guide). | | |
| Code has been [peer reviewed](https://nhsdigital.github.io/rap-community-of-practice/implementing_RAP/workflow/code-review/). | | |
| Code is [published in the open](https://nhsdigital.github.io/rap-community-of-practice/implementing_RAP/publishing_code/how-to-publish-your-code-in-the-open/) and linked to & from accompanying publication (if relevant). | | |

## 🥈 Silver

Implementing best practice by following good analytical and software engineering standards.

Meeting all of the above requirements, plus:

| Criteria | Completion | Further details |
| - | - | - |
| Outputs are produced by code with minimal manual intervention. | | |
| Code is well-documented including user guidance, explanation of code structure & methodology and [docstrings](https://nhsdigital.github.io/rap-community-of-practice/training_resources/python/python-functions/#documentation) for functions. | | |
| Code is well-organised following [standard directory format](https://nhsdigital.github.io/rap-community-of-practice/training_resources/python/project-structure-and-packaging/). | | |
| [Reusable functions](https://nhsdigital.github.io/rap-community-of-practice/training_resources/python/python-functions/) and/or classes are used where appropriate. | | |
| Code adheres to agreed coding standards (e.g PEP8, [style guide for Pyspark](https://nhsdigital.github.io/rap-community-of-practice/training_resources/pyspark/pyspark-style-guide/)). | | |
| Pipeline includes a testing framework ([unit tests](https://nhsdigital.github.io/rap-community-of-practice/training_resources/python/unit-testing/), [back tests](https://nhsdigital.github.io/rap-community-of-practice/training_resources/python/backtesting/)). | | |
| Repository includes dependency information (e.g. [requirements.txt](https://pip.pypa.io/en/stable/user_guide/#requirements-files), [PipFile](https://github.com/pypa/pipfile/blob/main/README.rst), [environment.yml](https://nhsdigital.github.io/rap-community-of-practice/training_resources/python/virtual-environments/conda/)). | | |
| [Logs](https://nhsdigital.github.io/rap-community-of-practice/training_resources/python/logging-and-error-handling/) are automatically recorded by the pipeline to ensure outputs are as expected. | | |
| Data is handled and output in a [Tidy data format](https://medium.com/@kimrodrikwa/untidy-data-a90b6e3ebe4c). | | |

## 🥇 Gold 

Analysis as a product to further elevate your analytical work and enhance its reusability to the public.

Meeting all of the above requirements, plus:

| Criteria | Completion | Further details |
| - | - | - |
| Code is fully [packaged](https://packaging.python.org/en/latest/). | | |
| Repository automatically runs tests etc. via CI/CD or a different integration/deployment tool e.g. [GitHub Actions](https://docs.github.com/en/actions). | | |
| Process runs based on event-based triggers (e.g., new data in database) or on a schedule. | | |
| Changes to the RAP are clearly signposted. E.g. a changelog in the package, releases etc. (See gov.uk info on [Semantic Versioning](https://github.com/alphagov/govuk-frontend/blob/main/docs/contributing/versioning.md)). | | |
