import argparse
import configparser
import os
import pathlib
import sys
import typing as t

from . import appveyor
from . import travis

class ConfFile:
    def __init__(self, git_sha: str, routines: t.List[str], travis_env: t.List[str]) -> None:
        self.git_sha = git_sha
        self.routines = routines
        self.travis_env = travis_env


def load_conf(path: pathlib.Path) -> ConfFile:
    git_sha = os.environ["CI_LAND_SHA"]

    with open(path) as f:
        lines = f.readlines()

    routines: t.List[str] = []
    travis_env: t.List[str] = []

    index = 1
    section = None
    for index, line in enumerate(lines):
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        elif stripped.startswith('[') and stripped.endswith(']'):
            section = stripped
        elif section == '[routines]':
            routines.append(stripped)
        elif section == '[travis_env]':
            travis_env.append(stripped)
        else:
            raise RuntimeError(f"What the heck is at line {index}? {line}")

    return ConfFile(git_sha, routines, travis_env)


def print_conf_details(conf: ConfFile) -> None:
    print(f"Using ci-land {conf.git_sha}")
    for routine in conf.routines:
        print(f" * {routine}")


def create_appveyor_yml(conf: ConfFile, root: pathlib.Path) -> None:
    appveyor_path = root / "appveyor.yml"
    appveyor_contents = appveyor.generate_contents(git_sha=conf.git_sha, routines=conf.routines)
    with open(appveyor_path, "w") as f:
        f.write(appveyor_contents)


def create_travis_yml(conf: ConfFile, root: pathlib.Path) -> None:
    travis_path = root / ".travis.yml"
    travis_contents = travis.generate_contents(git_sha=conf.git_sha, routines=conf.routines, extra_env=conf.travis_env)
    with open(travis_path, "w") as f:
        f.write(travis_contents)


def format(project_path: pathlib.Path) -> None:
    conf_path = project_path.parent / ".cil.conf"
    if not conf_path.exists:
        raise RuntimeError(f"Cannot find configuration at {conf_path}.")
    conf = load_conf(conf_path)
    print_conf_details(conf)
    create_appveyor_yml(conf, project_path.parent)
    create_travis_yml(conf, project_path.parent)

def main() -> int:
    parser = argparse.ArgumentParser(
        "cil-format",
        description="Formats configs needed to run CI."
    )
    parser.add_argument("--project_path", type=str, help="Path to a project to format.", default=".")
    args = parser.parse_args()
    project_path = pathlib.Path(args.project_path)
    if not project_path.exists():
        print(f"Invalid path: {project_path}")
        sys.exit(1)
    format(project_path)
    sys.exit(0)
