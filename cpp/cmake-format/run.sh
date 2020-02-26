readonly relative_scripts_dir=$(dirname "${BASH_SOURCE[0]}")
readonly scripts_dir=$(cd "${relative_scripts_dir}" >/dev/null 2>&1 && pwd)

cmake-format -c "${scripts_dir}"/config.py -i ./CMakeLists.txt
