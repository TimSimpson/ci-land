# cget / vcpkg helper scripts

This contains helper scripts for Cget and Vcpkg workflows.

It also uses environment variables and conventions defined by [cenv](https://github.com/TimSimpson/cenv).

## install.sh

This creates "c-environments" in the cenv root directory by

    1. calling cget init
    2. installing a fresh copy of vcpkg

cget creates a CMake toolchain file, and a "triplet" is created for the vcpkg file pointing to it. A link to vcpkg is also put inside of cget.
