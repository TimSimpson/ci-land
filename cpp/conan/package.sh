#! /bin/bash
if [ "${PROFILE}" == '' ]; then
    echo 'PROFILE environment variable not defined.'
    exit 1
fi

set -euo pipefail
readonly root_dir="$(pwd)"
readonly scripts_dir="${root_dir}/ci/cpp/conan"
readonly output_dir="${root_dir}/output/package"
readonly profile_path="${scripts_dir}/profiles/${PROFILE}"
readonly build_dir="${output_dir}/${PROFILE}"

readonly source_folder="${output_dir}"/source
readonly install_folder="${output_dir}"/install
readonly build_folder="${output_dir}"/build
readonly package_folder="${output_dir}"/package

if [ ! -f "${profile_path}" ]; then
    echo 'Conan profile file not found at '"${profile_path}"
    exit 1
fi

# Extracts the package and version from the root conan file.
readonly package_name_and_version=`"${scripts_dir}/print_version.sh"`

readonly package_reference="${package_name_and_version}"@"${CONAN_USERNAME:-_}"/"${CONAN_CHANNEL:-_}"

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

function cmd_settings(){
    echo "
    Paths:
          package_reference        - ${package_reference}
          package_name_and_version - ${package_name_and_version}
          source_folder            - ${source_folder}
          install_folder           - ${install_folder}
          build_folder             - ${build_folder}
          package_folder           - ${package_folder}
    "
}

function cmd_clean(){
    if [ -d "${output_dir}" ]; then
        rm -r "${output_dir}"
    fi
}

function cmd_source(){
    mkdir -p "${source_folder}"
    conan source . --source-folder="${source_folder}"
}

function cmd_install(){
    mkdir -p "${install_folder}"
    conan install . --install-folder="${install_folder}" -pr="${profile_path}"
}

function cmd_build(){
    mkdir -p "${build_folder}"
    conan build . "--source-folder=${source_folder}" "--install-folder=${install_folder}" "--build-folder=${build_folder}"
}

function cmd_package(){
    mkdir -p "${package_folder}"
    conan package . "--source-folder=${source_folder}" "--install-folder=${install_folder}" "--build-folder=${build_folder}" "--package=${package_folder}"
}

function cmd_export(){
    conan export-pkg . -f "--package=${package_folder}" -pr="${profile_path}"
}

function cmd_test(){
    conan test test_package -pr="${profile_path}" "${package_reference}"
}

function cmd_all(){
    cmd_clean
    cmd_source
    cmd_install
    cmd_build
    cmd_package
    cmd_export
    cmd_test
}

function cmd_upload(){
    check_upload_settings
    conan upload "${package_reference}" --all -r richter
}

function show_help() {
    echo "Usage: ${0} [command]"
    echo "
    Commands:
          clean       - Erase ${output_dir}
          source      - run conan source, put in ${source_folder}
          install     - install to ${install_folder}
          build       - build in ${build_folder}
          package     - package in ${package_folder}
          export      - export package to local cache
          test        - tests package "${package_name_and_version}"
          all         - do all of the above
          upload      - uploads "${package_reference}"
          settings    - show paths and other variables
    "
}

if [ $# -lt 1 ]; then
    show_help
    exit 1
fi

readonly cmd="${1}"
shift 1;

case "${cmd}" in
    "clean" ) cmd_clean $@;;
    "source" ) cmd_source $@;;
    "install" ) cmd_install $@;;
    "build" ) cmd_build $@;;
    "package" ) cmd_package $@;;
    "export" ) cmd_export $@;;
    "test" ) cmd_test $@;;
    "all" ) cmd_all $@;;
    "upload" ) cmd_upload $@;;
    "settings" ) cmd_settings $@;;
    * )
        echo "'${cmd}' is not a valid command."
        echo
        show_help
        exit 1
esac
