#!/usr/bin/bash
#
# photo-import.sh - Copy JPG and RAW photos from SD DCIM to local directory removing source file from SD
#
# 05/31/2022 - Added MP4 video clips
# 08/28/2022 - updated remote_dir (sd) path to include path for video

remote_dir=/media/user/disk/DCIM/./
remote_vid_dir=/media/user/disk/PRIVATE/M4ROOT/./
local_dir_jpg=$HOME/Pictures/photo-import_JPG_$(date +%Y%m%d)
local_dir_raw=$HOME/Pictures/photo-import_RAW_$(date +%Y%m%d)
local_dir_clip=$HOME/Pictures/video-import_MP4_$(date +%Y%m%d)
nas_dir=/opt/diskstation/photos
export logfile=$HOME/log/photo-import_$(date +%Y%m%dt%H%Ms%s).log
line=$(printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =)

function error_check {
	[ ! -d $remote_dir ] && printf "Error: $remote_dir does not exist or not mounted. Exiting!\n\n" && exit 1
	if find $remote_dir -maxdepth 3 -empty | read v; then echo "Error: $remote_dir does not contain any files. Exiting!" && exit 1; fi
	[ ! -d $local_dir_jpg ] && printf " INFO: Creating $local_dir_jpg\n\n" && mkdir -p $local_dir_jpg
	[ ! -d $local_dir_raw ] && printf " INFO: Creating $local_dir_raw\n\n" && mkdir -p $local_dir_raw
	[ ! -d $local_dir_clip ] && printf " INFO: Creating $local_dir_clip\n\n" && mkdir -p $local_dir_clip
	[ ! -d $nas_dir_jpg ] && printf " INFO: Creating $nas_dir_jpg\n\n" && mkdir -p $nas_dir_jpg
	[ ! -d $nas_dir_raw ] && printf " INFO: Creating $nas_dir_raw\n\n" && mkdir -p $nas_dir_raw
	[ ! -d $nas_dir_clip ] && printf " INFO: Creating $nas_dir_clip\n\n" && mkdir -p $nas_dir_clip
	[ ! -d $HOME/log ] && printf " INFO: Creating log directory\n\n" && mkdir -p $HOME/log
	disk_remote_used=$(df -k $remote_dir | grep dev | awk '{print $3}')
	disk_local_avail=$(df -k $HOME | grep dev | awk '{print $4}')
	[ ! -x "$(command -v identify)" ] && printf "Package: dnf install ImageMagick\n" && sudo dnf -y install ImageMagick
	if (( $(bc -l <<< "$disk_remote_used>$disk_local_avail") ))
	then
		echo "Warning: Not enough local space. Exiting!" && exit 1
	fi
}
function rsync_from_SD_to_local {
	if [ -z "$(find $remote_dir -maxdepth 0 -type d -empty 2>/dev/null)" ]; then
		printf "\n$line\n INFO: rsync JPG files $remote_dir to $local_dir_jpg\n$line\n"
		rsync -avhRm --log-file $logfile --progress --whole-file --remove-source-files \
			--include "*/" --include="*.JPG" --exclude="*" \
			$remote_dir $local_dir_jpg
		printf "\n$line\n INFO: rsync RAW files $remote_dir to $local_dir_raw\n$line\n"
		rsync -avhRm --log-file $logfile --progress --whole-file --remove-source-files \
			--include "*/" --include="*.ARW" --exclude="*" \
			$remote_dir $local_dir_raw
		printf "\n$line\n INFO: rsync MP4 files $remote_vid_dir to $local_dir_clip\n$line\n"
		rsync -avhRm --log-file $logfile --progress --whole-file --remove-source-files \
			--include "*/" --include="*.MP4" --exclude="*" \
			$remote_vid_dir $local_dir_clip
		[[ "$(read -e -p 'List local JPG file information?	[y/N] '; echo $REPLY)" == [Yy]* ]] && \
			printf "\n$line\n$local_dir_jpg\n$line\n`identify $local_dir_jpg/*/*`\n\n"
		[[ "$(read -e -p 'List local RAW file information?	[y/N] '; echo $REPLY)" == [Yy]* ]] && \
			printf "\n$line\n$local_dir_raw\n$line\n`identify $local_dir_raw/*/*`\n\n"
		[[ "$(read -e -p 'List local MP4 file information?	[y/N] '; echo $REPLY)" == [Yy]* ]] && \
			printf "\n$line\n$local_dir_clip\n$line\n`identify $local_dir_clip/*/*`\n\n"
	else
		printf "Warning: $remote_dir is empty maybe not mounted. Skipping...\n\n"
	fi
}
function rsync_from_local_to_nas {
	[ ! -d $nas_dir ] && printf " Warning: Not mounted $nas_dir. Skipping...\n\n" && return 1
	printf "\n$line\n INFO: rsync files $local_dir_jpg and $local_dir_raw to $nas_dir\n$line\n"
	rsync -avzp --log-file $logfile --progress --whole-file --no-owner --no-group \
		$local_dir_jpg $nas_dir
	rsync -avzp --log-file $logfile --progress --whole-file --no-owner --no-group \
		$local_dir_raw $nas_dir
	rsync -avzp --log-file $logfile --progress --whole-file --no-owner --no-group \
		$local_dir_clip $nas_dir
}
function start_counts {
	outfile=$HOME/log/photo-import_files_$(date +%Y%m%dt%H:%M:%s)
	printf " Counting remote files ... "
	remote_count_start=$(find $remote_dir -type f | wc -l) && echo $remote_count_start
	printf " Counting local JPG files ... "
	local_count_start_jpg=$(find $local_dir_jpg -type f | wc -l) && echo $local_count_start_jpg
	printf " Counting local RAW files ... "
	local_count_start_raw=$(find $local_dir_raw -type f | wc -l) && echo $local_count_start_raw
	printf " Counting local MP4 files ... "
	local_count_start_raw=$(find $local_dir_clip -type f | wc -l) && echo $local_count_start_clip
	printf "\n"
}

