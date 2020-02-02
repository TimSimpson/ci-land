#!/bin/bash
if [ "${TRAVIS_BUILD_DIR}" == '' ]; then
    echo "This is intended too run on Travis CI."
    exit 1
fi

set -e
set -x

if [[ "$(uname -s)" == 'Darwin' ]]; then
    brew update || brew update
    brew outdated pyenv || brew upgrade pyenv
    brew install pyenv-virtualenv

    if which pyenv > /dev/null; then
        eval "$(pyenv init -)"
    fi

    pyenv install 3.6.1
    pyenv virtualenv 3.6.1 conan
    pyenv rehash
    pyenv activate conan
    pip install conan --upgrade
else
    pip3 install virtualenv
    python3 -m virtualenv "venv"
    export PATH="$(pwd)/venv/bin:${PATH}"
    pip install conan --upgrade
fi

conan remote add bincrafters https://api.bintray.com/conan/bincrafters/public-conan
conan user
