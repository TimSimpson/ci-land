#!/bin/bash
if [ "${TRAVIS_BUILD_DIR}" == '' ]; then
    echo "This is intended too run on Travis CI."
    exit 1
fi
set -e
set -x

readonly scripts_dir="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

if [[ "$(uname -s)" == 'Darwin' ]]; then
    if which pyenv > /dev/null; then
        eval "$(pyenv init -)"
    fi
    pyenv activate conan
else
    export PATH="$(pwd)/venv/bin:${PATH}"
fi

echo 'What version of Python is this?'
python --version

"${scripts_dir}"/../run.sh
