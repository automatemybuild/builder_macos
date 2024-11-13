#!/bin/bash
#
# builder.sh - Post OS install tool to apply common build settings
#
# Updates:
# 07/08/2020 - Created script to use common functions and build list
# 03/26/2024 - Updated for github
# 
### Error checks
[[ $1 == "" ]] && echo "Usage: $0 [build script] --noprompt" && exit 1
[[ ! -f $1 ]] && echo "Error: $1 is not found" && exit 1

### Variables
file="${1}"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

### Functions
[[ ! -f functions.sh ]] && echo "Error: functions.sh file not found. Exiting" && exit 1
source functions.sh

### Run commands from os.build
header "${0} ${file} ${2}"
[[ "$2" != "--noprompt" ]] && printf "Press [ESC] to skip command, [q]uit, [f]unction list, [v]im ${file} or other key to confirm\n"
IFS=$'\n' read -d '' -r -a lines < $file
for item in "${lines[@]}"
do
  if [[ "$item" == "#"* ]]; then
    printf "\n\n${YELLOW}${item}${NC}"
  elif [[ "$2" == "--noprompt" ]]; then
    header ${item} && $item && printf "${GREEN}done${NC}\n"
  else
    printf "\n%-64s%3s" "> ${item}" ""
    read -sn 1 key
    case $key in
        q) printf "\n\n${YELLOW}Quit!${NC}\n\n" && exit 1 ;;
        v) vi $file ;;
        f) printf "\n" && grep ^function ~/bin/builder_functions.sh | awk '{print $2}' & read -p "athoc run function: " athoc && header ${athoc} && $athoc && printf "${GREEN}done${NC}\n" ;;
        $'\e') printf "${RED}x${NC}" ;;
        *) echo -e "${GREEN}\xE2\x9C\x94${NC}" && header ${item} && $item && printf "${GREEN}done${NC}\n" ;;
    esac
  fi
done
printf "\n\n${GREEN}Complete!${NC}  $msg\n\n"
