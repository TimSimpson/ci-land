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

function cmd_build() {
  require_valid_profile
  pushd "${build_dir}"
  conan build "${root_dir}"
  popd
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

function cmd_run() {
  cmd_install
  cmd_build
  cmd_test
}

function cmd_test() {
  pushd "${build_dir}"
  ctest
  popd
}


function show_help() {
    echo "Usage: ${script_name} [command]"
    echo "
    Commands:
          build        - build in ${build_dir}
          clean        - Erase ${build_dir}
          install      - install to ${build_dir}
          package      - create and test package
          profiles     - list profiles
          run          - install, build, and test
          test         - run ctest in ${build_dir}
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
    "build" ) cmd_build $@ ;;
    "clean" ) cmd_clean $@ ;;
    "install" ) cmd_install $@ ;;
    "package" ) cmd_package $@ ;;
    "profiles" ) cmd_profiles $@ ;;
    "run" ) cmd_run $@ ;;
    "test" ) cmd_test $@ ;;
    * )
        echo "'${cmd}' is not a valid command."
        echo
        show_help
        exit 1
esac
