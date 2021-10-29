#!/bin/sh

cd queries
languages=$(find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
cd ..

for lang in $languages
do
    echo "\nInstalling $lang"
    nvim --headless --clean \
        -u ci.vim \
        -c "TSInstallSync $lang" -c "q"
done
