#!/bin/bash
# Lint python code within quarto files

# Convert .qmd to .py via .ipynb
quarto convert "$1.qmd"
jupytext --to py:percent "$1.ipynb"

# Process the generated Python file so line numbers align with qmd...

# Remove Jupyter metadata
perl -i -0777 -pe 's/^# ---.*?\n# %% \[markdown\]\n//s' "$1.py"

# Replace all comment lines in markdown cells with '# -' otherwise the linter
# will says these lines are too long (as assumes they are python comments)
sed -i -e '/^# %% \[markdown\]/,/^# %%/ {
  /^#/ s/^# .*/# -/
}' "$1.py"

# Do the same for the first section of markdown before the first code cell
sed -i -e '0,/^# %%[^%]*$/ {/^#/ s/^#.*/# -/}' "$1.py"

# Removes lines which are # %%, but not # %% [markdown]
# And remove line after if that is blank (for 2nd command)
perl -i -ne 'if ($skip) { $skip = 0; next if /^$/; } $skip = /^# %%$/; print unless $skip' "$1.py"

# Remove consecutive blank lines, leaving one line at most, if they are before
# a # %% [markdown] line
awk '
  # If the current line is a marker, print one blank line if we saw any, then print the marker
  /^\# %% \[markdown\]/ {
    if (blank_count > 0) print ""
    blank_count = 0
    print
    next
  }
  # If the line is blank, increment counter and skip printing for now
  /^$/ {
    blank_count++
    next
  }
  # For any other line, print any queued blank lines and the line itself
  {
    while (blank_count-- > 0) print ""
    blank_count = 0
    print
  }
' "$1.py" > tmp && mv tmp "$1.py"

# Run pylint
# pylint "$1.py"