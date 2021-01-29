#!/usr/bin/env bash
set -e

# Create and activate a local Python 3 conda environment
PYTHONNOUSERSITE=True conda env create --force -q -f environment.yaml
conda activate openwpm-crawler
# Update the corresponding Jupyter kernel
ipython kernel install --user --name=openwpm-crawler
