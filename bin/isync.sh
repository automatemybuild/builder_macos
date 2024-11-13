#!/usr/bin/bash
#
# isync.sh - Copy photos and videos from iphone DCIM to local directory
#
# 03/26/2024 - git repo

line=$(printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =)
remote_dir=/run/user/1000/gvfs/gphoto*/DCIM/./
local_dir=$HOME/Pictures/isync_$(date +%Y%m%d)

function error_check {
	[ ! -d $remote_dir ] && printf "Error: $remote_dir does not exist or not mounted. Exiting!\n\n" && exit 1
	[ ! -d $local_dir ] && printf " INFO: Creating $local_dir\n\n" && mkdir -p $local_dir
	[ ! -d $HOME/log ] && printf " INFO: Creating log directory\n\n" && mkdir -p $HOME/log
}

function remove_motion_files {
	find $remote_dir -type f \( -name "*.MOV" -or -name "*.mov" \) -size -11M -exec rm {} \;
}

function rsync_from_iphone_to_local {
	logfile=$HOME/log/isync_$(date +%Y%m%dt%H%Ms%s).log
	if [ -z "$(find $remote_dir -maxdepth 0 -type d -empty 2>/dev/null)" ]; then
		printf "\n$line\n INFO: rsync JPG files $remote_dir to $local_dir\n$line\n"
		rsync -avhRm --log-file $logfile --progress --whole-file --remove-source-files \
			--include "*/" --include="*.JPG" --exclude="*" \
			$remote_dir $local_dir
		printf "\n$line\n INFO: rsync MOV files $remote_dir to $local_dir\n$line\n"
		rsync -avhRm --log-file $logfile --progress --whole-file --remove-source-files \
			--include "*/" --include="*.MOV" --exclude="*" \
			--min-size=11m \
			$remote_dir $local_dir
	else
		printf "Warning: $remote_dir is empty maybe not mounted. Skipping...\n\n"
	fi
}

function start_counts {
	outfile=$HOME/log/isync_files_$(date +%Y%m%dt%H:%M:%s)
	printf " Counting remote files ... "
	remote_count_start=$(find $remote_dir -type f | wc -l) && echo $remote_count_start
	printf " Counting local files ... "
	local_count_start=$(find $local_dir -type f | wc -l) && echo $local_count_start
	find $remote_dir -type f | sort > $outfile.remote_start
	find $local_dir -type f | sort > $outfile.local_start
}

function end_counts {
	remote_count_end=$(find $remote_dir -type f | wc -l)
	local_count_end=$(find $local_dir -type f | wc -l)
	find $remote_dir -type f | sort > $outfile.remote_end
	find $local_dir -type f | sort > $outfile.local_end
}

function report {
	diff $outfile.remote_start $outfile.remote_end > $outfile.remote_diff
	diff $outfile.local_start $outfile.local_end > $outfile.local_diff
	printf "\n$line INFO: Remote diff\n$line\n`cat $outfile.remote_diff`\n\n"
	printf "$line INFO: Local diff\n$line\n`cat $outfile.local_diff`\n\n"
	printf "$line\nReport: rsync error count --> `grep error $logfile | wc -l`\n"
	printf "	Remote count --> Start: $remote_count_start \tEnd: $remote_count_end \n"
	printf "	Local count  --> Start: $local_count_start \tEnd: $local_count_end \n$line\n"
	printf "$line\nRemote count --> Start: $remote_count_start \tEnd: $remote_count_end \n" >> $logfile
	printf "Local count  --> Start: $local_count_start \tEnd: $local_count_end \n$line\n\n" >> $logfile
	printf "Files:\n\t$outfile.remote_diff\n\t$outfile.local_diff\n\t$logfile\n\n"
}

error_check

printf "\n$line\n isync.sh\n$line\n * Stop virtual machines\n * Remove pin lock (optional)\n * Turn on Airplane mode\n * Set iOS Display Auto-Lock for transfer (optional)\n\tSettings > Display & Brightness > Auto-Lock > Never\n * On Input/Ouput error [CTRL + C] to exit, unmount, and restart\n$line\n\n"
echo "Monitor command:  watch 'ls $local_dir/*/* | wc -l'"
printf " INFO: Motion file count: "
find $remote_dir -type f \( -name "*.MOV" -or -name \"*.mov\" \) -size -11M -exec ls -lh {} \; | wc -l
[[ "$(read -e -p 'CMD: Remove remote motion MOV files under 11MB? [y/N] '; echo $REPLY)" == [Yy]* ]] && remove_motion_files

for i in {1..20}; do
	if find -type f -exec false {} +
	then
		echo '>> Success!! All files moved.'
		return 0
	else
		printf "\n\n>> RUN: $i\n\n"
		start_counts
		rsync_from_iphone_to_local
		end_counts
		report
		printf "sleeping 5min ... \n" 
		for s in `seq 300 -1 1` ; do echo -ne "\r$s " ; sleep 1 ; done
	fi
done

printf "\n\n$line * Unmount with file manager and disconnect (Wait for each unmount to finish!)\n * Reset iOS Display Auto-Lock\n\tSettings > Display & Brightness > Auto-Lock\n$line\n"
