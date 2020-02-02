#!/bin/bash
if [ "${TRAVIS_BUILD_DIR}" == '' ]; then
    echo "This is intended too run on Travis CI."
    exit 1
fi
set -e
set -x

readonly scripts_dir="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

export PATH="$(pwd)/venv/bin:${PATH}"

pip3 install mrst==0.6.1
pip3 install Sphinx==2.3.1

"${scripts_dir}"/../docs.sh
