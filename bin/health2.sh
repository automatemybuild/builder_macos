#!/bin/bash
# 10/23/2022 - created
# 10/24/2022 - fix for critical command error
# 01/11/2023 - added tmux session check
# 06/24/2023 - added docker_status and updated for alpine OS
# 06/25/2023 - added ping_host url_check, warning and command check
# 10/15/2023 - fix for docker installed without yml file
# 10/16/2023 - updated for docker filter status=val format on ubutu
# 03/26/2024 - git repo

# Variables
output=/tmp/health.txt
[ -f $output ] && rm $output >/dev/null 2>&1

# Functions
function critical () {
    [ "$level" == "normal" ] && printf "\033[0;101m $1 \033[0m "
    [ "$level" == "info" ] && printf "\033[0;101m $1 \033[0m "
    [ "$level" == "verbose" ] && printf "\033[0;101m $1 \033[0m \n"
}

function warning () {
    [ "$level" == "normal" ] && printf "\033[0;43m $1 \033[0m "
    [ "$level" == "info" ] && printf "\033[0;43m $1 \033[0m "
    [ "$level" == "verbose" ] && printf "\033[0;43m $1 \033[0m \n"
}

function normal () {
    [ "$level" == "normal" ] && printf "\033[0;42m $1 \033[0m "
    [ "$level" == "info" ] && printf "\033[0;42m $1 \033[0m "
    [ "$level" == "verbose" ] && printf "\033[0;42m $1 \033[0m \n"
}

function inform () {
    [ "$level" == "normal" ] && printf "\033[0;44m $1 \033[0m "
    [ "$level" == "info" ] && printf "\033[0;44m $1 \033[0m "
    [ "$level" == "verbose" ] && printf "\033[0;44m $1 \033[0m \n"
}

function docker_status {
    [ ! -x "$(command -v docker-compose)" ] && return 0
    [ ! -f docker-compose.yml ] && return 0
    for i in $(docker-compose ps --services --filter status=running); do
        normal $i
        done
    for i in $(docker-compose ps --services --filter status=restarting); do
        warning $i
        docker-compose logs $i tail -1 >> $output 2>&1
        done
    for i in $(docker-compose ps --services --filter status=paused); do
        warning $i
        docker-compose logs $i tail -1 >> $output 2>&1
        done
    for i in $(docker-compose ps --services --filter status=stopped); do
        critical $i
        docker-compose logs $i tail -1 >> $output 2>&1
        done
}

function cpu_load {
    load=$(uptime | awk '{print $11}' | cut -f1 -d '.')
    tolerance=(2)
    if [[ "$load" -gt "$tolerance" ]]; then
        critical cpu_load
        top -b -n 1 | head -10 >> $output 2>&1
    else
        normal cpu_load
    fi
    [ "$level" == "verbose" ] && top -b -n 1 | head -20
}

function free_mem {
    [ ! -x "$(command -v free)" ] && inform install:free && return 0
    mem=$(free -m | grep Mem | awk '{print $4}')
    tolerance=(100)
    if [[ "$mem" -lt "$tolerance" ]]; then
        critical free_mem
        free -mh >> $output 2>&1
    else
        normal free_mem
    fi
    [ "$level" == "verbose" ] && free -mh
}

function diskusage () {
    #diskusage=$(df $1 --output=pcent | grep -v Use | cut -f1 -d '%')
    diskusage=$(df $1 | grep -v Use | cut -f1 -d '%')
    tolerance=(65)
    if [[ "$diskusage" == "$tolerance" ]] ;then
        critical $1
        df -h $1 >> $output 2>&1
    else
        normal $1
    fi
    [ "$level" == "verbose" ] && df -h $1
}

function dns {
    [ ! -x "$(command -v dig)" ] && inform install:dig && return 0
    dns=$(dig +short -x 1.1.1.1 2>/dev/null)
    if [[ "$dns" == "" ]] ;then critical dns ;else normal dns; fi
}

function gateway {
    #gateway=$(route -n | grep 'UG[ \t]' | awk '{print $2}' 2>/dev/null)
    gateway=$(route -n get default | grep 'gateway' | awk '{print $2}' 2>/dev/null)
    if [[ "$gateway" == "" ]] ;then critical gateway; else normal ${gateway}; fi
}

function wan {
    [ ! -x "$(command -v curl)" ] && inform install:curl && return 0
    ipaddr=$(curl -s http://whatismijnip.nl |cut -d " " -f 5 2>/dev/null)
    if [[ "$ipaddr" == "" ]] ;then critical internet ;else normal ${ipaddr}; fi
}

function ufw_status {
    [ ! -x "$(command -v ufw)" ] && return 0
    if [ -f /usr/sbin/ufw ] ;then
        ufw_active=$(sudo ufw status | grep active | awk '{print $2}' 2>/dev/null)
        if [[ "$ufw_active" != "active" ]] ;then critical ufw ;else normal ufw; fi
    fi
    [ "$level" == "verbose" ] && sudo ufw status 
}

function tmux_check {
    [ ! -x "$(command -v tmux)" ] && return 0
    session=$(tmux display -p '#{session_name}' 2>/dev/null)
    if [[ "$session" != "" ]] ;then 
        if [[ -n "$TMUX" ]] ;then 
            inform "tmux `tmux display -p '#{session_name}'`"
        else
            inform tmux
        fi
    fi
    [ "$level" == "verbose" ] && tmux ls
}

function url_check () {
    trimmed_url=$(echo "$1" | cut -d'/' -f1-1)
    if curl --output /dev/null --silent --head --fail "https://${1}"; then
        normal $trimmed_url
    else
        critical $trimmed_url
    fi
}

function ping_host () {
    ping -c 1 $1 >/dev/null 2>&1
    trimmed_hostname=$(echo "$1" | sed 's/news\.//')
    if [ $? -eq 0 ]; then
        normal $trimmed_hostname
    else
        critical $trimmed_hostname
    fi
}

case $1 in
    -h | --help )
    echo "Usage: [OPTIONS]"
    echo "  -h | --help - display this message"
    echo "  -v | --verbose - display all messages"
    ;;
    -v | --verbose)
    level=verbose
    ;;
    -i | --info)
    printf "Health: "
    level=info
    ;;
    *)
    printf "Health: "
    level=normal
    ;;
esac

# Execute Funtions from menu
cpu_load
#free_mem
diskusage /home
tmux_check
gateway
wan
dns
#ufw_status
docker_status
#url_check google.com
#ping_host hub.docker.com
if [ "$level" == "info" ] && [ -f $output ] ;then
    cat $output
fi
printf "\n"
