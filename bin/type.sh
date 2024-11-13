#!/usr/bin/env bash
#
# type.sh - type text file into VI editor on a remote session like a human
#
# 10/25/2023 - copies a text file to a remote system by typing file into a VIM sessions that it opens and saves 
# 02/06/2024 - added set keyboard input
# 03/26/2024 - git update
#
# Find Device: sudo evemu-describe

# Error Check
[ ! -x "$(command -v evemu-event)" ] && sudo apt -y install evemu
[ $EUID -ne 0 ] && echo "Error: This script must be run as root" && exit 1
[ "$1" == "" ] && echo "Usage: sudo type.sh [text file]" && exit 1 || inputfile=$1
[ ! -f $inputfile ] && echo "Error: Input file not found" && exit 1
[ ! -x "$(command -v evemu-event)" ] && echo "Error: evemu-event not installed. Exiting." && exit 1

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
    SEC=$(( (RANDOM % 3 ) + 1 )) && sleep 0.0$SEC
}

function keymap {
    case "$char" in
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
            sleep 0.1
        ;;
        $'\t')
            char=TAB
        ;;
        '-')
            char=MINUS
        ;;
        '=')
            char=EQUAL
        ;;
        '"')
            SHIFT=KEY_LEFTSHIFT
            char=APOSTROPHE
        ;;
        '~')
            SHIFT=KEY_RIGHTSHIFT
            char=GRAVE
        ;;
        "'")
            char=APOSTROPHE
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
        '?')
            SHIFT=KEY_LEFTSHIFT
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
        '<')
            SHIFT=KEY_LEFTSHIFT
            char=COMMA
        ;;
        '>')
            SHIFT=KEY_LEFTSHIFT
            char=DOT
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
            SHIFT=KEY_RIGHTSHIFT
            char=3
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
    printf "\n\n>>>  EVEMU Keyboard player starting. Select window... "
    printf "5" && sleep 1
    printf "\b4" && sleep 1
    printf "\b3" && sleep 1
    printf "\b2" && sleep 1
    printf "\b1" && sleep 1
    printf "\b \n\n"
}

# Execute
set_keyboard_input
countdown

# Open VIM with filename
commands="vim $inputfile
ggdG
:set smartindent&"

# Type from variable
while IFS= read -r -n1 char; do
    printf "${char}"
    keymap $char
    press  KEY_$char
    #SEC=$(( (RANDOM % 10 ) + 1 )) && sleep 0.00$SEC
    SEC=$(( (RANDOM % 10 ) + 1 )) && sleep 0.0$SEC
    [ "$char" == "ENTER" ] && SEC=$(( (RANDOM % 10 ) + 1 )) && printf "\n" && sleep 0.$SEC
done <<< "$commands"
echo "INSERT MODE"; press KEY_I

# Type from inputfile
while IFS= read -r -n1 char; do
    printf "${char}"
    keymap $char
    press  KEY_$char
    SEC=$(( (RANDOM % 10 ) + 1 )) && sleep 0.00$SEC
    [ "$char" == "ENTER" ] && SEC=$(( (RANDOM % 10 ) + 1 )) && printf "\n" && sleep 0.$SEC
done < "$inputfile"
echo

# Close VIM file
echo "ESC INSERT MODE"; press KEY_ESC
echo ":wq"; SHIFT=KEY_LEFTSHIFT; press KEY_SEMICOLON; press KEY_W; press KEY_Q; press KEY_ENTER

