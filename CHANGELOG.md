# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Dates formatted as YYYY-MM-DD as per [ISO standard](https://www.iso.org/iso-8601-date-and-time-format.html).

## v0.5.0 - 2026-02-20

This release has lots and lots of changes based on peer review of the book from Nav Mustafee, Rob Challen, Tom Slater and Alison Harper. Other changes include addressing FAIRness requirements, switching R length of warm-up analysis to use intervals, and improving the docker action used to build the site.

### Added

* Addressed FAIRness requirements ([#170](https://github.com/pythonhealthdatascience/des_rap_book/issues/170)), with some larger changes including:
    * Addition of action which checks all images have alt text.
    * New "Impact" page.

### Changed

* R length of warm-up now uses intervals.
* Improved `docker_quarto.yaml` (shorter run-time as doesn't need to restore renv every time build book).
* Addressed peer review feedback from Nav Mustafee ([#149](https://github.com/pythonhealthdatascience/des_rap_book/issues/149), [#150](https://github.com/pythonhealthdatascience/des_rap_book/issues/150), [#158](https://github.com/pythonhealthdatascience/des_rap_book/issues/158), and [#161](https://github.com/pythonhealthdatascience/des_rap_book/issues/161)).
* Addressed peer review feedback from Rob Challen ([#152](https://github.com/pythonhealthdatascience/des_rap_book/issues/152) and sub-issues).
* Addressed peer review feedback from Tom Slater ([#172](https://github.com/pythonhealthdatascience/des_rap_book/issues/172) and sub-issues).
* Addressed peer review feedback from Alison Harper ([#169](https://github.com/pythonhealthdatascience/des_rap_book/issues/169) and sub-issues).
* Add all-contributors CLI instructions to `CONTRIBUTING.md`.

## v0.4.0 - 2026-01-06

### Added

* Quality assurance page.
* Date each page was last updated (based on commits to main, generated using bash script in GitHub action).

### Changed

* Addressed peer review feedback from Nav Mustafee ([#130](https://github.com/pythonhealthdatascience/des_rap_book/issues/130)).
* Addressed peer review feedback from Fatemeh Alidoost ([#134](https://github.com/pythonhealthdatascience/des_rap_book/issues/134), [#144](https://github.com/pythonhealthdatascience/des_rap_book/issues/144) and [#146](https://github.com/pythonhealthdatascience/des_rap_book/issues/146)).
* Restructured the website so it has a homepage, a dedicated section with step-by-step tutorial, but then separate sections with background information. Now has top navbar with banner, for hopefully more professional appearance and easier navigation.

## v0.3.0 - 2025-11-06

This release adds new pages on the mathematical proof of correctness, discrete-event simulation, and conclusions/feedback, as well as template repositories for structuring work as a package. It fixes the calculation of R time-weighted measures, updates the Python approach to determining warm-up length, and extends all pages to cover all performance metrics. Numerous smaller improvements are also included.

### Added

* Template repositories for package structure.
* Mathematical proof of correctness page.
* Discrete-event simulation introductory page.
* Conclusions page.
* Feedback page.

### Fixed

* Add correction for R time-weighted measures so last interval is included in calculations.

### Changed

* Pages following *Performance Measures* now use **all** metrics (and not just two) for Python and R.
* Changed Python approach for determining length of warm-up (previous approach unsuitable when using all metrics).
* Added patient end-time logging to all simulation model pages.
* Upgraded to `sim-tools` v1.0.0 (Python) and add `queueing` (R).

Also some minor improvements and refinements, including:

* Extra desk-check suggestions in `verification_validation.qmd`
* Removed colour variable for R sensitivity plots.
* Expanded and cross-linked stuff on guidelines in `sharing/archive.qmd` and `intro/guidelines.qmd`.
* Small corrections in README, docstrings, linting.
* Refactoring tests.
* Clarifications on R data storage, seed sequences, correlated streams, and limitations of structuring research as a package.
* Mentions of MRAN, P3M, commit pinning, `data-raw`, `pins` and `{targets}`.
* Mentioned relevant verification/validation concepts in topic pages.
* Added link to repository `renv.lock` on environment page.

## v0.2.0 - 2025-10-14

This release adds a large number of new pages. It also introduces pre-commits, contributor acknowledgements, a contributing guide, interface improvements, updated introduction boxes, and giscus comments.

### Added

* Logging page
* Output analysis section covering:
    * Initialisation bias
    * Performance measures
    * Replications
    * Parallel processing
    * Number of replications
    * Length of warm-up
* Experimentation section covering:
    * Scenario and sensivity analysis
    * Tables and figures
    * Full run
* Verification and validation section covering:
    * Verification and validation
    * Tests
* Style and documentation section covering:
    * Linting
    * Docstrings
    * GitHub actions
    * Documentation
* Collaboration and sharing section covering:
    * Code review
    * Licensing
    * Citation
    * Changelog
    * Sharing and archiving
* Add citation to footer.
* Add pre-commits.
* Add `all-contributors`.
* Add `CONTRIBUTING.md`.

### Changed

* Redid the introduction box for each page to be simpler/clearer.
* Moved giscus `comments` settings to `_quarto.yml` so can have comments on index page.
* Improvements to existing pages (citations, illustrations, links, `.lightbox`).
* Switched to consistent modern execution options syntax.

### Fixed

* Parameters from file (don't generate PDF).
* Input modelling (correct `python-content` to `r-content`).
* Add padding to bottom of side bar so can see all pages (otherwise cuts off for some reason sometimes).

## v0.1.0 - 2025-09-10

🌱 Initial release of the website (work in progress). This version introduces the website structure and the first written sections (up to *Output Analysis*).

### Added

* Project overview page (*STARS*).
* Introduction section covering:
    * Reproducibility and RAPs
    * Guidelines
    * Open-source languages
    * Example conceptual models
* Setup section covering:
    * Version control
    * Environments
    * Structuring as a package
    * Code organisation
* Model inputs section covering:
    * Input modelling
    * Input data management
    * Parameters from script
    * Parameters from file
    * Parameter validation
* Model building section covering:
    * Randomness
    * Entity generation
    * Entity processing
