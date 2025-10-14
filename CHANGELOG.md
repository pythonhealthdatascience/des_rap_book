# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Dates formatted as YYYY-MM-DD as per [ISO standard](https://www.iso.org/iso-8601-date-and-time-format.html).

## v0.2.0 - 2025-10-14

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