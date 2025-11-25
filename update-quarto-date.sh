#!/bin/bash
set -e

for f in $(git ls-files 'pages/*.qmd'); do
  # Get the last commit date for the file from main branch
  date=$(git log -1 --format="%ad" --date=iso-strict origin/main -- "$f")
  [ -z "$date" ] && date=$(git log -1 --format="%ad" --date=iso-strict -- "$f")
  # Insert or update the `date:` field in YAML front matter
  tmpfile=$(mktemp)
  awk -v new_date="$date" '
    BEGIN {in_yaml=0; date_set=0}
    NR==1 && /^---/ {in_yaml=1; print; next}
    in_yaml && /^date:/ {print "date: \"" new_date "\""; date_set=1; next}
    in_yaml && /^---/ && !date_set {print "date: \"" new_date "\""; date_set=1}
    {print}
    in_yaml && /^---/ {in_yaml=0}
  ' "$f" > "$tmpfile" && mv "$tmpfile" "$f"
done
