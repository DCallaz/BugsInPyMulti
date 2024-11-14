#!/bin/bash

open_sem() {
  mkfifo pipe-$$
  exec 3<>pipe-$$
  rm pipe-$$
  local i=$1
  for((;i>0;i--)); do
    printf %s 000 >&3
  done
}

run_with_lock() {
  local x
  # this read waits until there is something to read
  read -u 3 -n 3 x && ((0==x)) || exit $x
  (
   ( "$@"; )
  # push the return code of the command to the semaphore
  printf '%.3d' $? >&3
  )&
}

run_one() {
  local project="$1"
  local version="$2"
  if [ -d "$save_dir/$project/$version" ]; then
    echo "$version: Skipping..."
    return
  fi
  ./gen_one.sh ${v_dir:+-V "$v_dir"} -p "$project" -i "$version" \
    -w "$bip/tmp/$project-$version" &> /dev/null
  if [ $? -ne 0 ]; then
    echo "$version: Skipping..."
    return
  fi
  mkdir -p "$save_dir/$project/$version"
  cp "$bip/tmp/$project-$version/$project/coverage_alltest_bugsinpy.txt" "$save_dir/$project/$version/"
  if [ -f "$bip/tmp/$project-$version/$project/coverage.json" ]; then
    tar -C "$bip/tmp/$project-$version/$project" -czf \
      "$save_dir/$project/$version/coverage.json.tgz" "coverage.json"
    if [ -f "$bip/tmp/$project-$version/$project/coverage.tcm" ]; then
      cp "$bip/tmp/$project-$version/$project/coverage.tcm" "$save_dir/$project/$version/"
    else
      echo "WARNING: $project $version has no coverage.tcm file"
    fi
  else
    echo "WARNING: $project $version has no coverage.json file"
  fi
  if [ "$(find "$bip/tmp/$project-$version/$project" -name "bug.locations.*")" ]; then
    cp $bip/tmp/"$project-$version"/"$project"/bug.locations.* "$save_dir/$project/$version/"
  fi
  rm -rf "$bip/tmp/$project-$version/"
  echo "$version: Done."
}

USAGE="USAGE: ./generate_coverage.sh [-p <project>] [-V <version dir>] <save dir>"
N=8
open_sem $N
bip="$PWD"
if [ $# -lt 1 ]; then
  echo "$USAGE"
  exit 0
fi
while getopts ":hp:V:" opt; do
  case ${opt} in
    h )
      echo "$USAGE"
      exit 0
      ;;
    p )
      project="$OPTARG"
      ;;
    V )
      v_dir="$OPTARG"
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      echo "$USAGE"
      exit 0
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      echo "$USAGE"
      exit 0
      ;;
  esac
done
shift $((OPTIND -1))
save_dir="$1"
save_dir="$(readlink -f "$(echo ${save_dir/"~"/~})")"
home="$PWD"
mkdir -p "$save_dir"
if [ ! -d "$bip/tmp" ]; then
  mkdir -p "$bip/tmp"
fi
if [ ! "$project" ]; then
  project="$(cat projects.txt)"
fi
for project in $project; do
  echo "$project"
  versions="$(python3 framework/bin/dump_versions.py ${v_dir:+-v "$v_dir" } "$project" |
    awk -F- '{print $NF}')"
  for version in $versions; do
    run_with_lock run_one $project $version
  done
  # wait for all the versions to finish before moving onto the next project
  wait
done
