#!/bin/bash

# About Brewfile
# 1. Command line tools registered in Homebrew are "brew 'app-name'" (installed with the brew install command)
# 2. Command line tools not registered in Homebrew are "tap 'app-name'" (installed with the brew tap command)
# 3. Normal applications are "cask 'app-name'" (those installed using Homebrew Cask)
# 4. Apps installed from AppStore are "mas 'app name' id:XX"
# 'brew cask' can be used if you install Homebrew, but 'mas' requires 'mas-cli' to be installed.
# Brewfile can be generated by command 'brew bundle dump' and overwritten by '--force' option.
#
# To disable SIP, do the following:
# 1. Restart your computer in Recovery mode with pressing Command (⌘) + R or longpressing Power.
# 2. Launch Terminal from the Utilities menu.
# 3. Run the command 'csrutil disable'.
# 4. Restart your computer.
# 5. Restart your computer.

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"

# Define variables
BIN=$(cd $(dirname $0); pwd)
PARENT=$(cd $(dirname $0)/../; pwd)
INSTLOG="$BIN/install.log"
######

# function that would show a progress bar to the user
show_progress() {
    while ps | grep $1 &> /dev/null ; do
        echo -n "."
        sleep 2
    done
    echo -en "Done!\n"
    sleep 2
}

wait_yn(){
    YN="xxx"
    while [ $YN != 'y' ] && [ $YN != 'n' ] ; do
        read -p "$1 [y/n]" YN
    done
}
######

clear

# give the user an option to exit out
wait_yn $'[\e[1;33mACTION\e[0m] - Would you like to start with the install?'
if [[ $YN = y ]] ; then
    echo -e "$CNT - Setup starting..."
else
    echo -e "$CNT - This script will now exit, no changes were made to your system."
    exit
fi

# Install CLI for Xcode
echo -en "$CNT - Now installing CLI for Xcode."
xcode-select --install &>> $INSTLOG
show_progress $!
echo -e "$COK - Installed."

# Install rosetta
wait_yn $'[\e[1;33mACTION\e[0m] - Would you like to install rosetta?'
if [[ $YN = y ]] ; then
    sudo softwareupdate --install-rosetta --agree-to-licensesudo softwareupdate --install-rosetta --agree-to-license &>> $INSTLOG
    show_progress $!
    echo -e "$COK - Installed."
fi

# Install homebrew
if ! type brew &> /dev/null ; then
    echo -en "$CNT - Now installing Homebrew."
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &>> $INSTLOG
    show_progress $!
    echo -e "$COK - Installed."
else
    echo -e "$CNT - Since Homebrew is already installed, skip this phase and proceed."
fi

# Homebrew path setting
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile

# Install app from Brewfile
wait_yn $'[\e[1;33mACTION\e[0m] - Would you like to install app from Brewfile?'
if [[ $YN = y ]] ; then
    brew bundle install --file $BIN/Brewfile &>> $INSTLOG
    echo -e "$COK - Installed."
fi

# Install custom app
wait_yn $'[\e[1;33mACTION\e[0m] - Would you like to install custom app?'
if [[ $YN = y ]] ; then
    cd
    git clone http://github.com/possatti/pokemonsay &>> $INSTLOG
    cd pokemonsay
    ./install.sh &>> $INSTLOG
    echo -e "$COK - Installed."
fi

# Copy Config Files
wait_yn $'[\e[1;33mACTION\e[0m] - Would you like to copy config files?'
if [[ $YN = y ]] ; then
    echo -e "$CNT - Copying config files..."

    # copy the configs directory
    cp -rT $PARENT/. ~/ &>> $INSTLOG
    cp $PARENT/src/donut.c /Users/$USER/bin/
    echo -e "$COK - Installed."

    echo export \""PATH="\$PATH:/Users/$USER/bin\" >> ~/.zshrc
    echo -e "TMOUT=900\nTRAPALRM() { tput bold && tput setaf 2 && gcc /Users/$USER/bin/donut.c -o /Users/$USER/bin/donut && /Users/$USER/bin/donut }" >> ~/.zshrc
    echo "neowofetch --gap -30 --ascii \"\$(fortune -s | pokemonsay -w 30)\""  >> ~/.zshrc
fi

# yabai sudoers setting
echo "$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 $(which yabai) | cut -d " " -f 1) $(which yabai) --load-sa" | sudo tee /private/etc/sudoers.d/yabai

# A bootplug to match the binary format so that yabai can inject code into the Dock of arm64 binaries.
if [[ $(uname -m) == 'arm64' ]]; then
    sudo nvram boot-args=-arm64e_preview_abi
    echo -en "$COK - A bootplug to match the binary format so that yabai can inject code into the Dock of arm64 binaries."
fi

# Enable services
yabai --start-service
skhd --start-service

# Write default-write setting
source $BIN/parse-plist

# Generate miscelenaeous file
brew bundle dump
parse-plist > parse-plist
sudo ln -s /Users/$USER/Documents /Users/$USER/Documents-ln
sudo ln -s /Users/$USER/Downloads /Users/$USER/Downloads-ln
sudo ln -s /Users/$USER/ /Users/$USER/mymac-ln

# Script is done
echo -e "$CNT - Script had completed!"
