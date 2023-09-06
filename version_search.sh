#!/bin/bash
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
reset=`tput sgr0`
USAGE="USAGE: ./version_search.sh [-l] <project>"
log_dir="$PWD/versions"
while getopts ":hl:" opt; do
  case ${opt} in
    l )
      log_dir=$OPTARG
      ;;
    h )
      echo "$USAGE"
      ;;
    \? )
      echo "$USAGE"
      ;;
  esac
done
shift $((OPTIND -1))
if [ $# -lt 1 ]; then
  echo $USAGE
  exit 0
fi
project=$1
top_dir="$PWD"
log_dir="$(readlink -f "$(echo ${log_dir/"~"/~})")"
mkdir -p "$log_dir/$project"
temp="$PWD/temp"
if [ ! -d "$temp" ]; then
  mkdir -p "$temp"
fi
bugs=$(bugsinpy-info -p $project | grep "Number of bugs" | cut -d ':' -f 2 | xargs)
cd "$temp"
echo "${blue}Checking out versions...${reset}"
for (( b=1; b<=$bugs; b++ )); do
  echo "  $project-$b"
  # create the log dir for this version
  mkdir -p "$log_dir/$project/$b"
  # Skip downloading project if it is already there
  if [ -d $temp/$project-$b ]; then
    cd "$project-$b/$project"
    # Revert to working changes
    git restore .
    git reset > /dev/null
    git add -A .
    cd "$temp"
    continue
  fi
  bugsinpy-checkout -p $project -i $b -v 0 -w $temp/$project-$b &> /dev/null
  cd "$project-$b/$project"
  # Compile the project
  bugsinpy-compile &> /dev/null
  # Track the current changes so we can return to them
  git add -A .
  cd "$temp"
done
echo "${blue}Done checking out versions.${reset}"
for (( b=1; b<=$bugs; b++ )); do
  # Collect the tests for version b
  unset test_diffs
  unset test_pts
  declare -A test_diffs
  declare -A test_pts
  cd "$project-$b/$project"
  # Revert to working changes (sanity check)
  git restore .
  git reset > /dev/null
  git add -A .
  if [ ! -f "bugsinpy_run_test.sh" ]; then
    echo "${red}ERROR: Could not find run_test.sh for bug $b${reset}"
    continue
  fi
  tests=()
  while IFS="" read -r run_test || [ -n "$run_test" ]; do
    s="s/^\(pytest\( -q -s\)\?\|python -m unittest -q\|python3 -m pytest\|py.test\|tox\) //g"
    tests+=($(echo "$run_test" | sed "$s"))
  done < bugsinpy_run_test.sh
  #echo "Bug $b's tests: ${tests[@]}"
  unittest=0
  if [ "$(grep unittest bugsinpy_run_test.sh)" ]; then
    unittest=1
  fi
  # Process tests and collect test diffs
  for t in "${tests[@]}"; do
    if [ "$unittest" -eq 1 ]; then
      awk_cmd='match($0, /(.+)\.([A-Z][^.]*)\.([^.]+)/, ary) {print ary[1],ary[2],ary[3]}'
    else
      awk_cmd='match($0, /(.+)\.py(::([A-Z][^:]*))?::(.+)/, ary) {print ary[1],ary[3],ary[4]}'
    fi
    test_pts[$t]="$(echo "$t" | awk "$awk_cmd" | sed 's/\//./g')"
    test_diffs[$t]="$($top_dir/cut ${test_pts[$t]})"
    echo "${test_diffs[$t]}" > "$log_dir/$project/$b/${test_pts[@]// /.}.patch"
  done
  cd "$temp"
  # Done collecting tests
  #echo "${test_diffs[@]}"
  for (( v=$b+1; v<=$bugs; v++ )); do
    echo "${blue}Transplanting bug $b in version $v${reset}"
    #echo "${diff[$b]}"
    cd "$project-$v/$project"
    # check expected and actual outputs for each test
    brk=1
    for t in "${tests[@]}"; do
      # Splice in the code for this test for bug b
      echo "${test_diffs[$t]}" | $top_dir/splice ${test_pts[$t]}
      # Get expected and actual output for test
      expected_output="$(bugsinpy-test -t "$t")"
      test_output="$(bugsinpy-test -t "$t")"

      if [ "$unittest" == 1 ]; then
        awk_cmd='/-{70}/{n++;next};n%2==1'
        grp='^\(Traceback\|[ ]\+File\|$\)'
        expected_error=$(echo "$expected_output" | awk "$awk_cmd" | grep -v "$grp" | sed 's/ : .*//g' | tail -n 2)
        test_error=$(echo "$test_output" | awk "$awk_cmd" | grep -v "$grp" | sed 's/ : .*//g' | tail -n 2)
        sed_cmd='s/FAIL.*/fail/g;s/ERROR.*/error/g'
        fail_or_error=$(echo "$test_output" | grep "^\(FAIL\|ERROR\):" | sed "$sed_cmd")
      else
        expected_error=$(echo "$expected_output" | grep "^E\s\+")
        test_error=$(echo "$test_output" | grep "^E\s\+")
        sed_cmd='s/.*FAILURES.*/fail/g;s/.*ERRORS.*/error/g'
        fail_or_error=$(echo "$test_output" | grep "=\+ \(FAILURES\|ERRORS\)" | sed "$sed_cmd")
      fi
      if [ "$fail_or_error" == "error" ]; then
        echo "${yellow}  failed to compile test case${reset}"
        echo "$test_output"
      elif [ "$fail_or_error" == "fail" ]; then
        if [ "$test_error" != "$expected_error" ]; then
          echo "${yellow}  error messages do not match${reset}"
          echo "  Found:"
          echo "  $test_error"
          echo "  Expected:"
          echo "  $expected_error"
        else
          echo "${green}  success!${reset}"
          echo "$b" >> "$log_dir/$project/$v/bugs.txt"
          echo "${test_pts[$t]}" > "$log_dir/$project/$v/$b.test"
          echo "${test_diffs[$t]}" > "$log_dir/$project/$v/$b.diff"
          brk=0
        fi
      else
        echo "${yellow}  test case passing${reset}"
        echo "$test_output"
      fi
    done
    # Revert to working changes
    git restore .
    git reset > /dev/null
    git add -A .
    #echo "$diff" | patch -R -p1
    cd "$temp"
    if [ "$brk" -eq 1 ]; then
      break
    fi
  done
done
#for (( b=1; b<=$bugs; b++ )); do
  #rm -rf "$project-$b"
#done
