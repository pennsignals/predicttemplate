#!/usr/bin/env bash
set -euo pipefail

if [[ "${GITHUB_REF}" == refs/tags/* ]]; then
    version=$(basename "${GITHUB_REF}")
else
    version=${GITHUB_SHA}
fi

echo $version
