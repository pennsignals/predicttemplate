#!/usr/bin/env bash
set -euo pipefail

while [ $# -gt 0 ]; do
  case "$1" in
    -b|--branch)
      branch="$2"
    ;;
    -c|--canary)
      canary="$2"
    ;;
    -h|--host)
      host="$2"
      ;;
    -n|--name)
      name="$2"
    ;;
    -o|--organization)
      organization="$2"
    ;;
    -u|--username)
      username="$2"
    ;;
    *)
      echo "Invalid argument: $1"
      echo "Expected: --branch --canary --host --name --organization --username"
      exit 1
  esac
  shift
  shift
done

branch=${branch:-"main"}
host=${host:-"github.com"}

canary=${canary:-"${name}canary"}

cruft create \
  --no-input \
  --checkout "${branch}" \
  --extra-context "{\"description\": \"Canary\", \"name\": \"${canary}\", \"organization\": \"${organization}\", \"repo\": \"${host}/${organization}/${canary}\" }" \
  "https://${host}/${organization}/${name}"
cd "${canary}"
git config --global init.defaultBranch "${branch}"
git init .
git remote add origin "https://${host}/${organization}/${canary}.git"
git add -A
git config user.email "${username}@users.noreply.${host}"
git config user.name "${username}"
git commit -m 'Canary'
