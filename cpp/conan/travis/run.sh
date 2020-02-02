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

echo '

    What is happening?
             Hreerm??!

'
echo "TRAVIS_BRANCH=${TRAVIS_BRANCH}"

"${scripts_dir}"/../package.sh settings

if [[ "${TRAVIS_BRANCH}" == 'master' ]]; then
    export CONAN_USERNAME=TimSimpson
    export CONAN_CHANNEL=testing
    "${scripts_dir}"/../package.sh upload
else
    "${scripts_dir}"/../package.sh all
fi
