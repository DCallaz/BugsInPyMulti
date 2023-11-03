#!/bin/bash
for proj in *; do
  echo "$proj";
  for bug in "$proj"/bugs/*; do
    echo "$bug"
    if [ -d "$bug" ]; then
      t=()
      while IFS="" read -r run_test || [ -n "$run_test" ]; do
        s="s/^\(pytest\( -q -s\)\?\|python -m unittest -q\|python3 -m pytest\|py.test\|tox\) //g"
        t+=($(echo "$run_test" | sed "$s"))
      done < "$bug"/run_test.sh
      for tst in "${t[@]}"; do
        echo "  $tst"
      done
    fi
  done
done
