#!/usr/bin/env bash
set -euxo pipefail

function usage {
    echo ""
    echo "Consul configuration put."
    echo ""
    echo "usage: --src ./predict/local/configuration.yaml --dst organization/application/predict/configuration.yaml"
    echo ""
    echo " --src -s string      path to configuration file"
    echo " --dst -d string      path to consul kv"
    echo " --help -t            Print usage and exit"
    echo ""
}

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
        ;;
        -d|--dst)
            dst="$2"
        ;;
        -s|--src)
            src="$2"
        ;;
        *)
            invalid_parameter $1
    esac
    shift
    shift
done

consul kv put ${dst} @${src}
