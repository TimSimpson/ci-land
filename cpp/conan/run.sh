#! /bin/bash
if [ "${PROFILE}" == '' ]; then
    echo 'PROFILE environment variable not defined.'
    exit 1
fi

set -euo pipefail
readonly root_dir="$(pwd)"
readonly scripts_dir="${root_dir}/ci"
readonly output_dir="${root_dir}/output"
readonly profile_path="${scripts_dir}/profiles/${PROFILE}"
readonly build_dir="${output_dir}/${PROFILE}"

if [ ! -f "${profile_path}" ]; then
    echo 'Conan profile file not found at '"${profile_path}"
    exit 1
fi

mkdir -p "${build_dir}"
cd "${build_dir}"
conan install "${root_dir}" -pr="${profile_path}" --build missing
LP3_ROOT_PATH="${root_dir}/ci/media" conan build "${root_dir}"
