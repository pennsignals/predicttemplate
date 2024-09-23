#!/usr/bin/env bash
set -euo pipefail

function usage {
    cat << EOF
Usage: $0 [options]

Levant render and deploy nomad jobs.

Options:
    -s, --src string                Source directory for nomad files
                                    (example: ./predict/nomad)
    -d, --dst string                Destination directory for rendered files
                                    (example: ./nomad)
    -v, --version string            Version
                                    (example: 4.0.0-rc.1)
    -h, --help                      Print this help and exit
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        -s|--src)
            src="$2"
            shift 2
            ;;
        -d|--dst)
            dst="$2"
            shift 2
            ;;
        -v|--version)
            version="$2"
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

echo "Deploying jobs from: ${src}"
for file in ${src}/*.nomad.hcl; do
    name="$(basename ${file})"
    levant render -var version="${version}" -out="${dst}/${name}" ${file}
done

echo "Deploying jobs from: ${dst}."
for file in ${src}/*.nomad.hcl; do
    levant deploy \
        -address http://nomad.service.consul:4646 \
        -var version="${version}" \
        -ignore-no-changes ${file}
done

tar -czvf nomad.tar.gz ${dst}
