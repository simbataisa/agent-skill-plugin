#!/usr/bin/env bash
set -euo pipefail

# Check for direct database mutation commands
# Takes $1 as the bash command string
# Warns if direct DB mutations are detected without migration files

command="${1:-.}"

# Check for SQL mutation patterns: INSERT, UPDATE, DELETE, DROP, ALTER
if echo "${command}" | grep -iE "(psql.*INSERT|psql.*UPDATE|psql.*DELETE|psql.*DROP|psql.*ALTER|mysql\s+-e.*INSERT|mysql\s+-e.*UPDATE|mysql\s+-e.*DELETE)" &>/dev/null; then
  echo "⚠️  BMAD: Direct DB mutation detected. Use migration files (Flyway/Liquibase/golang-migrate) instead of running SQL directly." >&2
  exit 0
fi

exit 0
