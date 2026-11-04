#!/usr/bin/env bash
# Check that the pre-specified files still match ratings/holdout/PRESPEC.sha256.
# The recorded paths predate the move into llm_annotation/, so match by file name.
set -u
cd "$(dirname "$0")/.."
status=0
while read -r hash path; do
  case $(basename "$path") in
    prespecification.md) f=../docs/prespecification.md ;;
    *) f=prompts/$(basename "$path") ;;
  esac
  if [ "$(shasum -a 256 "$f" | cut -d' ' -f1)" = "$hash" ]; then
    echo "OK       $f"
  else
    echo "CHANGED  $f" >&2; status=1
  fi
done < ratings/holdout/PRESPEC.sha256
exit $status
