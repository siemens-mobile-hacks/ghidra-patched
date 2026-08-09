#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
	echo "Usage: $0 <version> <build-number>" >&2
	exit 1
fi

version="$1"
build_number="$2"

if [[ ! "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	echo "Invalid version: ${version}" >&2
	exit 1
fi

if [[ ! "${build_number}" =~ ^[1-9][0-9]*$ ]]; then
	echo "Invalid build number: ${build_number}" >&2
	exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
	echo "Working tree is not clean" >&2
	exit 1
fi

tag="${version}-${build_number}"
if git rev-parse --verify --quiet "refs/tags/${tag}" >/dev/null; then
	echo "Tag already exists: ${tag}" >&2
	exit 1
fi

git tag --annotate "${tag}" --message "Ghidra ${version} patched build ${build_number}"
git push origin "${tag}"
