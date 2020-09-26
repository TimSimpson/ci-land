#! /bin/bash
set -euo pipefail

npm run format
npm run lint
npm run tests
