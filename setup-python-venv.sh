#!/usr/bin/env bash
set -e

# Create and activate a local Python 3 venv
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip

# Install requirements
pip install -U -r requirements.txt

# Update the corresponding Jupyter kernel
ipython kernel install --user --name=openwpm-crawler

echo "* Success: To activate the python venv, run"
echo "    source venv/bin/activate"
