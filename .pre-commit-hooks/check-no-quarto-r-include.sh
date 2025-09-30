#!/usr/bin/env bash

# Find staged .qmd files
FILES=$(git diff --cached --name-only | grep '\.qmd$')
ERROR=0

for FILE in $FILES; do
  # Detect presence of Quarto include lines
  if grep -q '{{< *include *.*\.R *>}}' "$FILE"; then
    echo "ERROR: $FILE contains '{{< include ... .R >}}'."
    echo "Please use '#| file: filename.R' in code chunk options instead."
    ERROR=1
  fi
done

if [ $ERROR -eq 1 ]; then
  echo "Commit blocked: Replace '{{< include ... .R >}}' with Quarto chunk option '#| file: filename.R'."
  exit 1
fi

exit 0
