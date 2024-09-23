#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat << EOF
Usage: $0 [options]

Options:
  -p, --password string     GitHub password
  -r, --repository string   GitHub organization/project
  -u, --username string     GitHub username
  -b, --branch string       Github branch
                            (default: main)
  -c, --canary              Github canary project
                            (default: <project>canary)
  -h, --host                GitHub branch
                            (default: github.com)
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
    -b|--branch)
      branch="$2"
      shift 2
      ;;
    -c|--canary)
      canary="$2"
      shift 2
      ;;
    -h|--host)
      host="$2"
      shift 2
      ;;
    -r|--repository)
      repository="$2"
      shift 2
      ;;
    -p|--password)
      password="$2"
      shift 2
      ;;
    -u|--username)
      username="$2"
      shift 2
      ;;
    *)
      echo "Error: Invalid argument $1" >&2
      usage
      exit 1
  esac
done

branch=${branch:-"main"}
host=${host:-"github.com"}
name=${repository#*/}
organization=${repository%/*}

canary=${canary:-"${name}canary"}

cd "${canary}"
git config credential.helper store
(echo "protocol=https"; echo "host=${host}"; echo "username=${username}"; echo password=$(printf "${password}" | jq -sRr @uri); echo) | git credential approve
git push -u origin "${branch}" --force --verbose
