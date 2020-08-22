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

readonly output_root_dir="${root_dir}/output/package"
readonly output_dir="${output_root_dir}/${PROFILE}"
readonly source_folder="${output_dir}"/source
readonly install_folder="${output_dir}"/install
readonly build_folder="${output_dir}"/build
readonly package_folder="${output_dir}"/package

# export CONAN_V2_MODE=true

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
    if [ ! -f "${profile_path}" ]; then
        echo '    Warning: $PROFILE is invalid; Conan profile file not found at '"${profile_path}"
        echo
    fi
}

# Extracts the package and version from the root conan file.

function print_name_and_version(){
    PYTHONPATH="${scripts_dir}"/version_extractor python3 conanfile.py
}

function print_package_reference(){
    local package_name_and_version=$1
    echo "${package_name_and_version}"@"${CONAN_USERNAME:-_}"/"${CONAN_CHANNEL:-_}"
}



function check_upload_settings(){
    # Call this to abort the program if the user hasn't set the username /
    # channel to something serious.
    if [ "${CONAN_USERNAME:-_}" == "_" ]; then
        echo "CONAN_USERNAME is not set. Aborting!"
        exit 1;
    fi
    if [ "${CONAN_CHANNEL:-_}" == "_" ]; then
        echo "CONAN_CHANNEL is not set. Aborting!"
        exit 1;
    fi
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

function cmd_settings(){
    local package_name_and_version=`print_name_and_version`
    local package_reference=`print_package_reference "${package_name_and_version}"`

    echo "
    Paths:
          package_reference        - ${package_reference}
          package_name_and_version - ${package_name_and_version}
          source_folder            - ${source_folder}
          install_folder           - ${install_folder}
          build_folder             - ${build_folder}
          package_folder           - ${package_folder}
    "
    profile_warning
}

function cmd_clean(){
    require_valid_profile
    if [ -d "${output_dir}" ]; then
        rm -r "${output_dir}"
    fi
    if [ -d "${root_dir}"/test_package/build ]; then
        rm -r "${root_dir}"/test_package/build
    fi
    local package_name_and_version=`print_name_and_version`
    local package_reference=`print_package_reference "${package_name_and_version}"`
    set +e
    conan remove -f "${package_reference}"
    set -e
}

function cmd_source(){
    require_valid_profile
    mkdir -p "${source_folder}"
    conan source . --source-folder="${source_folder}"
}

function cmd_install(){
    export CONAN_SKIP_TESTS=true
    require_valid_profile
    mkdir -p "${install_folder}"
    conan install . --install-folder="${install_folder}" -pr="${profile_path}"  --build missing
}

function cmd_build(){
    export CONAN_SKIP_TESTS=true
    require_valid_profile
    mkdir -p "${build_folder}"
    conan build . "--source-folder=${source_folder}" "--install-folder=${install_folder}" "--build-folder=${build_folder}"
}

function cmd_package(){
    export CONAN_SKIP_TESTS=true
    require_valid_profile
    mkdir -p "${package_folder}"
    conan package . "--source-folder=${source_folder}" "--install-folder=${install_folder}" "--build-folder=${build_folder}" "--package=${package_folder}"
}

function cmd_export(){
    export CONAN_SKIP_TESTS=true
    require_valid_profile
    local package_name_and_version=`print_name_and_version`
    local package_reference=`print_package_reference "${package_name_and_version}"`
    set +e
    conan remove -f "${package_reference}"
    set -e
    conan export-pkg . -f "--package=${package_folder}" -pr="${profile_path}"
}

function cmd_test(){
    export CONAN_SKIP_TESTS=true
    require_valid_profile
    pushd "${build_folder}"
    ctest "${@}"
    popd
}

function cmd_test_package(){
    local test_package_dir="${1:-test_package}"

    export CONAN_SKIP_TESTS=true
    require_valid_profile
    local package_name_and_version=`print_name_and_version`
    local package_reference=`print_package_reference "${package_name_and_version}"`

    conan test "${test_package_dir}" -pr="${profile_path}"  --build missing "${package_reference}"
}

function announce() {
    set +e
    which figlet
    if [ "${?}" -eq 0 ]; then
        figlet -f pagga "${@}"
    fi
    set -e
}

function cmd_all(){
    require_valid_profile
    announce clean
    cmd_clean
    cmd_re_all
}

function cmd_re_all(){
    announce source
    cmd_source
    announce install
    cmd_install
    announce build
    cmd_build
    announce test
    cmd_test
    announce package
    cmd_package
    announce export
    cmd_export
    announce test package
    cmd_test_package
}

function cmd_create() {
    export CONAN_SKIP_TESTS=true
    require_valid_profile
    local package_name_and_version=`print_name_and_version`
    local package_reference=`print_package_reference "${package_name_and_version}"`
    conan create . "${package_reference}" -pr="${profile_path}"
}

function cmd_upload(){
    require_valid_profile

    local package_name_and_version=`print_name_and_version`
    local package_reference=`print_package_reference "${package_name_and_version}"`

    check_upload_settings
    conan upload "${package_reference}" --all -r richter
}

function show_help() {
    local package_name_and_version=`print_name_and_version`
    local package_reference=`print_package_reference "${package_name_and_version}"`

    echo "Usage: ${script_name} [command]"
    echo "
    Commands:
          profiles     - List all profiles in ${scripts_dir}/profiles
          clean        - Erase ${output_dir}
          source       - run conan source, put in ${source_folder}
          install      - install to ${install_folder}
          build        - build in ${build_folder}
          package      - package in ${package_folder}
          export       - export package to local cache
          test         - tests binaries in ${build_folder}
          test_package - tests package "${package_name_and_version}"
          all          - do all of the above
          re-all       - like all, but skips clean
          create       - run conan create
          upload       - uploads "${package_reference}"
          settings     - show paths and other variables
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
    "profiles" ) cmd_profiles $@ ;;
    "clean" ) cmd_clean $@ ;;
    "source" ) cmd_source $@ ;;
    "install" ) cmd_install $@ ;;
    "build" ) cmd_build $@ ;;
    "package" ) cmd_package $@ ;;
    "export" ) cmd_export $@ ;;
    "test" ) cmd_test $@ ;;
    "test_package" ) cmd_test_package $@ ;;
    "create" ) cmd_create $@ ;;
    "all" ) cmd_all $@ ;;
    "re-all" ) cmd_re_all $@ ;;
    "upload" ) cmd_upload $@ ;;
    "settings" ) cmd_settings $@ ;;
    * )
        echo "'${cmd}' is not a valid command."
        echo
        show_help
        exit 1
esac
