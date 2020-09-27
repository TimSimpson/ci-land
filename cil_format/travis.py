import typing as t


OPENING = """language: cpp

clang-linux: &clang-linux
  os: linux
  dist: bionic
  python: "3.7"
  compiler: clang
  addons:
    apt:
      sources:
        - ubuntu-toolchain-r-test
        - llvm-toolchain-bionic-8
      packages:
        - clang-8
        - libstdc++-8-dev
        - python3-pip
        - xorg-dev
        - libx11-xcb-dev
        - libxcb-render0-dev
        - libxcb-render-util0-dev
        - libxcb-xkb-dev
        - libxcb-icccm4-dev
        - libxcb-image0-dev
        - libxcb-keysyms1-dev
        - libxcb-shape0-dev
        - libxcb-sync-dev
        - libxcb-xfixes0-dev
        - libxcb-xinerama0-dev
        - libxcb-randr0-dev
        - autoconf

emscripten: &emscripten
  os: linux
  dist: bionic
  python: "3.7"
  compiler: clang
  addons:
    apt:
      packages:
        - python3-pip

osx: &osx
   os: osx
   language: generic
   osx_image: xcode11.3

install:
  - git clone https://github.com/TimSimpson/ci-land.git ci
  - pushd ci && git checkout {git_sha} && popd
  - ./ci/cpp/conan/travis/install.sh

script:
  - git submodule update --init --recursive
  - ./ci/cpp/conan/travis/run.sh

matrix:
  include:
"""

DOCS_MATRIX = """
    - name: "Docs"
      language: python
      os: linux
      dist: bionic
      python: "3.7"
      addons:
        apt:
          packages:
            - python3-pip
            - pandoc
      script:
        - ./ci/cpp/conan/travis/docs.sh
"""

CUTE_NAMES = {
    "clang-8-r-static": "Linux Clang 8.0 Release",
    "clang-8-d-static": "Linux Clang 8.0 Debug",
    "emscripten-w-r": "Emscripten WASM Release",
    "emscripten-js-d": "Emscripten Javascript Debug",
}

def generate_contents(git_sha: str, routines: t.List[str], extra_env: t.List[str]) -> str:
    lines: t.List[str] = []
    lines.extend(OPENING.format(git_sha=git_sha).split("\n"))

    for routine in routines:
        if 'msvc' in routine:
            continue
        elif routine == 'cpp/docs':
            lines.extend(DOCS_MATRIX.split('\n'))
        else:
            profile = routine.split("/")[-1]
            cute_name = CUTE_NAMES[profile]
            lines.append(f'    - name: "{cute_name}"')
            lines.append(f'      <<: *clang-linux')
            lines.append(f'      env:')
            lines.append(f'        - PROFILE={profile}')

    lines.append("env:")
    lines.append("  global:")

    for e in extra_env:
        lines.append(f"    - {e}")

    return "\n".join(lines)
