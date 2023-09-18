#!/bin/bash
for project in $(cat projects.txt); do
  num_bugs="$(bugsinpy-info -p "$project" | grep "Number of bugs" | cut -d ':' -f 2 | xargs)"
  echo "$project,$num_bugs"
  for ((i=1; i<=$num_bugs; i++)); do
    sha="$(bugsinpy-info -p "$project" -i "$i" | awk '/Revision id/{getline; print}' | xargs)"
    echo "$sha"
  done
done
