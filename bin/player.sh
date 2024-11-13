#!/bin/bash
#
# 07/31/2019 - converted key lookup to function added random file player
# 02/06/2024 - added set_keyboard_input
# 03/26/2024 - git update

# Variables
random=$HOME/etc/player_cmds/unixcmd*
count=3
start=$(date)

# Functions
function test_input_device() {
    local device="$1"
    evemu-event "$device" --type EV_KEY --code KEY_Y --value 1 --sync
    evemu-event "$device" --type EV_KEY --code KEY_Y --value 0 --sync
}

function set_keyboard_input {
    # Iterate over /dev/input/event# devices
    for device in /dev/input/event{4,5,6,7,8,9}; do
        # Test input device
        if test_input_device "$device"; then
        printf "\t"
            read -rp "$device? (press Enter): " choice
            case $choice in
                [Yy]* )
                    KEYBOARD="$device"
                    return
                    ;;
                * )
                    ;;
            esac
        fi
    done
    echo "No input detected on any device."
    exit 1
}

function press {
    [ "$SHIFT" == "" ] || evemu-event ${device} --type EV_KEY --code $SHIFT --value 1 --sync
    evemu-event ${device} --type EV_KEY --code $1 --value 1 --sync
    evemu-event ${device} --type EV_KEY --code $1 --value 0 --sync
    [ "$SHIFT" == "" ] || evemu-event ${device} --type EV_KEY --code $SHIFT --value 0 --sync
    SHIFT=
    SEC=$(( (RANDOM % 10 ) + 1 )) && sleep 0.1$SEC
}

function keymap {
    case $char in
        [0-9])
        ;;
        [A-Z])
        if [[ $char = [QWERTASDFGZXCVB] ]]; then 
            SHIFT=KEY_LEFTSHIFT
        else
            SHIFT=KEY_RIGHTSHIFT
        fi
        ;;
        [a-z])
            char=${char^^}
        ;;
        ' ')
            char=SPACE
            sleep 0.4
        ;;
        '-')
            char=MINUS
        ;;
        '=')
            char=EQUAL
        ;;
        ',')
            char=COMMA
        ;;
        ':')
            SHIFT=KEY_LEFTSHIFT
            char=SEMICOLON
        ;;
        ';')
            char=SEMICOLON
        ;;
        '.')
            char=DOT
        ;;
        '/')
            char=SLASH
        ;;
        '\')
            char=BACKSLASH
        ;;
        '[')
            char=LEFTBRACE
        ;;
        ']')
            char=RIGHTBRACE
        ;;
        '{')
            SHIFT=KEY_LEFTSHIFT
            char=LEFTBRACE
        ;;
        '}')
            SHIFT=KEY_LEFTSHIFT
            char=RIGHTBRACE
        ;;
        '!')
            SHIFT=KEY_RIGHTSHIFT
            char=1
        ;;
        '@')
            SHIFT=KEY_RIGHTSHIFT
            char=2
        ;;
        '#')
            ### Custom ESC key map
            char=ESC
        ;;
        '$')
            SHIFT=KEY_RIGHTSHIFT
            char=4
        ;;
        '%')
            SHIFT=KEY_RIGHTSHIFT
            char=5
        ;;
        '^')
            SHIFT=KEY_RIGHTSHIFT
            char=6
        ;;
        '&')
            SHIFT=KEY_LEFTSHIFT
            char=7
        ;;
        '*')
            SHIFT=KEY_LEFTSHIFT
            char=8
        ;;
        '(')
            SHIFT=KEY_LEFTSHIFT
            char=9
        ;;
        ')')
            SHIFT=KEY_LEFTSHIFT
            char=0
        ;;
        '_')
            SHIFT=KEY_LEFTSHIFT
            char=MINUS
        ;;
        '+')
            SHIFT=KEY_LEFTSHIFT
            char=EQUAL
        ;;
        '|')
            SHIFT=KEY_LEFTSHIFT
            char=BACKSLASH
        ;;
        *)
            char=ENTER
        ;;
    esac
}

function countdown {
    printf "\n\n>>>  EVEMU Keyboard player starting. Select window... Count Down: "
    printf "5" && sleep 1
    printf "\b4" && sleep 1
    printf "\b3" && sleep 1
    printf "\b2" && sleep 1
    printf "\b1" && sleep 1
    printf "\bSTARTING\n" && sleep 1
}

# Error Check
[ ! -x "$(command -v evemu-event)" ] && sudo apt -y install evemu
[ $EUID -ne 0 ] && echo "Error: This script must be run as root" && exit 1
[ "$1" == "" ] && echo "Usage: sudo player.sh [player.dat file]" && exit 1 || inputfile=$1
[ ! -f $inputfile ] && echo "Error: Input file not found" && exit 1

# Execute
set_keyboard_input
countdown

# Continuous Play 
while :
do
    [ $(date +'%H') = 17 ] && printf "Exit: 5PM EOD\n`date`\n\n" && exit 0
    while IFS= read -r -n1 char
    do
        printf "$char"
        keymap $char
        press  KEY_$char
        SEC=$(( (RANDOM % 10 ) + 1 )) && sleep 0.0$SEC
        [ "$char" == "ENTER" ] && SEC=$(( (RANDOM % 10 ) + 1 )) && printf "\n[$SEC sec] " && sleep $SEC
    done < "$inputfile"
    SEC=$(( (RANDOM % 10 ) + 1 )) && printf "\n>>> completed selected $inputfile. Sleeping 1$SEC seconds...\n$start\n`date`\n" && sleep 1$SEC
    ls $random |sort -R | tail -$count |tail -$N |while read randomfile; do
    printf "\n>>> Random file: $randomfile\n"
        while IFS= read -r -n1 char
        do
            printf "$char"
            keymap $char
            press  KEY_$char
            SEC=$(( (RANDOM % 10 ) + 1 )) && sleep 0.0$SEC
            [ "$char" == "ENTER" ] && SEC=$(( (RANDOM % 10 ) + 1 )) && printf "\n[$SEC sec] " && sleep $SEC
        done < "$randomfile"
    done
    SEC=$(( (RANDOM % 10 ) + 1 )) && printf "\n>>> completed random $count files. Sleeping 1$SEC seconds...\n$start\n`date`\n" && sleep 1$SEC
done
