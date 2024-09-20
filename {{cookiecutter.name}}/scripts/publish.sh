{% raw %}#!/usr/bin/env bash
set -euo pipefail

function usage {
    echo ""
    echo "Publish labeled images from docker compose."
    echo ""
    echo "usage: --build -b bool --registry -r string --username -u string --password -p string"
    echo ""
    echo "  --build -b bool          build images"
    echo "                           (default: false"
    echo "  --registry -c string     registry"
    echo "                           (default: ghcr.io)"
    echo "  --username -u string     username GITHUB_REF"
    echo "  --password -p string     password GITHUB_TOKEN"
    echo "  --repository -r string   repository GITHUB_REPOSITORY"
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
        -b|--build)
            build="$2"
        ;;
        -c|--registry)
            registry="$2"
        ;;
        -u|--username)
            username="$2"
        ;;
        -p|--password)
            password="$2"
        ;;
        -r|--repository)
            repository="$2"
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

build="${build:-false}"
registry="${registry:-ghcr.io}"
username="${username:=$GITHUB_REF}"
password="${password:=$GITHUB_TOKEN}"
repository="${repository:=$GITHUB_REPOSITORY}"
repository=$(echo "$repository" | tr '[:upper:]' '[:lower:]')

docker login "${registry}" -u "${username}" -p "${password}"

if [[ "${build}" == true ]]; then
    docker compose -f docker-compose.yml build --no-cache
fi

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
