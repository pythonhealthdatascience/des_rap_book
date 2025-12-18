#!/usr/bin/env bash
set -euo pipefail

# This file generates a version of the des-rap-book environment
# with the local python package appended

cp environment.yaml pages/guide/environment-full.yaml
printf "    - -e .\n" >> pages/guide/environment-full.yaml