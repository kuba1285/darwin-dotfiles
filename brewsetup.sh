#!/bin/bash

current=$(cd $(dirname $0)/../; pwd)

echo "Xcodeをインストールします..."
xcode-select --install

# rosettaのインストール。不要であれば下記1行削除してください
sudo softwareupdate --install-rosetta --agree-to-licensesudo softwareupdate --install-rosetta --agree-to-license

if [ $(uname) = Darwin ]; then
    if ! type brew &> /dev/null ; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "Since Homebrew is already installed, skip this phase and proceed."
    fi
    brew bundle install --file ./Brewfile
fi