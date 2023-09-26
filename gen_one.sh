#!/bin/bash
USAGE="USAGE: ./gen_one.sh -p <project> -i <version> -w [-w <work dir>]"
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

work_dir="$PWD"
verbose="/dev/null"
vb=""
while getopts ":hvp:i:w:" opt; do
  case ${opt} in
    h )
      echo "$USAGE"
      exit 0
      ;;
    p )
      project="$OPTARG"
      ;;
    i )
      v="$OPTARG"
      ;;
    w )
      work_dir="$OPTARG"
      ;;
    v )
      verbose="/dev/stdout"
      vb="-v"
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      ;;
  esac
done
shift $((OPTIND -1))
if [ ! "$project" ]; then
  echo "${yellow}Please specify a project${reset}"
  echo "$USAGE"
  exit 0
elif [ ! "$v" ]; then
  echo "${yellow}Please specify a version${reset}"
  echo "$USAGE"
  exit 0
fi
echo "${green}Checking out $project-$v...${reset}"
bugsinpy-multi-checkout $vb -p "$project" -i "$v" -w "$work_dir" &> "$verbose"
cd "$work_dir/$project"
echo "${green}Collecting coverage...${reset}"
bugsinpy-coverage -a &> "$verbose"
echo "${green}Creating TCM...${reset}"
bugsinpy-to-tcm
bugsinpy-identify
echo "${green}Done${reset}"
