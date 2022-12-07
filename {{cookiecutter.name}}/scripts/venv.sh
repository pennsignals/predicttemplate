#!/usr/bin/env bash
set -euxo pipefail

brew install python3.9
/opt/homebrew/bin/python3.9 -m venv .venv
. .venv/bin/activate
pip install -U pip setuptools wheel
pip install -e ".[dev]"
pre-commit run --all-files
