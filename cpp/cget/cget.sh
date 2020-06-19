#! /bin/bash
set -euo pipefail

readonly script_name="${0}"
readonly relative_scripts_dir=$(dirname "${BASH_SOURCE[0]}")
readonly scripts_dir=$(cd "${relative_scripts_dir}" >/dev/null 2>&1 && pwd)
readonly root_dir="$(pwd)"

set +u
if [ "${CENV_NAME}" == '' ]; then
    CENV_NAME='${CENV_NAME}'
fi
set -u

readonly output_dir="${root_dir}/output/cget"
readonly build_dir="${output_dir}/${CENV_NAME}"
readonly test_package_src="${root_dir}/test_package"
readonly test_package_build_dir="${output_dir}/${CENV_NAME}/test_package"

function require_cenv_name() {
  if [ "${CENV_NAME}" == '${CENV_NAME}' ]; then
      echo 'CENV_NAME environment variable not set. Call `cenv s` to set it.'
      exit 1
  fi
  if [ "${CGET_PREFIX}" == '' ]; then
      echo 'CGET_PREFIX was not set. Is cenv / cget properly installed?'
      exit 1
  fi
}

function cmd_clean(){
    require_cenv_name
    if [ -d "${build_dir}" ]; then
        rm -r "${build_dir}"
    fi
}

function cmd_build() {
  require_cenv_name
  mkdir -p "${build_dir}"
  pushd "${build_dir}"
  cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE="${CGET_PREFIX}/cget/cget.cmake" -DCMAKE_INSTALL_PREFIX="${CGET_PREFIX}" -H"${root_dir}" -B"${build_dir}"
  cmake --build "${build_dir}"
  popd
}

function cmd_install() {
  require_cenv_name
  mkdir -p "${build_dir}"
  pushd "${build_dir}"
  cmake --build "${build_dir}" --target install
  popd
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

function cmd_run() {
  pushd "${build_dir}"
  export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${CGET_PREFIX}/cget/lib
  "${@}"
  local code="${?}"
  popd
  exit "${code}"
}

function cmd_test() {
  pushd "${build_dir}"
  CTEST_OUTPUT_ON_FAILURE=1 cmd_run ctest
  popd
}

function cmd_test_package() {
  require_cenv_name
  if [ -d "${test_package_build_dir}" ]; then
    rm -r "${test_package_build_dir}"
  fi
  mkdir -p "${test_package_build_dir}"
  pushd "${test_package_build_dir}"
  cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE="${CGET_PREFIX}/cget/cget.cmake" -DCMAKE_INSTALL_PREFIX="${CGET_PREFIX}" -H"${test_package_src}" -B"${test_package_build_dir}"
  cmake --build "${test_package_build_dir}"
  popd
}


function show_help() {
    echo "Usage: ${script_name} [command]"
    echo "
    Commands:
          clean        - Erase ${build_dir}
          build        - build in ${build_dir}
          install      - install to ${CGET_PREFIX}
          rebuild      - calls CMake directly in ${build_dir}
          run          - runs executables in ${build_dir} directory
          test         - run ctest in ${build_dir}
          test_package - builds test pacakge ${test_package_src}
                         in ${test_package_build_dir}
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
    "run" ) cmd_run $@ ;;
    "test" ) cmd_test $@ ;;
    "test_package" ) cmd_test_package $@ ;;
    * )
        echo "'${cmd}' is not a valid command."
        echo
        show_help
        exit 1
esac
