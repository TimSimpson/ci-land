#! /bin/bash
set -euo pipefail

readonly script_name="${0}"
readonly relative_scripts_dir=$(dirname "${BASH_SOURCE[0]}")
readonly scripts_dir=$(cd "${relative_scripts_dir}" >/dev/null 2>&1 && pwd)
readonly root_dir="$(pwd)"

set +u
if [ "${PROFILE}" == '' ]; then
    PROFILE='${PROFILE}'
fi
set -u

readonly profile_path="${scripts_dir}/profiles/${PROFILE}"

readonly output_dir="${root_dir}/output"
readonly build_dir="${output_dir}/${PROFILE}"

function profile_hint() {
    echo 'See valid profiles using:'
    echo
    echo "      ${script_name} profiles"
    echo
    exit 1
}

function require_valid_profile() {
  if [ "${PROFILE}" == '${PROFILE}' ]; then
      echo 'PROFILE environment variable not set. Set it to a valid profile.'
      profile_hint
      exit 1
  fi
  if [ ! -f "${profile_path}" ]; then
      echo 'Conan profile file not found at '"${profile_path}"
      profile_hint
      exit 1
  fi
}

function profile_warning() {
    if [ "${PROFILE}" == '${PROFILE}' ]; then
        echo '    Warning: $PROFILE not set. Set it to a valid profile.'
    elif [ ! -f "${profile_path}" ]; then
        echo '    Warning: $PROFILE is invalid; Conan profile file not found at '"${profile_path}"
        echo
    fi
}

function cmd_bt() {
  cmd_build
  cmd_test
}

function cmd_build() {
  require_valid_profile
  pushd "${build_dir}"
  conan build "${root_dir}"
  popd
  set +u
  if [[ "${1}" == "test" ]]; then
      set -u
      cmd_test
  fi
  set -u
}

function cmd_clean(){
    require_valid_profile
    if [ -d "${build_dir}" ]; then
        rm -r "${build_dir}"
    fi
}

function cmd_install() {
  require_valid_profile
  mkdir -p "${build_dir}"
  pushd "${build_dir}"
  conan install "${root_dir}" -pr="${profile_path}" --build missing
  popd
}

function cmd_package() {
  "${scripts_dir}"/package.sh "${@}"
}

function cmd_profiles(){
    local profiles=($(ls "${scripts_dir}/profiles"))
    echo "Profiles:"
    for profile in "${profiles[@]}"
    do
        echo "    ${profile}"
    done
    echo ""
    exit 1
}

function cmd_rebuild() {
  require_valid_profile
  pushd "${build_dir}"
  cmake --build .
  popd
  set +u
  if [[ "${1}" == "test" ]]; then
      set -u
      cmd_test
  fi
  set -u
}


function cmd_run() {
  cmd_install
  cmd_bt
}

function cmd_test() {

  pushd "${build_dir}"
  CTEST_OUTPUT_ON_FAILURE=1 ctest
  popd
}

function cmd_docs() {
  "${scripts_dir}"/docs.sh "${@}"
}

function cmd_st() {
  local st_project="${build_dir}/cil.sublime-project"
  echo '
  {
  "folders": [
    {
      "path": "'"${root_dir}"'"
    }
  ],
  "settings": {
    "ecc_flags_sources": [
      {
        "file": "CMakeLists.txt",
        "flags":
        [
            "-DCMAKE_MODULE_PATH:FILEPATH=\"\";${project_path:${folder}}"
        ]
      }
    ],
  },
  "build_systems": [
    {
      "file_regex": "(^.*\\.[a-z]*):([0-9]*)",
      "name": "build",
      "env": {
      },
      "working_dir": "${project_path:${folder}}",
      "cmd": [
        "cmake",
        "--build",
        "${project_path:${folder}}",
        "--",
        "-j4"
      ]
    }
  ]
}
' > "${st_project}"
  echo "Wrote new file to \"${st_project}\"."
  echo 'Calling Sublime Text...'
  subl "${st_project}"
}


function show_help() {
    echo "Usage: ${script_name} [command]"
    echo "
    Commands:
          bt           - build and run ctest in ${build_dir}
          build        - build in ${build_dir}
          clean        - Erase ${build_dir}
          install      - install to ${build_dir}
          package      - create and test package
          profiles     - list profiles
          rebuild      - calls CMake directly in ${build_dir}
          run          - install, build, and test
          test         - run ctest in ${build_dir}
          docs         - build docs in ${output_dir}/docs
          st           - create Sublime Text project

    TODO: maybe remove build and run? 'conan build' and 'conan run' replace them
    "

    profile_warning
}


if [ $# -lt 1 ]; then
    show_help
    exit 1
fi

readonly cmd="${1}"
shift 1;

case "${cmd}" in
    "bt" ) cmd_bt $@ ;;
    "build" ) cmd_build $@ ;;
    "clean" ) cmd_clean $@ ;;
    "install" ) cmd_install $@ ;;
    "package" ) cmd_package $@ ;;
    "profiles" ) cmd_profiles $@ ;;
    "rebuild" ) cmd_rebuild $@ ;;
    "run" ) cmd_run $@ ;;
    "test" ) cmd_test $@ ;;
    "docs" ) cmd_docs $@ ;;
    "st" ) cmd_st $@ ;;
    * )
        echo "'${cmd}' is not a valid command."
        echo
        show_help
        exit 1
esac
