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
  ./gen_one.sh -p "$project" -i "$version" -w "/tmp/$project-$version" &> /dev/null
  if [ $? -ne 0 ]; then
    echo "$version: Skipping..."
    return
  fi
  mkdir -p "$save_dir/$project/$version"
  cp "/tmp/$project-$version/$project/coverage_alltest_bugsinpy.txt" "$save_dir/$project/$version/"
  cp "/tmp/$project-$version/$project/coverage.tcm" "$save_dir/$project/$version/"
  if [ "$(find "/tmp/$project-$version/$project" -name "bug.locations.*")" ]; then
    cp /tmp/"$project-$version"/"$project"/bug.locations.* "$save_dir/$project/$version/"
  fi
  rm -rf "/tmp/$project-$version/"
  echo "$version: Done."
}

USAGE="USAGE: ./generate_coverage.sh [-p <project>] <save dir>"
N=2
open_sem $N
if [ $# -lt 1 ]; then
  echo "$USAGE"
  exit 0
fi
while getopts ":hp:" opt; do
  case ${opt} in
    h )
      echo "$USAGE"
      exit 0
      ;;
    p )
      project=$OPTARG
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
if [ ! "$project" ]; then
  project="$(cat projects.txt)"
fi
for project in $project; do
  echo "$project"
  for version in $(python3 dump_versions.py "$project" | awk -F- '{print $NF}'); do
    run_with_lock run_one $project $version
  done
  # wait for all the versions to finish before moving onto the next project
  wait
done
