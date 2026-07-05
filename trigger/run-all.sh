#!/usr/bin/env bash
# run-all.sh — execute every per-section script after 00-setup.sql.
# Usage:  ./run-all.sh           (uses mysql -u root -p, prompts for password)
#   or:   ./run-all.sh --no-pw   (assumes passwordless local root on macOS brew)
set -euo pipefail

MYSQL="mysql"

USER="root"
case "${1:-}" in
  --no-pw) ARGS=(--protocol=local -u "$USER") ;;
  *)       ARGS=(-u "$USER" -p) ;;
esac

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "==> 00-setup.sql"
"$MYSQL" "${ARGS[@]}" < 00-setup.sql

for section_dir in [0-9]*-*; do
  echo "==> $section_dir/setup-*.sql"
  for f in "$section_dir"/setup-*.sql; do
    [ -f "$f" ] || continue
    echo "    -> $(basename "$f")"
    "$MYSQL" "${ARGS[@]}" < "$f" || echo "    !! failed: $f (continuing)"
  done
  echo "==> $section_dir/example-*.sql"
  for f in "$section_dir"/example-*.sql; do
    [ -f "$f" ] || continue
    echo "    -> $(basename "$f")"
    "$MYSQL" "${ARGS[@]}" < "$f" || echo "    !! failed: $f (continuing)"
  done
done

echo "Done."