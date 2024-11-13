#!/bin/bash
#
# update.sh - general purpose package update tool with options
#
# 06/26/2023 - add update_os_packages, docker update, and error checks
# 08/19/2023 - added kill all for snap
# 03/26/2024 - git update

YELLOW='\033[0;33m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

function header () {
    line="++++++++++++++++++++++++++++++++++++++++++++++++++"
    printf "\n${YELLOW}${line}\n${WHITE}${*}${YELLOW}\n${line}${NC}\n"
}

function update_os_packages {
    header "update_os_packages"
    if hash apt 2>/dev/null; then
        sudo apt update -y
        sudo apt upgrade -y
        sudo apt dist-upgrade -y
    elif hash apt-get 2>/dev/null; then
        sudo apt-get update -y
        sudo apt-get upgrade -y
        sudo apt-get dist-upgrade -y
    elif hash apk 2>/dev/null; then
        sudo apk update
        sudo apk upgrade
    elif hash dnf 2>/dev/null; then
        sudo dnf update -y
        sudo dnf upgrade -y
    elif hash brew 2>/dev/null; then
        brew update
        brew upgrade
        brew upgrade --cask
        brew cleanup
        sudo softwareupdate -i -a
    else
        echo ">> No package installers found."
        return 0
    fi
    if hash flatpak 2>/dev/null; then
        sudo flatpak update -y
    fi
    if hash snap 2>/dev/null; then
        killall firefox
        killall slack
        killall snap-store
        sudo snap refresh
    fi
    if hash rpm-ostree 2>/dev/null; then
        sudo rpm-ostree update
    fi
    date > $HOME/.lastpatch
}

function clean_os_packages {
    header "update_os_packages"
    if hash apt 2>/dev/null; then
        sudo apt autoremove -y
        sudo apt clean -y
    elif hash apt-get 2>/dev/null; then
        sudo apt-get autoremove -y
        sudo apt-get clean -y
    elif hash dnf 2>/dev/null; then
        sudo dnf autoremove -y
        sudo dnf clean -y
    elif hash apk 2>/dev/null; then
        sudo apk clean cache
    else
        echo ">> No package installers found."
        return 0
    fi
}

function docker_state {
    [ ! -x "$(command -v docker-compose)" ] && return 1
    [ ! -f $HOME/docker-compose.yml ] && return 1
    header "docker container ps"
    docker container ps
}

function docker_pull {
    [ ! -x "$(command -v docker-compose)" ] && return 1
    [ ! -f $HOME/docker-compose.yml ] && return 1
    header "docker-compose pull"                                                
    docker-compose pull                                                         
    header "docker-compose up -d"                              
    docker-compose up -d 
}

function docker_clean {
    [ ! -x "$(command -v docker-compose)" ] && return 1
    [ ! -f $HOME/docker-compose.yml ] && return 1
    header "docker-compose up -d --remove-orphans"                              
    docker-compose up -d --remove-orphans                                       
    header "docker image prune"                                                 
    docker image prune                                                    
}                                                    

while :; do
  case $1 in
    -h|--help)
      echo "$0 [OPTIONS]
      Options:
      -c --clean      removes old images and packages not used 
      -r --reboot     OS update and reboot without docker updates
      -s --shutdown   OS update and shutdown without docker updates
      -l --lock       OS update and lock screen
      -h --help       this help text"
      exit
      ;;
    -c|--clean)
      clean_os_packages
      docker_clean
      exit
      ;;
    -l|--lock)
      [ ! -x "$(command -v dbus-send)" ] && echo ">> dbus-send command not found" && return 1
      update_os_packages
      header "Invoking Screen Lock"
      sleep 10
      dbus-send --type=method_call --dest=org.gnome.ScreenSaver /org/gnome/ScreenSaver org.gnome.ScreenSaver.Lock
      exit
      ;;
    -r|--reboot)
      [ ! -x "$(command -v reboot)" ] && echo ">> reboot command not found" && return 1
      update_os_packages
      header reboot
      sudo reboot
      exit
      ;;
    -s|--shutdown|--halt|--poweroff)
      [ ! -x "$(command -v poweroff)" ] && echo ">> poweroff command not found" && return 1
      update_os_packages
      header poweroff
      sudo poweroff
      exit
      ;;
    *)
      update_os_packages
      docker_state
      docker_pull
      docker_state
      header "Complete!"
      echo "Use the $0 -c|--clean option to remove orphans and older images after validation"
      date > $HOME/.lastupdate
      exit
      ;;
  esac
done
