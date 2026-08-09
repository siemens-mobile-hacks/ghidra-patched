#!/usr/bin/env bash

set -euo pipefail

root_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
version="${GHIDRA_VERSION:-12.1.2}"
tag="Ghidra_${version}_build"
source_dir="${root_dir}/build/ghidra"

if [[ ! -d "${source_dir}/.git" ]]; then
	mkdir -p "${root_dir}/build"
	git clone --depth 1 --branch "${tag}" \
		https://github.com/NationalSecurityAgency/ghidra.git \
		"${source_dir}"
fi

expected_revision="$(git -C "${source_dir}" rev-parse "refs/tags/${tag}^{commit}")"
current_revision="$(git -C "${source_dir}" rev-parse HEAD)"
if [[ "${current_revision}" != "${expected_revision}" ]]; then
	echo "${source_dir} is not checked out at ${tag}" >&2
	exit 1
fi

git -C "${source_dir}" reset --hard "${expected_revision}"
git -C "${source_dir}" clean -fd

for patch in "${root_dir}"/patches/*.patch; do
	git -C "${source_dir}" apply --check "${patch}"
	git -C "${source_dir}" apply "${patch}"
	echo "Applied: $(basename "${patch}")"
done

cd "${source_dir}"
gradle=(./gradlew)
if [[ "${OSTYPE}" == msys* || "${OSTYPE}" == cygwin* || "${OSTYPE}" == win32* ]]; then
	gradle=(./gradlew.bat)
fi

fetch_args=(--no-daemon)
if [[ "${GHIDRA_HIDE_DOWNLOAD_PROGRESS:-0}" == "1" ]]; then
	fetch_args+=(-DhideDownloadProgress=true)
fi

"${gradle[@]}" "${fetch_args[@]}" -I gradle/support/fetchDependencies.gradle
if [[ "${GHIDRA_RUN_TESTS:-0}" == "1" ]]; then
	"${gradle[@]}" --no-daemon unitTestReport
fi
"${gradle[@]}" --no-daemon buildGhidra

mkdir -p "${root_dir}/dist"
cp -v build/dist/*.zip "${root_dir}/dist/"
