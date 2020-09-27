import typing as t


OPENING = """os: Visual Studio 2019

environment:
    PYTHON: "C:\\Python37"

    matrix:
"""

CLOSING = """
install:
  - git clone https://github.com/TimSimpson/ci-land.git ci
  - cd ci
  - git checkout {git_sha}
  - cd ..
  - ci\\cpp\\conan\\appveyor\\install.bat

build_script:
  - git submodule update --init --recursive
  - ci\\cpp\\conan\\appveyor\\run.bat %PROFILE%
"""


def generate_contents(git_sha: str, routines: t.List[str]) -> str:
    lines: t.List[str] = []
    lines.extend(OPENING.split("\n"))

    for routine in routines:
        if 'msvc' not in routine:
            continue
        profile = routine.split("/")[-1]
        lines.append(f"        - PROFILE:  {profile}")

    lines.extend(CLOSING.format(git_sha=git_sha).split("\n"))

    return "\n".join(lines)
