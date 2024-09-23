#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat << EOF
Usage: $0 [options]

Options:
  -r, --ref string      GitHub ref (default: GITHUB_REF env var)
  -s, --sha string      GitHub SHA (default: GITHUB_SHA env var)
  -h, --help            Print this help and exit

If not provided via command-line arguments, GITHUB_REF and GITHUB_SHA
must be set in the environment.
EOF
}

# Parse command line arguments
while (( "$#" )); do
    case "$1" in
        -r|--ref)
            ref="$2"
            shift 2
            ;;
        -s|--sha)
            sha="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: Invalid argument $1" >&2
            usage
            exit 1
            ;;
    esac
done

# Set variable, fail if it is not provided and not in the environment
ref="${ref:=$GITHUB_REF}"
deploy=""

if [[ "$ref" == refs/tags/* ]]; then
    version=$(basename "$ref")
    regex="^[0-9]+\.[0-9]+\.[0-9]+(-(rc|evaluation)\.([0-9]+))?$"
    # Check if the version matches semantic versioning pattern
    if [[ $version =~ $regex ]]; then
        # Extract deploy from the version
        deploy="${BASH_REMATCH[2]}"
        if [[ $deploy == "" ]]; then
            deploy="live"
        fi
    fi
else
    # Set variable, fail if it is not provided and not in the environment
    sha="${sha:=$GITHUB_SHA}"
    version="$sha"
fi

# Output variables in GitHub Actions output format
echo "version=${version}"
echo "deploy=${deploy}"
