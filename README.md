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

[![](images/website_click.png)](https://pythonhealthdatascience.github.io/des_rap_book/)

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

<br>

## Citation

To cite this work, see the `CITATION.cff` file in this repository or use the "Cite this repository" button on GitHub.