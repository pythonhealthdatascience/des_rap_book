#!/bin/bash

# ------------------------------------------------------------
# Lint python code within quarto files with automatic cleanup
#
# To lint file:
#      bash pylintqmd.sh file.qmd
#
# To lint all .qmd files in directory
#      bash pylintqmd.sh folder
#
# To keep temporary .py files for debugging when lint:
#      KEEP_TEMP_FILES=1 bash pylintqmd.sh file.qmd
# ------------------------------------------------------------

# Function to process a single .qmd file
process_qmd() {
    qmd_file="$1"

    if [[ -z "$qmd_file" ]]; then
        echo "Error: Please provide the .qmd file (e.g., 'filename.qmd')." >&2
        exit 1
    fi

    if [[ "$qmd_file" != *.qmd ]]; then
        echo "Error: File must have a .qmd extension (e.g., 'filename.qmd')." >&2
        exit 1
    fi

    echo "Checking for active python code in $qmd_file..."

    base="${qmd_file%.qmd}"

    error_exit() {
        echo "Error: $1" >&2
        exit 1
    }

    # --- NEW: Convert .qmd to .py using the Python converter ---
    python3 qmd_to_py_converter.py "$qmd_file" "${base}.py" > /dev/null 2>&1 || error_exit "Failed to convert $qmd_file to .py"

    # Remove leading "./" from base before using it, then run pylint, piping
    # output through sed to replace all ".py" with ".qmd"
    nodot_base="${base#./}"
    pylint "${nodot_base}.py" | sed "s|${nodot_base}\.py|$qmd_file|g"

    # Remove temporary files (.py), but only if KEEP_TEMP_FILES is not set
    if [ -z "${KEEP_TEMP_FILES}" ]; then
        rm -f "${base}.py"
    fi
}

# Accept files and directories as arguments
if [ $# -eq 0 ]; then
    echo "Error: Please provide .qmd files or directories." >&2
    exit 1
fi

# Gather all .qmd files from arguments
qmd_files=()
for arg in "$@"; do
    if [ -f "$arg" ] && [[ "$arg" == *.qmd ]]; then
        qmd_files+=("$arg")
    elif [ -d "$arg" ]; then
        while IFS= read -r -d '' file; do
            qmd_files+=("$file")
        done < <(find "$arg" -type f -name "*.qmd" -print0)
    else
        echo "Warning: $arg is not a .qmd file or directory, skipping." >&2
    fi
done

# Process each .qmd file
for qmd_file in "${qmd_files[@]}"; do
    process_qmd "$qmd_file"
done
