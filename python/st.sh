#! /bin/bash
set -euo pipefail

readonly root_dir="$(pwd)"

if [ -f "pyproject.toml" ]; then
  readonly st_project="cil.sublime-project"
  echo '
  {
  "folders": [
    {
      "path": "'"${root_dir}"'"
    }
  ],
  "build_systems": [
    {
      "file_regex": "(^.*\\.[a-z]*):([0-9]*)",
      "name": "poetry run task checks",
      "working_dir": "${project_path:${folder}}",
      "shell_cmd": [
        "poetry",
        "run",
        "task",
        "checks"
      ]
    }
  ]
}
' > "${st_project}"
  echo "Wrote new file to \"${st_project}\"."
  echo 'Calling Sublime Text...'
  subl "${st_project}"
else

  echo "This doesn't look like a Python project to me."
fi
