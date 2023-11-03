#!/bin/bash
i=0
lines=($(cat bugsinpy-bugs.csv))
home="$PWD"
while [ $i -lt "${#lines[@]}" ]; do
  echo "$i ${lines[$i]}"
  project="${lines[$i]%,*}"
  bugs="${lines[$i]#*,}"
  out=$(bugsinpy-checkout -p "$project" -i 1 -v 1 -w "$PWD" 2>&1 >/dev/null)
  echo "$project"
  cd "$project"
  i=$((i+1))
  entries=""
  for (( j=1; j<=$bugs; j++)); do
    sha="${lines[$i]}"
    date_num="$(git show --no-patch --format=%at $sha)"
    #date="$(git show --no-patch --format=%ci $sha)"
    entries+="$date_num $j\n"
    i=$((i+1))
  done
  cd ../
  order="$(echo -e "${entries::-2}" | sort -k1n | cut -d ' ' -f 2)"
  echo "Order before:"
  echo "$order"
  j="$bugs"
  new=0
  for ver in $order; do
    if [ "$ver" != "$j" ]; then
      new=1
      echo "Moving $ver to $j"
      mv "$home/projects/$project/bugs/$ver" "$home/projects/$project/bugs/$j-new"
    fi
    ((j--))
  done
  if [ "$new" == "1" ]; then
    rename 's/-new$//' "$home"/projects/"$project"/bugs/*-new
  fi
  rm -rf "$project"
done
