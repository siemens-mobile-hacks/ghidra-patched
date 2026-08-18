#!/usr/bin/env bash

set -euo pipefail

root_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
version="${GHIDRA_VERSION:-12.1.2}"
tag="Ghidra_${version}_build"
source_dir="${root_dir}/build/ghidra"
build_mode="${GHIDRA_BUILD_MODE:-distribution}"

if [[ "${build_mode}" != "distribution" && "${build_mode}" != "natives" ]]; then
	echo "Unsupported GHIDRA_BUILD_MODE: ${build_mode}" >&2
	exit 1
fi

if [[ "${build_mode}" == "natives" && -z "${GHIDRA_NATIVE_PLATFORM:-}" ]]; then
	echo "GHIDRA_NATIVE_PLATFORM is required for a native-only build" >&2
	exit 1
fi

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
git -C "${source_dir}" clean -fdX -- \
	Ghidra/Features/Decompiler/src/decompile/cpp/test_dbg \
	Ghidra/Features/Decompiler/src/decompile/cpp/decomp_test_dbg \
	Ghidra/Features/Decompiler/src/decompile/cpp/decomp_dbg \
	Ghidra/Features/Decompiler/src/decompile/cpp/com_dbg \
	Ghidra/Features/Decompiler/src/decompile/cpp/ghi_opt \
	Ghidra/Features/Decompiler/src/decompile/cpp/ghidra_opt

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

mkdir -p "${root_dir}/dist"

if [[ "${build_mode}" == "natives" ]]; then
	platform="${GHIDRA_NATIVE_PLATFORM}"
	"${gradle[@]}" --no-daemon \
		":Decompiler:buildNatives_${platform}" \
		":FileFormats:buildNatives_${platform}" \
		":PDB:buildNatives_${platform}" \
		":DemanglerGnu:buildNatives_${platform}"

	stage_dir="$(mktemp -d "${root_dir}/build/native-stage.XXXXXX")"
	archive_dir="$(mktemp -d "${root_dir}/build/native-archive.XXXXXX")"
	cleanup() {
		rm -rf -- "${stage_dir}" "${archive_dir}"
	}
	trap cleanup EXIT

	found=0
	while IFS= read -r -d '' native_dir; do
		relative="${native_dir#"${source_dir}/"}"
		install_relative="${relative/\/build\/os\//\/os\/}"
		destination="${stage_dir}/$(dirname "${install_relative}")"
		mkdir -p "${destination}"
		cp -a "${native_dir}" "${destination}/"
		found=1
	done < <(find "${source_dir}/Ghidra" "${source_dir}/GPL" \
		-type d -path "*/build/os/${platform}" \
		! -path "${source_dir}/Ghidra/Test/*" -print0)

	if [[ "${found}" -ne 1 ]]; then
		echo "No native outputs found for ${platform}" >&2
		exit 1
	fi

	if [[ "${platform}" == win_* ]]; then
		test -f "${stage_dir}/Ghidra/Features/Decompiler/os/${platform}/decompile.exe"
	else
		test -x "${stage_dir}/Ghidra/Features/Decompiler/os/${platform}/decompile"
	fi

	archive="ghidra-natives-${platform}.zip"
	(cd "${stage_dir}" && zip -qr "${archive_dir}/${archive}" Ghidra GPL)
	cp -v "${archive_dir}/${archive}" "${root_dir}/dist/${archive}"
	exit 0
fi

if [[ "${GHIDRA_RUN_TESTS:-0}" == "1" ]]; then
	"${gradle[@]}" --no-daemon unitTestReport
fi
"${gradle[@]}" --no-daemon buildGhidra
cp -v build/dist/*.zip "${root_dir}/dist/"
