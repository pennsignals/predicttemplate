{% raw %}#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat << EOF

Publish labeled images from docker compose.

usage: --version -v string [options]

Required:
  --version -v string      version (example: 4.0.0-rc.1, 4.0.0)

Options:
  --build -b bool          build images (default: false)
  --registry -c string     registry (default: ghcr.io)
  --username -u string     username (default: GITHUB_REF)
  --password -p string     password (default: GITHUB_TOKEN)
  --repository -r string   repository (default: GITHUB_REPOSITORY)
  --help -h                Print this help and exit

If not provided via command-line arguments, GITHUB_REF, GITHUB_TOKEN
and GITHUB_REPOSITORY must be set in the environment.
EOF
}

# Default values
build=false
registry="ghcr.io"

# Parse command line arguments
while (( "$#" )); do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -b|--build)
            build="$2"
            shift 2
            ;;
        -c|--registry)
            registry="$2"
            shift 2
            ;;
        -u|--username)
            username="$2"
            shift 2
            ;;
        -p|--password)
            password="$2"
            shift 2
            ;;
        -r|--repository)
            repository="$2"
            shift 2
            ;;
        -v|--version)
            version="$2"
            shift 2
            ;;
        *)
            echo "Error: Invalid argument $1" >&2
            usage
            exit 1
            ;;
    esac
done

username="${username:=$GITHUB_REF}"
password="${password:=$GITHUB_TOKEN}"
repository="${repository:=$GITHUB_REPOSITORY}"

repository=$(echo "${repository}" | tr '[:upper:]' '[:lower:]')

docker login "${registry}" -u "${username}" -p "${password}"

[[ "${build}" == true ]] && docker compose -f docker-compose.yml build --no-cache

echo "version: ${version}"
images=$(docker images --filter "label=name" --format='{{.ID}}')

echo "images: ${images}"
for image in $images; do
    name=$(basename "${repository}").$(docker inspect --format '{{ index .Config.Labels "name" }}' "${image}")
    tag="${registry}/${repository}/${name}:${version}"

    echo "image: ${image}; tag: ${tag}"
    docker tag "${image}" "${tag}"
    docker push "${tag}"
done{% endraw %}
