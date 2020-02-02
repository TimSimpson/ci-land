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

function cmd_clean(){
    rm -r "${output_dir}"
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
    if [ $# -lt 1 ]; then
        echo 'Expect the name of the package under test as an argument.'
        echo 'Example: `foobar/1.2.3.4`'
        exit 1
    fi
    local package_name="${1}"
    conan test test_package -pr="${profile_path}" \
        "${package_name}"@"${CONAN_USERNAME:-_}"/"${CONAN_CHANNEL:-_}"
}

function cmd_all(){
    if [ $# -lt 1 ]; then
        echo 'Expect the name of the package under test as an argument.'
        echo 'Example: `foobar/1.2.3.4`'
        exit 1
    fi
    local package_name="${1}"

    cmd_clean
    cmd_source
    cmd_install
    cmd_build
    cmd_package
    cmd_export
    cmd_test "${package_name}"
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
          test        - test package
          all         - do all of the above
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
    * )
        echo "'${cmd}' is not a valid command."
        echo
        show_help
        exit 1
esac
