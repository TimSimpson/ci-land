#!/bin/bash
set -euo pipefail
readonly root_dir="$(pwd)"
readonly relative_scripts_dir=$(dirname "${BASH_SOURCE[0]}")
readonly scripts_dir=$(cd "${relative_scripts_dir}" >/dev/null 2>&1 && pwd)
readonly output_dir="${root_dir}/output/clang-format"

cp "${script_dir}/.clang-format" "${root_dir}/.clang-format"
mkdir -p "${output_dir}"
echo $script_dir
#cmake -P "${script_dir}/RunClangFormat.cmake" -D "source:string=${root_dir}"
cmake -H"${script_dir}"  -B"${output_dir}" -D"root_dir:directory=${root_dir}" -D"exclude:directory=${root_dir}/output"
cd "${output_dir}"
echo "Running..."
make format-all
echo "OK!"
# # -H"${script_dir}" -B"${output_dir}" -Dsource="${root_dir}"

