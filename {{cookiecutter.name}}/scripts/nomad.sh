#!/usr/bin/env bash
set -euxo pipefail

function usage {
    echo ""
    echo "Publish labeled images from docker compose."
    echo ""
    echo "usage: --src -s ./predict/nomad --dst -d ./nomad"
    echo ""
    echo "  --src -s string          Source directory for nomad files"
    echo "  --dst -d string          Destination for rendered nomad files"
    echo "  --version -v string      version"
    echo "                           (example: 4.0.0-rc.1)"
    echo "  --help -h                Print usage and exit"
    echo ""
}

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
        ;;
        -s|--src)
            src="$2"
        ;;
        -d|--dst)
            dst="$2"
        ;;
        -v|--version)
            version="$2"
        ;;
        *)
            invalid_parameter $1
    esac
    shift
    shift
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
