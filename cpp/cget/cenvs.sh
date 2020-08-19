#! /bin/bash
set -euo pipefail

readonly script_name="${0}"
readonly relative_scripts_dir=$(dirname "${BASH_SOURCE[0]}")
readonly scripts_dir=$(cd "${relative_scripts_dir}" >/dev/null 2>&1 && pwd)
readonly root_dir="$(pwd)"

# An untouched verison of Vcpkg is kept here, to make setting up multiple cenvs
# quicker.
readonly vcpkg_prisitine_copy="${CENV_ROOT}"/vcpkg

function require_cenv_root() {
    if [ "${CENV_ROOT}" == '${CENV_ROOT}' ]; then
        echo 'CENV_NAME environment variable not set.'
        exit 1
    fi
}

function require_cenv_name() {
  if [ "${CENV_NAME}" == '${CENV_NAME}' ]; then
      echo 'CENV_NAME environment variable not set. Call `cenv s` to set it.'
      exit 1
  fi
}

function ensure_vcpkg() {
    if [ -d "${vcpkg_prisitine_copy}" ]; then
        return
    fi
    git clone https://github.com/Microsoft/vcpkg.git "${vcpkg_prisitine_copy}"
    cd "${VCPKG_ROOT}"
    ./bootstrap-vcpkg.sh
}

function cmd_reinstall_vcpkg() {
    # This installs a fresh copy of vcpkg.
    local v
    if [ -d "${vcpkg_prisitine_copy}" ]; then
      rm -r "${vcpkg_prisitine_copy}"
    fi
    ensure_vcpkg
}


function add_vcpkg() {
    # Adds vcpkg to a cenv
    local cenv_name="${1}"
    local default_triplet="${2}"
    ensure_vcpkg
    local cget_prefix_path="${CENV_ROOT}"/envs/"${cenv_name}"
    local dst="${cget_prefix_path}"/vcpkg
    echo "Copying vcpkg (hopefully pristine copy) from ${vcpkg_prisitine_copy} to {dst}."
    cp -r "${vcpkg_prisitine_copy}" "${dst}"

    mkdir -p  "${cget_prefix_path}"/bin
    echo '#!/bin/bash
VCPKG_ROOT='"'${dst}'"'
VCPKG_DEFAULT_TRIPLET='"'${default_triplet}'"'
'"${dst}"'/vcpkg "${@}"
    ' > "${cget_prefix_path}"/bin/vcpkg
    chmod +x "${cget_prefix_path}"/bin/vcpkg

    local cget_toolchain="${cget_prefix_path}"/cget/cget.cmake
    local vcpkg_toolchain="${dst}"/scripts/buildsystems/vcpkg.cmake
    echo 'include("'"${vcpkg_toolchain}"'")' >> "${cget_toolchain}"
}

function cenv_delete() {
  local cget_prefix_path="${CENV_ROOT}"/envs/"${cenv_name}"
  if [ -d "${cget_prefix_path}" ]; then
    rm -r "${cget_prefix_path}"
  fi
}

function cget_init() {
    local cenv_name="${1}"
    shift 1
    local cget_args="${@}"
    local cget_prefix_path="${CENV_ROOT}"/envs/"${cenv_name}"
    cget init --prefix "${cget_prefix_path}" "${cget_args}"
    echo "${cget_args}" > "${cget_prefix_path}"/cenv-info.txt
}

function cmd_create_clang-8-d-static() {
    # Creates 'clang-8-d-static' cenv
    local cenv_name='clang-8-d-static'
    local cget_args='--std=c++17 -DCMAKE_C_COMPILER:none=clang-8 -DCMAKE_CXX_COMPILER:none=clang++-8 -DCMAKE_BUILD_TYPE:none=Debug -DCMAKE_CXX_STANDARD=17 -DBUILD_SHARED_LIBS=NO'
    cenv_delete "${cenv_name}"
    cget_init "${cenv_name}" "${cget_args}"
    add_vcpkg "${cenv_name}" x64-linux
}

function show_help() {
    echo "Usage: ${script_name} [command]"
    echo "
    Commands:
          reinstall-vcpkg - Installs a fresh copy of vcpkg in "${CENV_ROOT}"/vcpkg

          clang-8-d-static
    "

}

if [ $# -lt 1 ]; then
    show_help
    exit 1
fi

readonly cmd="${1}"
shift 1;

case "${cmd}" in
    "reinstall-vcpkg" ) cmd_reinstall_vcpkg $@ ;;
    "clang-8-d-static" ) cmd_create_clang-8-d-static $@ ;;
    * )
        echo "'${cmd}' is not a valid command."
        echo
        show_help
        exit 1
esac
