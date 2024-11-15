#!/bin/bash
#
# netchk.sh - quick check of reachablity
#

### Variables
END=10
COUNT=1
WAIT=1
SIZE=64
speed=default
data=~/.config/netchk
outfile=${data}/monitor_netchk.log
[ "$1" == "--dialup" ] && WAIT=5  && COUNT=1 && END=3 && speed=dialup
[ "$1" == "--slow" ] && WAIT=3  && COUNT=1 && END=5 && speed=slow
[ "$1" == "--fast" ] && WAIT=1 && COUNT=1 && END=30 && speed=fast
[ "$1" == "--stress" ] && WAIT=1 && COUNT=10 && END=30 && SIZE=1500 && speed=stress
[ "$1" == "--monitor" ] && rm -f $data/monitor* && clear && speed=monitor && cp /dev/null $outfile
[ "$1" == "--clear" ] && rm -f $data/* && exit 0
[ "$1" == "--alias" ] && alias netchk='$HOME/bin/netchk_boa.sh 2> /dev/null' && printf "alias set\n\n" && exit 0
[ "$1" == "--help" ] && clear && printf "netchk_boa [option]\n\n--help\t\t- this help text\n--clear\t\t- clear data history\n--alias\t\t- sets alias for [netchk_boa]\n--dialup\t- few pings with very high wait times\n--slow\t\t- less pings longer wait times\n--stress\t- stress test higher count per (!) test\n--monitor\t- continous monitor\n\n" && exit 0
[ ! -d $data ] && mkdir -p $data
gateway=$(route -n|grep "UG"|grep -v "UGH"|cut -f 10 -d " " | head -1)
dns1=$(nmcli dev show | grep DNS | head -1 | awk '{print $2}')
local=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'| grep -v 192.168.122| head -1)
color_red='echo -e \e[31m\c'
color_green='echo -e \e[32m\c'
color_yellow='echo -e \e[33m\c'
color_normal='tput sgr0'

printf "MENU\n\n 1) BOFA\n 2) LAN\n 3) Jitsi\n 4) WAN\n\nchoice: "
read -sn 1 key
case $key in
  1)
  clear
  declare -a hostlist=(\
  	"$local"\
  	"$gateway"\
  	"$dns1"\
  	"192.168.1.1"\
  	"1.1.1.3"\
  	"BANK-OF-AME.edge5.Newark1.Level3.net"\
  	"BANK-OF-AME.bear1.Richmond1.Level3.net"\
  	"BANK-OF-AME.ear1.Dallas3.Level3.net"\
  	)
  ;;
  2)
  declare -a hostlist=(\
  	"$local"\
  	"$gateway"\
  	"$dns1"\
	"1.1.1.3"\
  	"wlan1-ap.localdomain"\
  	"wlan2-ap.localdomain"\
  	"wlan3-ap.localdomain"\
  	"dns3.localdomain"\
  	"skull.localdomain"\
  	"intel-nuc.localdomain"\
  	"printer.localdomain"\
  	"codsworth.localdomain"\
  	"nas.localdomain"\
  	"ping.localdomain"\
  	"netmon.localdomain"\
  	"htpc.localdomain"\
  	"htpc2.localdomain"\
  	"roku-mediaroom.localdomain"\
  	"roku-livingroom.localdomain"\
  	"roku-office.localdomain"\
  	"tivo-mediaroom.localdomain"\
  	"tivo-livingroom.localdomain"\
  	"tivo-office.localdomain"\
	)
  ;;
  3)
  declare -a hostlist=(\
  	"$local"\
  	"$gateway"\
  	"$dns1"\
	"1.1.1.3"\
	"meet-jit-si-latency.cloud.jitsi.net"\
	"meet.jit.si"\
	"collector.callstats.io"\
	"web-cdn.jitsi.net"\
	"rtcstats-server.jitsi.net"\
	)
  ;;
  *)
  declare -a hostlist=(\
  	"$local"\
  	"$gateway"\
  	"$dns1"\
  	"1.1.1.3"\
  	"4.2.2.4"\
  	"us-newjersey.privacy.network"\
  	"us-newyorkcity.privacy.network"\
  	"mail.protonmail.com"\
  	"amazon.com"\
  	"www.disneyplus.com"\
  	"forecast.weather.gov"\
  	"thehackernews.com"\
  	"www.theverge.com"\
  	"www.hulu.com"\
  	"meet.jit.si"\
  	"reddit.com"\
  	"twitter.com"\
  	"youtube.com"\
	)
  ;;
esac

function connection_monitor () { 
  target=1.0.0.1
  ping_count=36
  sleep=2
	tally=$[$tally +1]
  count=1
  size=1
  wait=1
  printf "\n[`printf %${ping_count}s |tr " " "."`] Connection monitor ($tally) Log: `cat ${outfile} | wc -l`\n \u001b[1A"
  for ((n=0; n < ping_count; n++))
	do
    sleep $sleep
    ping_test=$(ping $target -q -c $count -w $wait -s $size | grep packet.loss | grep -o "[0-9]*\%" | tr -cd [:digit:] 2> /dev/null )
    if [ "$ping_test" == "0" ]
    then
      printf "!"
    elif [ "$ping_test" == "100" ]
    then
      printf "\u001b[7m.\u001b[0m"
      date=$(date +"%Y-%m-%dT%H:%M:%S") && echo "$date $target unreachable" >> $outfile
    elif [ "$ping_test" -gt "1" ]
    then
      printf "\u001b[7m%\u001b[0m"
      date=$(date +"%Y-%m-%dT%H:%M:%S") && echo "$date $target packetloss" >> $outfile
    else
      printf "\u001b[7m?\u001b[0m"
      date=$(date +"%Y-%m-%dT%H:%M:%S") && echo "$date $target hostname error" >> $outfile
    fi
  done
}

### Ping check for each hostname
while true ; do
	printf "%-40s%3s\n" Hostname "(ping end:$END count:$COUNT wait:$WAIT size:$SIZE)"
	printf "%-40s%3s\n" "--------------------------------------"    "----------------------------------------------"
	for hostname in "${hostlist[@]}"
	do
		if [ "$hostname" != "$last" ] ;then
			name=$hostname
			[ "$hostname" == "$gateway" ] && name="$name(gateway)"
			[ "$hostname" == "$dns1" ] && name="$name(dns)"
			[ "$hostname" == "$local" ] && name="$name(local)"
			[ "$hostname" == "4.2.2.4" ] && name="$name(vpn_check)"
			printf "%-40s%3s" $name "--> "
			x=$END 
			start=`date +%s%N | cut -b1-13`
			while [ $x -gt 0 ]; 
			do 
				last=$hostname
				x=$(($x-1))
				PING=$(ping $hostname -q -c $COUNT -W $WAIT -s $SIZE | grep packet.loss | grep -o "[0-9]*\%" | tr -cd [:digit:] 2> /dev/null )
				if [ "$PING" == "0" ]
				then
					printf "!"
				elif [ "$PING" == "100" ]
				then
					printf "."
					error="(packet loss)"
          date=$(date +"%Y-%m-%dT%H:%M:%S") && echo "$date $hostname unreachable" >> $outfile
				elif [ "$PING" -gt "1" ]
				then
					$color_red
					printf "%"
					error="(error)"
          date=$(date +"%Y-%m-%dT%H:%M:%S") && echo "$date $hostname packetloss" >> $outfile
				else
					$color_red
					printf "?"
					error="(lookup error)"
          date=$(date +"%Y-%m-%dT%H:%M:%S") && echo "$date $hostname hostname error" >> $outfile
				fi
				$color_normal
			done
			end=`date +%s%N | cut -b1-13`
			runtime=$((end-start))
			printf "$runtime\n" >> $data/$speed.$hostname
			avg=$(awk '{ total += $1; count++ } END { print total/count }' $data/$speed.$hostname)
			avg=$(echo $avg | grep -o '^[0-9]*')
			[ "$runtime" -ge "$avg" ] && $color_yellow
			printf " $runtime ms ($avg)	$error\n"
			$color_normal
			error=''
			avg=''
		fi	
	done
	printf "%-40s%3s\n" "--------------------------------------"    "----------------------------------------------"
	[ "$speed" != "monitor" ] && exit 0
  connection_monitor
  clear
done
