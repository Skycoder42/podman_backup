#!/bin/bash
set -eo pipefail

mkdir -p .git/hooks

cat << EOF > .git/hooks/pre-commit
#!/bin/bash
set -eo pipefail

exec dart run dart_pre_commit
EOF
chmod a+x .git/hooks/pre-commit
