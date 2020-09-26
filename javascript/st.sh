#! /bin/bash
set -euo pipefail

readonly root_dir="$(pwd)"

if [ -f "package.json" ]; then
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
      "file_regex": "(^.*\\.[a-z]*)\\(([0-9]*)\\,([0-9]*)\\): error",
      "name": "lint",
      "working_dir": "${project_path:${folder}}",
      "cmd": ["npm", "run", "lint"]
    },
    {
      "file_regex": "\\[error\\] ([^\\:]*)",
      "name": "format",
      "working_dir": "${project_path:${folder}}",
      "cmd": ["npm", "run", "format"]
    },
    {
      "file_regex": "\\(([^\\:]*)\\:([0-9]*)\\:([0-9]*)\\)",
      "name": "tests",
      "working_dir": "${project_path:${folder}}",
      "cmd": ["npm", "run", "tests"],
      "target": "terminus_exec"
    }
  ]
}
' > "${st_project}"
  echo "Wrote new file to \"${st_project}\"."
  echo 'Calling Sublime Text...'
  subl "${st_project}"
else

  echo "This doesn't look like a Javascript project to me."
fi