function end_counts {
	remote_count_end=$(find $remote_dir -type f | wc -l)
	local_count_end_jpg=$(find $local_dir_jpg -type f | wc -l)
	local_count_end_raw=$(find $local_dir_raw -type f | wc -l)
	local_count_end_clip=$(find $local_dir_clip -type f | wc -l)
	find $remote_dir -type f | sort > $outfile.remote_end
	find $local_dir_jpg -type f | sort > $outfile.local_end_jpg
	find $local_dir_raw -type f | sort > $outfile.local_end_raw
	find $local_dir_clip -type f | sort > $outfile.local_end_clip
}

function report {
	printf "$line\nReport: rsync error count --> `grep error $logfile | wc -l`\n"
	printf "	Remote count --> Start: $remote_count_start \tEnd: $remote_count_end \n"
	printf "	Local JPG count  --> Start: $local_count_start_jpg \tEnd: $local_count_end_jpg \n"
	printf "	Local RAW count  --> Start: $local_count_start_raw \tEnd: $local_count_end_raw \n$line\n"
	printf "	Local MP4 count  --> Start: $local_count_start_clip \tEnd: $local_count_end_clip \n$line\n"
	printf "$line\nRemote count --> Start: $remote_count_start \tEnd: $remote_count_end \n\n" >> $logfile
	printf "Local JPG count  --> Start: $local_count_start_jpg \tEnd: $local_count_end_jpg \n$line\n\n" >> $logfile
	printf "Local RAW count  --> Start: $local_count_start_raw \tEnd: $local_count_end_raw \n$line\n\n" >> $logfile
	printf "Local MP4 count  --> Start: $local_count_start_clip \tEnd: $local_count_end_clip \n$line\n\n" >> $logfile
}

function custom_path {
	year=$(date +%Y)
	printf $year
	[[ "$(read -e -p ' ? [Y/n] '; echo $REPLY)" == [Nn]* ]] && read -p 'Year: ' year
	read -p 'Event Name (no spaces): ' event
	local_dir_jpg=$HOME/Pictures/${year}_${event}_JPG_$(date +%Y%m%d)
	local_dir_raw=$HOME/Pictures/${year}_${event}_RAW_$(date +%Y%m%d)
	local_dir_clip=$HOME/Pictures/${year}_${event}_MP4_$(date +%Y%m%d)
	export $local_dir_jpg
	export $local_dir_raw
	export $local_dir_clip
    printf "\n$line\n photo-import.sh\n$line\n\n$local_dir_jpg\n$local_dir_raw\n$local_dir_clip\n\n"
}

function error_report {
	echo
	[ ! -f $logfile ] && exit 0
	error_count=$(grep error $logfile | grep -v code.23 | wc -l)
	zero=0
	if (( $(bc -l <<< "$error_count>$zero") ))
	then
		printf "$line\nReport: rsync error count --> `grep error $logfile | grep -v code.23 | wc -l`\n$line\n`grep error $logfile`\n\n"
	fi
}

printf "\n$line\n photo-import.sh\n$line\n\n$local_dir_jpg\n$local_dir_raw\n\n"
printf "SD card contains `df -h $remote_dir | grep dev | awk '{print $3}'` of photos. Local space available `df -h $HOME | grep dev | awk '{print $4}'`\n\n"
[[ "$(read -e -p 'Use the default directory name?	[Y/n] '; echo $REPLY)" == [Nn]* ]] && custom_path

error_check
start_counts

[[ "$(read -e -p 'View photo/video file information on SD card?	[y/N] '; echo $REPLY)" == [Yy]* ]] && printf "\n$line\n$remote_dir\n$line\n`identify $remote_dir/*/*`\n\n"
[[ "$(read -e -p 'Move photos/video from SD card to local directory?	[y/N] '; echo $REPLY)" == [Yy]* ]] && rsync_from_SD_to_local && end_counts && report
[[ "$(read -e -p 'Copy (rsync) same local/video photos to NAS?	[y/N] '; echo $REPLY)" == [Yy]* ]] && rsync_from_local_to_nas

error_report
