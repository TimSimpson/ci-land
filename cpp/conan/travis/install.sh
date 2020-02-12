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
    # Travis likes to change stuff around, so sometimes things just break.
    # Log what we're dealing with.
    python3 --version
    pip3 --version
    pip3 install setuptools
    pip3 install virtualenv
    python3 -m virtualenv "venv"
    export PATH="$(pwd)/venv/bin:${PATH}"
    pip install conan --upgrade
fi

# ~start-doc add-conan-repos
conan remote add bincrafters https://api.bintray.com/conan/bincrafters/public-conan
conan remote add richter https://api.bintray.com/conan/timsimpson/richter
# ~end-doc

conan user
