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
    -p|--password)
      password="$2"
    ;;
    -u|--username)
      username="$2"
    ;;
    *)
      echo "Invalid argument: $1"
      echo "Expected: --branch --canary --host --name --password --username"
      exit 1
  esac
  shift
  shift
done

branch=${branch:-"main"}
host=${host:-"github.com"}

canary=${canary:-"${name}canary"}

cd "${canary}"
git config credential.helper store
(echo "protocol=https"; echo "host=${host}"; echo "username=${username}"; echo password=$(printf "${password}" | jq -sRr @uri); echo) | git credential approve
git push -u origin "${branch}" --force-with-lease -v
