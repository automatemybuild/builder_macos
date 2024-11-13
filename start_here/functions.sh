#!/bin/bash
#
# functions.sh - Common functions used by builder.sh
#
# Updates:
# 07/08/2020 - Created to be souced into scripts that require common functions
# 03/24/2024 - Removed funtions no longer used
# 11/12/2023 - Updated for MacOS
# 

function header () {
    line=$(printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' +)
    printf "\n${YELLOW}${line}${WHITE}${*}${YELLOW}\n${line}${NC}\n"
}
function packagemgr { 
    # Install Homebrew if not already installed
    if [ ! -x "$command -v brew" ];then
	echo "Homebrew not installed. Installing Homebrew."
        xcode-select --install
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Attempt to set up Homebrew PATH automatically for this session
        if [ -x "/opt/homebrew/bin/brew" ]; then
            # For Apple Silicon Macs
            echo "Configuring Homebrew in PATH for Apple Silicon Mac..."
            export PATH="/opt/homebrew/bin:$PATH"
        fi
    fi
    # Verify brew is now accessible
    if ! command -v brew &>/dev/null; then
        echo "Failed to configure Homebrew in PATH. Please add Homebrew to your PATH manually."
        exit 1
    else
        pkgmgr=brew
    fi
}
function brew_update_upgrade_clean {
    [[ -z $pkgmgr ]] && packagemgr
    $pkgmgr update
    $pkgmgr upgrade
    $pkgmgr upgrade --cask
    $pkgmgr cleanup
}
function install_common_packages {
    [[ -z $pkgmgr ]] && packagemgr
    # Define an array of packages to install using Homebrew.
    packages=(
        "python"
        "bash"
        "zsh"
        "git"
        "tree"
        "pylint"
        "black"
        "tmux"
        "nmap"
        "mtr"
        "wireshark"
        "iftop"
        "iperf3"
        "htop"
        "inxi"
        "figlet"
    )
    # Loop over the array to install each application.
    for package in "${packages[@]}"; do
        if brew list --formula | grep -q "^$package\$"; then
            echo "$package is already installed. Skipping..."
        else
            header $package
            brew install "$package"
        fi
    done
}
function install_common_applications {
    [[ -z $pkgmgr ]] && packagemgr
    # Define an array of applications to install using Homebrew Cask.
    apps=(
        "google-chrome"
        "firefox"
        "discord"
        "slack"
        "gimp"
        "vlc"
        "keyboardcleantool"
        "beyond-compare"
        "quodlibet"
        "electrum"
    )
    
    # Loop over the array to install each application.
    for app in "${apps[@]}"; do
        if brew list --cask | grep -q "^$app\$"; then
            echo "$app is already installed. Skipping..."
        else
            header $app
            brew install --cask "$app"
        fi
    done
}
function install_common_fonts {
    [[ -z $pkgmgr ]] && packagemgr
    # Install fonts
    brew tap | grep -q "^homebrew/cask-fonts$" || brew tap homebrew/cask-fonts
    
    fonts=(
        "font-source-code-pro"
        "font-lato"
        "font-oswald"
    )
    
    for font in "${fonts[@]}"; do
        # Check if the font is already installed
        if brew list --cask | grep -q "^$font\$"; then
            echo "$font is already installed. Skipping..."
        else
            header $font
            brew install --cask "$font"
        fi
    done
}
fuction custom_macos_settings {
    echo ">> Set scroll as traditional instead of natural"
    defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
    killall Finder
        
    echo ">> Set location for screenshots"
    mkdir "${HOME}/Desktop/Screenshots"
    defaults write com.apple.screencapture location "${HOME}/Desktop/Screenshots"
    killall SystemUIServer

    echo ">> Add Bluetooth to Menu Bar for battery percentages"
    defaults write com.apple.controlcenter "NSStatusItem Visible Bluetooth" -bool true
    killall ControlCenter
}
