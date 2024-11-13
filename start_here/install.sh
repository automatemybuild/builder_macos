#!/bin/bash
#
# install.sh - update local files from git pull
#
# 03/26/2024 - git repo
# 11/12/2024 - updated for MacOS

function error_check {
	[ ! -d $source_dir ] && printf "ERROR: $source_dir does not exist or not mounted.\n\n"
}

function update_local {
	[ ! -d $local_dir ] && printf "Creating $local_dir\n\n" && mkdir -p $local_dir
	if [ -z "$(find $source_dir -maxdepth 0 -type d -empty 2>/dev/null)" ]; then
		printf "INFO: rsync $source_dir to $local_dir...\n\n"
		rsync -avhRm $1 --include='.*' $source_dir $local_dir
	else
		printf "WARNING: $source_dir is empty maybe not mounted. Skipping...\n\n"
	fi
}

local_dir=$HOME/bin
source_dir=$HOME/git/builder_macos/bin/./
[ -d $source_dir ] && error_check
[ -d $source_dir ] && update_local

local_dir=$HOME/nastools
source_dir=$HOME/git/builder_macos/nastools/./
[ -d $source_dir ] && error_check
[ -d $source_dir ] && update_local

local_dir=$HOME
source_dir=$HOME/git/builder_macos/dotfiles/./
[ -d $source_dir ] && error_check
[ -d $source_dir ] && update_local

printf "run:\nsource $HOME/.bash_profile\n\n"
printf "run:\ncd $HOME/git/builder_macos/start_here; ./builder.sh macos.playbook\n\n"
