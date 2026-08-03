#!/usr/bin/env bash
#
# Guards the one property `supabase db push` silently depends on: every file in
# supabase/migrations must have its own version number.
#
# The version is the leading digit group of the filename, and it is the primary
# key of `supabase_migrations.schema_migrations` on the remote. Two files that
# share one — which has now happened twice in this repo, 0070 and 0078, both
# times because two branches numbered "the next migration" the same before
# either had merged — cannot both be recorded. Whichever sorts second is either
# rejected or treated as already applied, so its DDL never reaches the database
# and nothing announces that. The feature it backed then fails in production
# against a schema that looks up to date.
#
# CI runs this on every PR; run it locally before adding a migration:
#
#   bash scripts/check-migrations.sh
#
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/supabase/migrations"
status=0

if [ ! -d "$dir" ]; then
  echo "check-migrations: $dir does not exist" >&2
  exit 1
fi

shopt -s nullglob
files=("$dir"/*.sql)
if [ ${#files[@]} -eq 0 ]; then
  echo "check-migrations: no migrations found in $dir" >&2
  exit 1
fi

# 1. Every filename must be <digits>_<name>.sql — anything else has no version
#    for the CLI to read.
for path in "${files[@]}"; do
  name="$(basename "$path")"
  if [[ ! "$name" =~ ^[0-9]+_[A-Za-z0-9_]+\.sql$ ]]; then
    echo "check-migrations: bad filename '$name' (expected <version>_<name>.sql)" >&2
    status=1
  fi
done

# 2. No two files may share a version.
dupes="$(
  for path in "${files[@]}"; do
    basename "$path" | sed -E 's/^([0-9]+)_.*/\1/'
  done | sort | uniq -d
)"

if [ -n "$dupes" ]; then
  while read -r version; do
    [ -n "$version" ] || continue
    echo "check-migrations: version $version is used by more than one migration:" >&2
    for path in "${files[@]}"; do
      name="$(basename "$path")"
      [[ "$name" == "${version}_"* ]] && echo "    $name" >&2
    done
    echo "    → renumber the newer one to the next free version." >&2
    status=1
  done <<<"$dupes"
fi

if [ "$status" -eq 0 ]; then
  echo "check-migrations: ${#files[@]} migrations, all versions unique."
fi

exit "$status"
