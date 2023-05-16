{% raw %}#!/usr/bin/env bash
set -euxo pipefail

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
	    echo '. ./version.sh --sha ${{ github.sha }} --ref ${{ github.ref }}'
	    exit 0
	;;
        --sha)
	    local sha="$1"
	;;
        --ref)
	    local ref="$1"
	;;
        *)
	    invalid_parameter "$1"
	    exit 1
    esac
    shift
    shift
done

VERSION="${ sha }"

if [[ ${ ref } == refs/tags/* ]]; then
  # Strip git ref prefix from version
  TAG_NAME=$(echo "${ ref }" | sed -e 's,.*/\(.*\),\1,')
  # Strip "v" prefix from tag name
  VERSION=$(echo "${ TAG_NAME }" | sed -e 's/^v//')
fi{% endraw %}
