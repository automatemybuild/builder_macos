#!/bin/bash
#
# imon - Ping list of addresses
# Usage: imon.sh [seconds]
#
# 03/26/2024 - git update
#
red='\e[1;41m'
green='\e[1;32m'
normal='\e[0m'
reverse='\e[7m'
list=~/etc/hostlist/imon
[[ -n $1 ]] && seconds=$1 || seconds=8

while true; do
	awk '{print $1}' < ${list} | while read ip; do
	if ping -c1 $ip >/dev/null 2>&1; then
		printf "${reverse}${green}                                \r $ip ${normal}\n"
	else
		printf "${red}                                \r $ip ${normal}\n"
	fi
	done
	printf "\n"
	sleep $seconds
done
