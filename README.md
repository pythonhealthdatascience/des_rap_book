<div align="center">

# DES RAP Book: Reproducible Discrete-Event Simulation in Python and R

[![Python 3.11](https://img.shields.io/badge/-Python_3.11-a8902b?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
![R 4.4.1](https://img.shields.io/badge/-R_4.4.1-276DC2?style=for-the-badge&logo=r&logoColor=white)
![Code licence](https://img.shields.io/badge/🛡️_Code_licence-MIT-8a00c2?style=for-the-badge&labelColor=gray)
![Text licence](https://img.shields.io/badge/🛡️_Text_licence-CC--BY--SA--4.0-b100cd?style=for-the-badge&labelColor=gray)
[![ORCID](https://img.shields.io/badge/ORCID_Amy_Heather-0000--0002--6596--3479-A6CE39?style=for-the-badge&logo=orcid&logoColor=white)](https://orcid.org/0000-0002-6596-3479)
[![All Contributors](https://img.shields.io/github/all-contributors/pythonhealthdatascience/des_rap_book?color=ee8449&style=for-the-badge)](#contributors)
[![DOI](https://img.shields.io/badge/DOI-10.5281/zenodo.17094155-blue?style=for-the-badge&labelColor=gray)](https://doi.org/10.5281/zenodo.17094155)

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

* Visit the [DES RAP Book website](https://pythonhealthdatascience.github.io/des_rap_book/) for all tutorials and resources (also viewable locally as described in `CONTRIBUTING.md`).

* The example model repositories linked from the book are:
    * [Python M/M/s example](https://github.com/pythonhealthdatascience/pydesrap_mms)
    * [Python stroke example](https://github.com/pythonhealthdatascience/pydesrap_stroke)
    * [R M/M/s example](https://github.com/pythonhealthdatascience/rdesrap_mms)
    * [R stroke example](https://github.com/pythonhealthdatascience/rdesrap_stroke)

<br>

## STARS

This resource has been developed as part of the project **STARS: Sharing Tools and Artefacts for Reproducible Simulations in healthcare**.

[![](images/stars_banner.png)](https://pythonhealthdatascience.github.io/stars/)

The project tackles the challenges of sharing, reusing, and reproducing discrete event simulation (DES) models in healthcare. Our goal is to create open resources using the two most popular open-source languages for DES: Python and R.

We have been developing tutorials, code examples, and tools to help researchers and practitioners develop, validate, and share DES models more effectively.

For more information on this project, check out the [STARS project website](https://pythonhealthdatascience.github.io/stars/).

<br>

## Citation

If you this book supports your work, please **cite our paper**:

> Heather A, Monks T, Harper A et al. Reproducible analytical pipelines for healthcare discrete‑event simulation: An open guide and worked examples [version 1; peer review: awaiting peer review]. NIHR Open Res 2026, 6:68 (https://doi.org/10.3310/nihropenres.14296.1)

You may choose to also cite the software repository or archived version:

* Repository details are also provided in the `CITATION.cff` file in this repository or via the "Cite this repository" button on GitHub.
* Archived version of this work on Zenodo: https://doi.org/10.5281/zenodo.17094155.

<br>

## Accessibility

This site uses [W3C's Web Accessibility Initiative (WAI) Easy Checks](https://www.w3.org/WAI/test-evaluate/easy-checks/) as a lightweight accessibility framework. Please see this [GitHub issue](https://github.com/pythonhealthdatascience/des_rap_book/issues/188) for a record of which checks are currently met and any known limitations.

<br>

## Contributors

If you're interested in contributing (or just viewing this website locally), check out the `CONTRIBUTING.md` file.

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="25%"><a href="https://github.com/amyheather"><img src="https://avatars.githubusercontent.com/u/92166537?v=4?s=100" width="100px;" alt="Amy Heather"/><br /><sub><b>Amy Heather</b></sub></a><br /><a href="https://github.com/pythonhealthdatascience/des_rap_book/issues?q=author%3Aamyheather" title="Bug reports">🐛</a> <a href="https://github.com/pythonhealthdatascience/des_rap_book/commits?author=amyheather" title="Code">💻</a> <a href="#content-amyheather" title="Content">🖋</a> <a href="https://github.com/pythonhealthdatascience/des_rap_book/commits?author=amyheather" title="Documentation">📖</a> <a href="#design-amyheather" title="Design">🎨</a> <a href="#ideas-amyheather" title="Ideas, Planning, & Feedback">🤔</a> <a href="#infra-amyheather" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="#tutorial-amyheather" title="Tutorials">✅</a></td>
      <td align="center" valign="top" width="25%"><a href="https://experts.exeter.ac.uk/19244-thomas-monks"><img src="https://avatars.githubusercontent.com/u/881493?v=4?s=100" width="100px;" alt="Tom Monks"/><br /><sub><b>Tom Monks</b></sub></a><br /><a href="#content-TomMonks" title="Content">🖋</a> <a href="#userTesting-TomMonks" title="User Testing">📓</a></td>
      <td align="center" valign="top" width="25%"><a href="https://business-school.exeter.ac.uk/about/people/profile/index.php?web_id=Navonil_Mustafee"><img src="https://avatars.githubusercontent.com/u/59238786?v=4?s=100" width="100px;" alt="Nav Mustafee"/><br /><sub><b>Nav Mustafee</b></sub></a><br /><a href="#content-NavonilNM" title="Content">🖋</a> <a href="#userTesting-NavonilNM" title="User Testing">📓</a></td>
      <td align="center" valign="top" width="25%"><a href="https://github.com/AliHarp"><img src="https://avatars.githubusercontent.com/u/32298783?v=4?s=100" width="100px;" alt="Alison Harper "/><br /><sub><b>Alison Harper </b></sub></a><br /><a href="#content-AliHarp" title="Content">🖋</a> <a href="#userTesting-AliHarp" title="User Testing">📓</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="25%"><a href="https://github.com/Falidoost"><img src="https://avatars.githubusercontent.com/u/103049148?v=4?s=100" width="100px;" alt="Fatemeh Alidoost"/><br /><sub><b>Fatemeh Alidoost</b></sub></a><br /><a href="#content-Falidoost" title="Content">🖋</a> <a href="#userTesting-Falidoost" title="User Testing">📓</a></td>
      <td align="center" valign="top" width="25%"><a href="https://www.linkedin.com/in/robchallen"><img src="https://avatars.githubusercontent.com/u/16591648?v=4?s=100" width="100px;" alt="Rob Challen"/><br /><sub><b>Rob Challen</b></sub></a><br /><a href="#content-robchallen" title="Content">🖋</a> <a href="#userTesting-robchallen" title="User Testing">📓</a></td>
      <td align="center" valign="top" width="25%"><a href="https://github.com/tbslater"><img src="https://avatars.githubusercontent.com/u/109083824?v=4?s=100" width="100px;" alt="Tom Slater"/><br /><sub><b>Tom Slater</b></sub></a><br /><a href="#content-tbslater" title="Content">🖋</a> <a href="#userTesting-tbslater" title="User Testing">📓</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

<br>

## Funding

This project is supported by the Medical Research Council [grant number [MR/Z503915/1](https://gtr.ukri.org/projects?ref=MR%2FZ503915%2F1)] from 1st May 2024 to 31st October 2026.

It is also supported by the National Institute for Health and Care Research (NIHR) under the NIHR Applied Research Collaboration South West Peninsula (Grant Reference Number NIHR200167). The views expressed are those of the author(s) and not necessarily those of the NIHR or the Department of Health and Social Care.
