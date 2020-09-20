#! /bin/bash
if [ "${PROFILE}" == '' ]; then
    echo 'PROFILE environment variable not defined.'
    exit 1
fi

set -euo pipefail
readonly relative_scripts_dir=$(dirname "${BASH_SOURCE[0]}")
readonly scripts_dir=$(cd "${relative_scripts_dir}" >/dev/null 2>&1 && pwd)
readonly root_dir="$(pwd)"
readonly output_dir="${root_dir}/output${CIL_OUTPUT_PREFIX:-}"
readonly profile_path="${scripts_dir}/profiles/${PROFILE}"
readonly build_dir="${output_dir}/${PROFILE}"

if [ ! -f "${profile_path}" ]; then
    echo 'Conan profile file not found at '"${profile_path}"
    exit 1
fi

mkdir -p "${build_dir}"
cd "${build_dir}"
conan install "${root_dir}" -pr="${profile_path}" --build missing
set +u
if [ "${CIL_RUN_CALL_SOURCE}" != '' ]; then
    set -u
    readonly download_src_dir="${build_dir}/src"
    mkdir -p "${download_src_dir}"
    conan source -sf "${download_src_dir}" "${root_dir}"
    conan build "${root_dir}" -sf "${download_src_dir}"
else
    set -u
    conan build "${root_dir}"
fi
ctest
