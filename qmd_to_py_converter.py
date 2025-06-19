"""
QMD to Python Converter

This script converts .qmd files to .py files while maintaining line alignment
with the original files. It preserves all Python code chunks, and converts
everything else into blank commented lines.

Usage
-----
python qmd_to_py_converter.py input.qmd [output.py] [-v]

Acknowledgements
----------------
Code generated and adapted from Perplexity.Ai.
"""

import re
import sys
import argparse
import os
from pathlib import Path


def convert_qmd_to_py_aligned(qmd_path, output_path=None, verbose=False):
    """
    Convert QMD file directly to Python file with perfect line alignment.

    Parameters
    ----------
    qmd_path : str or Path
        Path to the input .qmd file.
    output_path : str or Path, optional
        Path for the output .py file. If None, uses the same base name with
        .py extension.
    verbose : bool, default=False
        If True, print detailed progress information.

    Returns
    -------
    bool
        True if conversion was successful, False otherwise.
    """

    qmd_path = Path(qmd_path)

    # Determine output path
    if output_path is None:
        output_path = qmd_path.with_suffix('.py')
    else:
        output_path = Path(output_path)

    if verbose:
        print(f"Converting {qmd_path} to {output_path}")

    try:
        # Read the QMD file
        with open(qmd_path, 'r', encoding='utf-8') as f:
            qmd_lines = f.readlines()

        # Initialize processing state
        py_lines = []
        in_python_block = False
        in_r_block = False
        in_yaml = False

        # Process each line
        for line_num, line in enumerate(qmd_lines, 1):
            original_line = line.rstrip('\n')

            # Handle YAML frontmatter (convert to comments)
            if line_num == 1 and original_line.strip() == '---':
                in_yaml = True
                py_lines.append('# ---')
                continue
            elif in_yaml and original_line.strip() == '---':
                in_yaml = False
                py_lines.append('# ---')
                continue
            elif in_yaml:
                # Comment out YAML content
                if original_line.strip() == '':
                    py_lines.append('#')
                else:
                    py_lines.append('# -')
                continue

            # Detect code block boundaries
            python_block_start = re.match(r'^```\{python\}', original_line)
            r_block_start = re.match(r'^```\{r\}', original_line)
            code_block_end = original_line.strip() == '```'

            # Handle code block transitions
            if python_block_start:
                in_python_block = True
                py_lines.append('# %% [python]')
                continue
            elif r_block_start:
                in_r_block = True
                py_lines.append('# -')
                continue
            elif code_block_end and (in_python_block or in_r_block):
                if in_python_block:
                    in_python_block = False
                    py_lines.append('')  # Empty line to close Python block
                elif in_r_block:
                    in_r_block = False
                    py_lines.append('# ```')  # Comment out R block end
                continue

            # Process line content based on current context
            if in_python_block:
                # Python code: preserve exactly as is
                py_lines.append(original_line)
            elif in_r_block:
                # R code: convert to comments
                if original_line.strip() == '':
                    py_lines.append('#')
                else:
                    py_lines.append('# -')
            else:
                # Markdown content: convert to comments
                if original_line.strip() == '':
                    py_lines.append('#')
                else:
                    py_lines.append('# -')

        # Write the output file
        with open(output_path, 'w', encoding='utf-8') as f:
            for line in py_lines:
                f.write(line + '\n')

        if verbose:
            print(f"✓ Successfully converted {qmd_path} to {output_path}")
            print(f"  Line count: {len(qmd_lines)} → {len(py_lines)} " +
                  "(perfect preservation)")

            # Verify alignment of key markers
            verify_line_alignment(qmd_lines, py_lines, verbose)

        return True

    except FileNotFoundError:
        print(f"Error: Input file '{qmd_path}' not found")
        return False
    except PermissionError:
        print(f"Error: Permission denied accessing '{qmd_path}' " +
              f"or '{output_path}'")
        return False
    except Exception as e:
        print(f"Error during conversion: {e}")
        return False


def verify_line_alignment(qmd_lines, py_lines, verbose=False):
    """
    Verify that key Python markers are properly aligned between QMD and Python
    files.

    Args:
        qmd_lines (list): Lines from the original QMD file
        py_lines (list): Lines from the converted Python file
        verbose (bool): Print detailed verification results
    """

    # Define markers that should be perfectly aligned
    alignment_markers = [
        "# pylint: disable=missing-module-docstring",
        "import inspect", 
        "class ParamClass:",
        "def check_param_names(",
        "def validate_param(",
        "def model("
    ]

    if verbose:
        print("\n  === Line Alignment Verification ===")

    all_aligned = True

    for marker in alignment_markers:
        qmd_line_num = find_line_with_content(qmd_lines, marker)
        py_line_num = find_line_with_content(py_lines, marker)

        if qmd_line_num and py_line_num:
            if qmd_line_num == py_line_num:
                if verbose:
                    print(f"  ✓ {marker[:35]:<35}: line {qmd_line_num}")
            else:
                all_aligned = False
                if verbose:
                    diff = py_line_num - qmd_line_num
                    print(f"  ✗ {marker[:35]:<35}: QMD={qmd_line_num}, PY={py_line_num} (diff: {diff:+d})")
        elif qmd_line_num:
            if verbose:
                print(f"  ? {marker[:35]:<35}: found in QMD (line {qmd_line_num}) but not in PY")

    if verbose:
        status = "✓ PERFECT ALIGNMENT" if all_aligned else "✗ ALIGNMENT ISSUES DETECTED"
        print(f"  {status}")


def find_line_with_content(lines, content):
    """
    Find the line number (1-based) of the first line containing the specified content.

    Args:
        lines (list): List of lines to search
        content (str): Content to search for

    Returns:
        int or None: Line number if found, None otherwise
    """
    for i, line in enumerate(lines, 1):
        if content in line:
            return i
    return None


def main():
    """Main entry point for the script."""

    parser = argparse.ArgumentParser(
        description="Convert QMD file to Python with perfect line alignment",
        epilog="This script maintains exact line-by-line correspondence with the original QMD file."
    )
    parser.add_argument(
        "input_file",
        help="Input .qmd file path"
    )
    parser.add_argument(
        "output_file",
        nargs='?',
        help="Output .py file path (optional, defaults to input filename with .py extension)"
    )
    parser.add_argument(
        "-v", "--verbose", 
        action="store_true", 
        help="Print detailed progress and verification information"
    )

    args = parser.parse_args()

    # Validate input file
    if not args.input_file.endswith('.qmd'):
        print("Error: Input file must have .qmd extension")
        sys.exit(1)

    if not os.path.exists(args.input_file):
        print(f"Error: Input file '{args.input_file}' does not exist")
        sys.exit(1)

    # Perform conversion
    success = convert_qmd_to_py_aligned(
        args.input_file,
        args.output_file,
        args.verbose
    )

    if success:
        if args.verbose:
            print("\n🎉 Conversion completed successfully!")
        sys.exit(0)
    else:
        print("❌ Conversion failed")
        sys.exit(1)


if __name__ == "__main__":
    main()
