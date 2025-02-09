#!/bin/bash
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
reset=`tput sgr0`
USAGE="USAGE: ./version_search.sh [-l <log dir>] <project>"
log_dir="$PWD/versions"
home="$PWD"
while getopts ":hl:" opt; do
  case ${opt} in
    l )
      log_dir=$OPTARG
      ;;
    h )
      echo "$USAGE"
      exit 0
      ;;
    \? )
      echo "$USAGE"
      exit 0
      ;;
  esac
done
shift $((OPTIND -1))
if [ $# -lt 1 ]; then
  echo $USAGE
  exit 0
fi
project=$1
log_dir="$(readlink -f "$(echo ${log_dir/"~"/~})")"
if [ -d "$log_dir/$project" ]; then
  rm -r "$log_dir/$project"
fi
mkdir -p "$log_dir/$project"
temp="$PWD/temp"
if [ ! -d "$temp" ]; then
  mkdir -p "$temp"
fi
cd "$temp"
# check for current files
if [ "$(find -maxdepth 1 -name "*.current")" ]; then
  echo -e "Found current files:\n$(find -maxdepth 1 -name "*.current")"
  find -maxdepth 1 -name "*.current" -exec basename -s ".current" "{}" + |
    xargs -I %% rm -rf "%%/"
  find -maxdepth 1 -name "*.current" -delete
fi
bugs=$(bugsinpy-info -p $project | grep "Number of bugs" | cut -d ':' -f 2 | xargs)
echo "${blue}Checking out versions...${reset}"
for (( b=1; b<=$bugs; b++ )); do
  echo "  $project-$b"
  touch "$project-$b.current"
  # create the log dir for this version
  mkdir -p "$log_dir/$project/$b"
  # Skip downloading project if it is already there
  if [ -d $temp/$project-$b ]; then
    cd "$project-$b/$project"
    # Revert to working changes
    git clean -df > /dev/null
    git restore .
    git reset > /dev/null
    git add -A .
    cd "$temp"
    rm "$project-$b.current"
    continue
  fi
  bugsinpy-checkout -p $project -i $b -v 0 -w $temp/$project-$b &> /dev/null
  cd "$project-$b/$project"
  # Compile the project
  bugsinpy-compile &> /dev/null
  # Track the current changes so we can return to them
  git add -A .
  cd "$temp"
  rm "$project-$b.current"
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
  git clean -df > /dev/null
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
      py_cmd='import re;print(*re.match("(.+)\\.(\\w[^.]*)\\.([^.]+)",input()).groups(""))'
    else
      py_cmd='import re;print(*re.match("(.+)\\.py(::(\\w[^:]*))?::(.+)",input()).groups(""))'
    fi
    test_pts[$t]="$(echo "$t" | python3 -c "$py_cmd" | sed 's/\//./g;s/ \+/ /g')"
    test_diffs[$t]="$(bugsinpy-cut ${test_pts[$t]})"
    if [ "$?" -ne 0 ] || [ "${test_diffs[$t]}" == "" ]; then
      echo "ERROR: bugsinpy-cut did not succeed, skipping test $t for bug $b..."
      test_diffs[$t]=""
      continue
    fi
    echo "$b,${test_pts[$t]}" >> "$log_dir/$project/$b/bugs.txt"
    echo "${test_diffs[$t]}" > "$log_dir/$project/$b/${test_pts[$t]}.diff"
    #echo "${test_diffs[$t]}" > "$log_dir/$project/$b/${test_pts[$t]// /.}.patch"
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
      if [ "${test_diffs[$t]}" == "" ]; then
        echo "${yellow}  cut command failed for ${test_pts[$t]}${reset}"
        continue
      fi
      # Splice in the code for this test for bug b
      echo "${test_diffs[$t]}" | bugsinpy-splice ${test_pts[$t]}
      # Get expected and actual output for test
      expected_output="$(bugsinpy-test -t "$t" -w "$temp/$project-$b/$project")"
      test_output="$(bugsinpy-test -t "$t")"

      if [ "$unittest" == 1 ]; then
        awk_cmd='/[=-]{70}/{n++;next};n%2==0 && n>0'
        grp='^\(Traceback\|[ ]\+\|$\)'
        expected_error=$(echo "$expected_output" | awk "$awk_cmd" | grep -v "$grp")
        test_error=$(echo "$test_output" | awk "$awk_cmd" | grep -v "$grp")
        awk_cmd='/[=-]{70}/{n++;next};n%2==1'
        sed_cmd='s/FAIL.*/fail/g;s/ERROR.*/error/g'
        fail_or_error=$(echo "$test_output" | awk "$awk_cmd" | grep "^\(FAIL\|ERROR\):" | sed "$sed_cmd")
      else
        expected_error=$(echo "$expected_output" | grep "^E\s\+")
        test_error=$(echo "$test_output" | grep "^E\s\+")
        sed_cmd='s/.*FAILURES.*/fail/g;s/.*ERRORS.*/error/g'
        fail_or_error=$(echo "$test_output" | grep "=\+ \(FAILURES\|ERRORS\)" | sed "$sed_cmd")
      fi
      # Replace any occurence of this version in error string with the bug version
      test_error="${test_error//$project-$v/$project-$b}"
      #if [ "$test_error" != "$expected_error" ] || [ "$fail_or_error" == "" ]; then
      if [ "$(python3 "$home"/lcs.py "$test_error" "$expected_error")" -lt 85 ] ||
         [ "$fail_or_error" == "" ]; then
        if [ "$fail_or_error" == "error" ]; then
          echo "${yellow}  failed to compile test case${reset}"
          echo "${test_diffs[$t]}"
          echo "<-------------------------------------------------------------->"
          if [ "$test_error" ]; then
            echo "$test_error"
          else
            echo "$test_output"
          fi
        elif [ "$fail_or_error" == "fail" ]; then
          echo "${yellow}  error messages do not match${reset}"
          echo "  Found:"
          echo "  $test_error"
          echo "  Expected:"
          echo "  $expected_error"
          echo "  With score: $(python3 "$home/lcs.py" "$test_error" "$expected_error")"
        else
          echo "${yellow}  test case passing${reset}"
          echo "${test_diffs[$t]}"
          echo "<-------------------------------------------------------------->"
          echo "$test_output"
        fi
      else
        echo "${green}  success!${reset}"
        echo "$b,${test_pts[$t]}" >> "$log_dir/$project/$v/bugs.txt"
        echo "${test_diffs[$t]}" > "$log_dir/$project/$v/${test_pts[$t]}.diff"
        brk=0
      fi
      # Revert to working changes for this test
      git clean -df > /dev/null
      git restore .
      git reset > /dev/null
      git add -A .
    done
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
