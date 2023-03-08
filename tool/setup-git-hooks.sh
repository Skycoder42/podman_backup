#!/bin/bash
set -eo pipefail

mkdir -p .git/hooks
echo "#!/bin/sh" > .git/hooks/pre-commit
echo "set -eo pipefail" >> .git/hooks/pre-commit
echo "exec dart run dart_pre_commit" >> .git/hooks/pre-commit
chmod a+x .git/hooks/pre-commit
