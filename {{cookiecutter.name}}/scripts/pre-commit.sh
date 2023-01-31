#!/bin/bash
if ! [ -x "$(command -v pre-commit)" ]; then
    pip install pre-commit && pre-commit install
fi
if ! [ -x "$(command -v predict)" ]; then
    python -m pip install -e ".[dev]"
fi
CONFIG=./predict/local/test.yaml ENV=./predict/secrets/example.env pre-commit run --all-files
