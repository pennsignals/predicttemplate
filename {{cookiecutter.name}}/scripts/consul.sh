#!/usr/bin/env bash
set -euo pipefail

function usage {
    cat << EOF
Usage: $0 [options]

Options:
    -s, --src string            Path to configuration file
                                (example: ./predict/local/configuration.yaml)
    -d, --dst string            Path to consul key value
                                (example: organization/application/predict/configuration.yaml
    -h, --help                  Print this help and exit
EOF
}

while (( "$#" )); do
    case "$1" in
        -d|--dst)
            dst="$2"
            shift 2
            ;;
        -s|--src)
            src="$2"
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

consul kv put ${dst} @${src}
