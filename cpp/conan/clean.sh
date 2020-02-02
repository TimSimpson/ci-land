#! /bin/bash
set -euo pipefail

if [ "${PROFILE}" == '' ]; then
    echo 'PROFILE environment variable not defined.'
    exit 1
fi

readonly scripts_dir="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"
readonly root_dir="${scripts_dir}/.."
readonly output_dir="${root_dir}/output"
readonly profile_path="${scripts_dir}/profiles/${PROFILE}"
readonly build_dir="${output_dir}/${PROFILE}"

if [ ! -f "${profile_path}" ]; then
    echo 'Conan profile file not found at '"${profile_path}"
    exit 1
fi

rm -r "${build_dir}"
