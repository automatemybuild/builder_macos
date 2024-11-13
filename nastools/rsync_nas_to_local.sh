#!/bin/bash
#
# rsync_nas_to_local.sh - syncronize files from mounted NAS filesystems to local media directory
#
# Updates:
#
# 07/21/2020 - created to backup NAS to local server
#

### Variables
line=$(printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =)
device=~/nas_mirror
path=/opt/diskstation
outfile=~/log/rsync_$(date +%Y%m%dT%H%M).log
last=$device/LAST_$(date +%Y%m%dT%H%M)

### Array
declare -a paths=("backup" "common" "emiller" "jenn_folders" "media" "music" "photos" "tmp")

### Error check
[ ! -d $device ] && printf "Info: Creating $device\n\n" && mkdir -f $device
[ ! -d ~/log ] && printf "Info: Creating ~/log directory\n\n" && mkdir ~/log

### Rsysc directories 
for dir in "${paths[@]}"
do
	printf "\n\n$line ${device}/${dir}\n$line\n\n"
	if [ -z "$(find $path/$dir -maxdepth 0 -type d -empty 2>/dev/null)" ]; then
		printf "Info: rsync $path/$dir to $device\n\n"
		rsync -avhRm --log-file $outfile --chmod=775 --chown=user:user \
			$1 --delete \
			--exclude="@eaDir" \
			$path/./$dir $device
	else
		printf "Warning: $path/$dir is empty maybe not mounted. Skipping...\n\n"
	fi
done
[ -f $device/LAST* ] && rm $device/LAST*
touch $last
df -h $device
printf "\n View outfile log: cat $outfile \n\n"
