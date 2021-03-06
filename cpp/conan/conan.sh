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

readonly output_dir="${root_dir}/output${CIL_OUTPUT_PREFIX:-}"
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

function cmd_info() {
  require_valid_profile
  mkdir -p "${output_dir}"
  pushd "${output_dir}"
  conan info "${root_dir}" -pr="${profile_path}"
  popd
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
      "name": "cmake build",
      "env": {
      },
      "working_dir": "${project_path:${folder}}",
      "cmd": [
        "cmake",
        "--build",
        "${project_path:${folder}}"
      ]
    },
    {
      "file_regex": "(^.*\\.[a-z]*):([0-9]*)",
      "name": "ctest",
      "working_dir": "${project_path:${folder}}",
      "env": {
        "CTEST_OUTPUT_ON_FAILURE": "1"
      },
      "cmd": [
        "ctest"
      ]
    }
  ]
}
' > "${st_project}"
  echo "Wrote new file to \"${st_project}\"."
  echo 'Calling Sublime Text...'
  subl "${st_project}"
}

function cmd_vsc() {
  # VSCode just HAS to put it's garbage here
  local vscode_build_path="${root_dir}/build"
  require_valid_profile
  mkdir -p "${vscode_build_path}"
  pushd "${vscode_build_path}"
  conan install "${root_dir}" -pr="${profile_path}" --build missing
  conan build "${root_dir}"
  popd
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
          info         - see the Conan dep graph
          st           - create Sublime Text project
          vsc          - run install and build in build dir for VSCode

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
    "info" ) cmd_info $@ ;;
    "st" ) cmd_st $@ ;;
    "vsc" ) cmd_vsc $@ ;;
    * )
        echo "'${cmd}' is not a valid command."
        echo
        show_help
        exit 1
esac
