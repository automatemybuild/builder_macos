#!/usr/bin/bash
#
# icards.sh - Index cards - view, create, and edit cards
#

green='\e[1;32m'
blue='\e[1;34m'
normal='\e[0m'
reverse='\e[7m'
dim='\e[2m'
dimoff='\e[22m'

[[ -z $1 ]] && index_card='default' || index_card="${1}"
remote_dir=/opt/diskstation/common/documents/cards
local_dir=~/Documents/cards
outfile=~/log/icards.rsync.log
[[ ! -d $local_dir ]] && mkdir -p ${local_dir} && rsync -rtuv ${remote_dir}/* ${local_dir}
[[ ! -d ~/log ]] && mkdir -p ~/log
[[ -d $remote_dir ]] && nas=yes && data_path=${remote_dir} || data_path=${local_dir}
index_card_file=${data_path}/${index_card}.card

function display_card () {
  index_card_file=${data_path}/${1}.card
  header=$(printf '\r%*s\r\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -)
  line=$(printf '\r%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -)
  printf "${blue}${header}--${reverse} ${1} ${normal}\n"
  export GREP_COLOR='1;37;42'
  cat ${index_card_file} | grep -v ^# | grep --color -E '(^|###.*|---.*)'
  printf "${blue}${line}${normal}\n"
}
function index_card_menu {
  while true; do
    read -sn 1 key
    case $key in
      a)
        printf "${green}Add card: ${normal}"
        read -e -p '' index_card
        [ -z "$index_card" ] && printf "No value entered\n\n" && return 1
        index_card_file=${data_path}/${index_card}.card
        vi ${index_card_file}
        display_card ${index_card}
      ;;
      b)
        readarray -t lines < <(ls -1 $local_dir | sed -e 's/\.card//g')
        for i in "${lines[@]}"; do
          display_card $i
          [[ "$(read -sn 1; echo $REPLY)" == [Qq]* ]] && exit
        done
      ;;
      c)
        printf "${green}Change card: ${normal}"
        read -e -p '' index_card
        index_card_file=${data_path}/${index_card}.card
        [[ ! -f $index_card_file ]] && printf "Card $index_card_file does not exist\n" && index_card_file=${data_path}/default.card
        display_card ${index_card}
      ;;
      [f/])
        printf "${green}Find: ${normal}"
        read -e -p '' findchar
	egrep -E -i ${findchar} ${data_path}/*card | sed 's/\.card/]/' | sed 's/^.*cards\//[/'
	printf "${blue}${line}${normal}\n"
        readarray -t lines < <(grep -rli ${findchar} ${local_dir}/*card | awk -F/ '{ print $NF }' | sed -e 's/\.card//g')
        if [ ${#lines[@]} -eq 0 ]; then
          printf "${blue}${findchar} not found!\n${normal}"
        else
          printf "${blue}"
          select choice in "${lines[@]}"; do
            [[ -n $choice ]] || { echo "Invalid choice. Please try again." >&2; continue; }
            break # valid choice was made; exit prompt.
          done
          read -r index_card <<<$choice
          index_card_file=${data_path}/${index_card}.card
          display_card ${index_card}
        fi
      ;;
      [h?])
        printf "${green}[?H]elp, [B]rowse, [/F]ind, [S]ync, [.D]isplay [A]dd [C]hange [L]ist [V]Edit [R]emove cards ${normal}\n"
      ;;
      v)
        vi $index_card_file
        display_card ${index_card}
      ;;
      r)
        printf "${green}Remove card: ${normal}"
        read -e -p '' index_card
        [[ "$index_card" == "default" ]] && printf "Can\'t remove default\n\n" && return 1
        [[ ! -f  ${data_path}/${index_card}.card ]] && printf "Card ${data_path}/${index_card}.card does not exist\n" && return
        echo "${data_path}/${index_card}.card"
        [[ "$(read -e -p 'Confirm? [y/N] '; echo $REPLY)" == [Yy]* ]] && rm ${local_dir}/${index_card}.card ${remote_dir}/${index_card}.card
        printf "\n${green}`ls -1 $data_path`${normal}\n"
      ;;
      s)
        printf "${dim}"
        rsync -rtuv ${local_dir}/* ${remote_dir}
        rsync -rtuv ${remote_dir}/* ${local_dir}
        printf "${dimoff}${green}done${normal}\n"
      ;;
      l)
        readarray -t lines < <(ls -1 $local_dir | sed -e 's/\.card//g')
        printf "${blue}"
        select choice in "${lines[@]}"; do
          [[ -n $choice ]] || { echo "Invalid choice. Please try again." >&2; continue; }
          break # valid choice was made; exit prompt.
        done
        read -r index_card <<<$choice
        index_card_file=${data_path}/${index_card}.card
        display_card ${index_card}
      ;;
      [d.])
        display_card ${index_card}
      ;;
      *)
        return 0
      ;;
    esac
  done
}
function create_index_card () {
  [[ "$(read -e -p 'Create new card? [y/N] '; echo $REPLY)" == [Yy]* ]] &&  vi $1
}
function sync_cards_local_remote {
  [[ -z $nas ]] && printf "\n${green}NAS ${remote_dir} not mounted${normal}\n\n" && return 1
  rsync -rtuv ${local_dir}/* ${remote_dir} 2>> ${outfile} >> ${outfile}
  rsync -rtuv ${remote_dir}/* ${local_dir} 2>> ${outfile} >> ${outfile}
}

[[ ! -e $index_card_file ]] && create_index_card ${index_card_file}
display_card ${index_card}
index_card_menu
sync_cards_local_remote
