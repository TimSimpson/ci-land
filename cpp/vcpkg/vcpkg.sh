#! /bin/bash
set -euo pipefail

readonly script_name="${0}"
readonly relative_scripts_dir=$(dirname "${BASH_SOURCE[0]}")
readonly scripts_dir=$(cd "${relative_scripts_dir}" >/dev/null 2>&1 && pwd)
readonly root_dir="$(pwd)"

readonly output_dir="${root_dir}/output/vcpkg"
readonly build_dir="${output_dir}"


function cmd_build() {
  mkdir -p "${build_dir}"
  pushd "${build_dir}"
  cmake "${root_dir}" -DCMAKE_TOOLCHAIN_FILE="${VCPKG_ROOT}"/scripts/buildsystems/vcpkg.cmake
  popd
  cmd_rebuild "${@}"
}

function cmd_clean(){
    require_valid_profile
    if [ -d "${build_dir}" ]; then
        rm -r "${build_dir}"
    fi
}

function cmd_install() {
  echo '

  I dunno how this will work...

  '
}

function cmd_rebuild() {
  pushd "${build_dir}"
  cmake --build ./
  popd
  set +u
  if [[ "${1}" == "test" ]]; then
    cmd_test
  fi
  set -u
}

function cmd_test() {
  pushd "${build_dir}"
  CTEST_OUTPUT_ON_FAILURE=1 ctest
  popd
}


function show_help() {
    echo "Usage: ${script_name} [command]"
    echo "
    Commands:
          build        - build in ${build_dir}
          clean        - Erase ${build_dir}
          install      - install to ${build_dir}
          rebuild      - calls CMake directly in ${build_dir}
          test         - run ctest in ${build_dir}
    "

}


if [ $# -lt 1 ]; then
    show_help
    exit 1
fi

readonly cmd="${1}"
shift 1;

case "${cmd}" in
    "build" ) cmd_build $@ ;;
    "clean" ) cmd_clean $@ ;;
    "install" ) cmd_install $@ ;;
    "rebuild" ) cmd_rebuild $@ ;;
    "test" ) cmd_test $@ ;;
    * )
        echo "'${cmd}' is not a valid command."
        echo
        show_help
        exit 1
esac
