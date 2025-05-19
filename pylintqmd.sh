#!/bin/bash

# Lint python code within quarto files with automatic cleanup
# e.g. bash lint_pyqmd.sh pages/inputs/input_modelling
# To keep the temporary .ipynb and .py files for debugging:
# e.g. KEEP_TEMP_FILES=1 bash lint_pyqmd.sh pages/inputs/input_modelling

# Get the first argument passed to the script (the base filename/path, without extension)
base="$1"

# Check if the provided filename ends with '.qmd'
# If it does, print an error message and exit.
# This ensures the user provides the file path WITHOUT the .qmd extension,
# as the script expects just the base name (e.g., 'pages/inputs/input_modelling')
if [[ "$base" == *.qmd ]]; then
    echo "Error: Please provide the file path without the .qmd extension (e.g., 'pages/inputs/input_modelling', not 'pages/inputs/input_modelling.qmd')." >&2
    exit 1
fi

# Define a cleanup function to remove temporary files (.ipynb and .py) after the script finishes
# This will only remove the files if the KEEP_TEMP_FILES environment variable is not set
cleanup() {
    if [ -z "${KEEP_TEMP_FILES}" ]; then
        rm -f "${base}.ipynb" "${base}.py"
    fi
}

# Register the cleanup function to be called automatically when the script exits,
# whether it exits normally or due to an error
trap cleanup EXIT

# Define a function to print an error message and exit the script with a non-zero status
# This is used throughout the script to handle errors gracefully and inform the user
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Convert .qmd to .py via .ipynb, suppressing output to terminal
quarto convert "${base}.qmd" > /dev/null 2>&1 || error_exit "Failed to convert ${base}.qmd to .ipynb"
jupytext --to py:percent "${base}.ipynb" > /dev/null 2>&1 || error_exit "Failed to convert ${base}.ipynb to .py"

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