#!/bin/bash
if [ $# -lt 1 ]; then
  echo "USAGE: ./generate_coverage.sh <save dir>"
  exit 0
fi
save_dir="$1"
save_dir="$(readlink -f "$(echo ${save_dir/"~"/~})")"
home="$PWD"
mkdir -p "$save_dir"
for project in $(cat projects.txt); do
  if [ "$project" == "keras" ]; then
    continue
  fi
  echo "$project"
  for version in $(python3 dump_versions.py "$project" | awk -F- '{print $NF}'); do
    echo -n "$version: "
    if [ -d "$save_dir/$project/$version" ]; then
      echo "Skipping..."
      continue
    fi
    ./gen_one.sh -p "$project" -i "$version" -w "/tmp/$project-$version" &> /dev/null
    mkdir -p "$save_dir/$project/$version"
    cp "/tmp/$project-$version/$project/coverage.tcm" "$save_dir/$project/$version/"
    if [ "$(find "/tmp/$project-$version/$project" -name "bug.locations.*")" ]; then
      cp /tmp/"$project-$version"/"$project"/bug.locations.* "$save_dir/$project/$version/"
    fi
    cd "$home"
    rm -rf "/tmp/$project-$version/"
    echo "Done."
  done
done
