<!--
When a Quarto document contains R and Python code blocks, it will use the knitr engine (from R) to render the document. This means we need to load the reticulate package, which allows us to execute Python code within the R session, within the conda environment specified.

Note: When a Quarto document just contains Python code blocks (and no R code), Quarto uses the Jupyter engine to render the document.
-->

```{r, include=FALSE}
library(reticulate)
use_condaenv("des-rap-book", required = TRUE)
```