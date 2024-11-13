#!/bin/bash
#
# restore_from_nas.sh - Restores files from remote NAS to local 
#
# 03/26/2024 - git update

function error_check {
	[ ! -d $remote_dir ] && printf "ERROR: $remote_dir does not exist or not mounted.\n\n"
}

function update_local () {
	[ ! -d $local_dir ] && mkdir -p $local_dir
	if [ -z "$(find $remote_dir -maxdepth 0 -type d -empty 2>/dev/null)" ]; then
		printf "INFO: rsync $remote_dir to $local_dir...\n\n"
		rsync -avhRm $* $remote_dir $local_dir
	fi
}

local_dir=$HOME/Documents
remote_dir=/opt/diskstation/common/documents/./
[ -d $remote_dir ] && error_check
[ -d $remote_dir ] && update_local

local_dir=$HOME/etc
remote_dir=/opt/diskstation/common/etc/./
[ -d $remote_dir ] && error_check
[ -d $remote_dir ] && update_local

local_dir=$HOME/scripts
remote_dir=/opt/diskstation/common/scripts/./
[ -d $remote_dir ] && error_check
[ -d $remote_dir ] && update_local --exclude="old"

local_dir=$HOME/.ssh
remote_dir=/opt/diskstation/common/ssh/./
[ -d $remote_dir ] && error_check
[ -d $remote_dir ] && update_local
chmod 700 $HOME/.ssh
chmod 600 $HOME/.ssh/*
chmod 644 $HOME/.ssh/*.pub

local_dir=$HOME/.config
remote_dir=/opt/diskstation/common/config/./
[ -d $remote_dir ] && error_check
[ -d $remote_dir ] && update_local

remote_dir=/opt/diskstation/emiller/.keepass/./
[ ! -d $HOME/.keepass ] && printf "Info: Creating .keepass directory\n\n" && mkdir -p $HOME/.keepass 
[ -d $remote_dir ] && \
	rsync -avzuh --chmod=500 --chown=user:user /opt/diskstation/emiller/keepass/master_database.kdbx $HOME/.keepass/
