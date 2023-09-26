#!/bin/bash
if [ $# -lt 1 ]; then
  echo "USAGE: ./make_tree.sh <project> [<log dir>]"
  exit 0
fi
project="$1"
log_dir="versions"
if [ $# -gt 1 ]; then
  log_dir="$2"
fi
for version in "$log_dir"/"$project"/*; do
  bugs=""
  if [ -f "$version/bugs.txt" ]; then
    bugs="$(cat "$version/bugs.txt" | cut -d ',' -f 1 | sort -nr | uniq | tr '\n' ' ')"
  fi
  echo "$bugs"
done | sort -n -k 1 | while read line; do echo $line | sed 's/ /\n/g' | sort -n | xargs; done
