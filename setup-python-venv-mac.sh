#!/usr/bin/env bash
set -e

# Create and activate a local Python 3 venv
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip

# Install requirements
pip install -U -r requirements.txt

# Install all analysis requirements except plyvel
cat analysis/utils/requirements.txt | grep -v plyvel > analysis/utils/requirements.mac.txt
CFLAGS='-mmacosx-version-min=10.7 -stdlib=libc++' pip install -r analysis/utils/requirements.mac.txt
rm analysis/utils/requirements.mac.txt

# A recent version of leveldb is required
brew install leveldb || brew upgrade leveldb

# Make sure we build plyvel properly to work with the installed leveldb on recent OSX versions
CFLAGS='-mmacosx-version-min=10.7 -stdlib=libc++ -std=c++11' pip install --force-reinstall --ignore-installed --no-binary :all: plyvel

# Update the corresponding Jupyter kernel
ipython kernel install --user --name=openwpm-crawler

echo "* Success: To activate the python venv, run"
echo "    source venv/bin/activate"
