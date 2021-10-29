#!/bin/sh

pwd

cd queries
languages=$(find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
cd -

echo $languages

for lang in $languages
do
    echo "\nInstalling $lang"
    nvim --headless --clean \
        -u scripts/ci.vim \
        -c "TSInstallSync $lang" -c "q"
done
