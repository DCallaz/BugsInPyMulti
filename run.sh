#!/bin/bash
USAGE="USAGE: ./run.sh [-h] <project> <version>"
if [ $# -lt 2 ]; then
  echo $USAGE
  exit 0
fi
while getopts ":h" opt; do
  case ${opt} in
    h ) echo $USAGE; exit 0
      ;;
    \? ) echo $USAGE; exit 0
      ;;
  esac
done
shift $((OPTIND -1))
project=$1
version=$2
main=$PWD
temp="$main/temp"
#temp=$(readlink -f "$(echo ${3/"~"/~})")
bugsinpy-checkout -p $project -i $version -v 0 -w $temp/$project-$version-b
bugsinpy-checkout -p $project -i $version -v 1 -w $temp/$project-$version-f
bugs=()
for file in $(cat $temp/$project-$version-f/$project/bugsinpy_patchfile.info); do
  file=${file%;}
  diff="diff -u $temp/$project-$version-b/$project/$file $temp/$project-$version-f/$project/$file"
  echo $diff > temp_diff
  $diff >> temp_diff
  lines=$(java -jar DiffProcess.jar reader temp_diff)
  lines=${lines##*[}
  lines=${lines%%]*}
  lines=(${lines//, / })
  #filename=${file//\//.}
  filename=${file%;}
  for line in "${lines[@]}"; do
    bugs+=("$filename:$line")
  done
  rm temp_diff
done
#echo "Bugs:"
#echo "${bugs[@]}"
#echo "END"
cp .coveragerc $temp/$project-$version-b/$project/.coveragerc
cd $temp/$project-$version-b/$project
bugsinpy-compile
bugsinpy-coverage -a
coverage json --show-contexts --pretty-print
bugsinpy-to-tcm
for bug in "${bugs[@]}"; do
  line=$(grep -nF "$bug" coverage.tcm | cut -f 1 -d :)
  if [ "$line" ]; then
    sed -i "${line}s/$/ | 1/" coverage.tcm
  fi
done
cp coverage.tcm $main/$project-$version.tcm
cd $main
rm -rf $temp/$project-$version-b
rm -rf $temp/$project-$version-f
