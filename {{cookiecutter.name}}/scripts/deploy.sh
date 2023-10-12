#!/usr/bin/env bash
set -euxo pipefail

# echo all the variables
echo "VERSION: $VERSION"
echo "VAR_FILE: $VAR_FILE"
LEVANT_VERSION=0.3.3
BINARY=linux-amd64-levant

wget https://github.com/hashicorp/levant/releases/download/${VERSION}/${BINARY} -O /usr/bin/levant
chmod +x /usr/bin/levant

for dir in */ ; do
    if [ -d "${dir}nomad" ]; then

      echo "Deploying jobs from: ${dir}nomad."
      for file in ${dir}nomad/*; do
          matched=$([[ $file =~ ^.*.nomad.hcl$ ]] && echo "true" || echo "false")

          # only deploy *.nomad.hcl (jobs)
          if [ $matched = "true" ]; then
            levant deploy -var TAG=${VERSION} -ignore-no-changes -vault=true -var-file=${VAR_FILE} ${file}
          fi

      done
    fi
done
