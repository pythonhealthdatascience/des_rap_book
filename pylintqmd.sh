#!/bin/bash

# Lint python code within quarto files with automatic cleanup
# e.g. bash lint_pyqmd.sh pages/inputs/input_modelling
# To keep the temporary .ipynb and .py files for debugging:
# e.g. KEEP_TEMP_FILES=1 bash lint_pyqmd.sh pages/inputs/input_modelling

set -e  # Exit immediately on any error

base="$1"
cleanup() {
    if [ -z "${KEEP_TEMP_FILES}" ]; then
        rm -f "${base}.ipynb" "${base}.py"
    fi
}
trap cleanup EXIT  # Cleanup on normal exit or error

# Convert .qmd to .py via .ipynb, suppressing output to terminal
quarto convert "${base}.qmd" > /dev/null 2>&1
jupytext --to py:percent "${base}.ipynb" > /dev/null 2>&1

# Process the generated Python file so line numbers align with qmd...

# Remove Jupyter metadata
perl -i -0777 -pe 's/^# ---.*?\n# %% \[markdown\]\n//s' "${base}.py"

# Replace all comment lines in markdown cells with '# -' otherwise the linter
# will says these lines are too long (as assumes they are python comments)
sed -i -e '/^# %% \[markdown\]/,/^# %%/ {
  /^#/ s/^# .*/# -/
}' "${base}.py"

# Do the same for the first section of markdown before the first code cell
sed -i -e '0,/^# %%[^%]*$/ {/^#/ s/^#.*/# -/}' "${base}.py"

# Removes lines which are # %%, but not # %% [markdown]
# And remove line after if that is blank (for 2nd command)
perl -i -ne 'if ($skip) { $skip = 0; next if /^$/; } $skip = /^# %%$/; print unless $skip' "${base}.py"

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
' "${base}.py" > tmp && mv tmp "${base}.py"

# Run pylint. Pipe output through sed to replace all ".py" with ".qmd"
pylint "${base}.py" | sed "s|${base}.py|${base}.qmd|g"