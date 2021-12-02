#!/bin/bash

languages=(javascript typescript cpp go python lua)

for lang in "${languages[@]}"
do
    echo -e "\nInstalling $lang"
    nvim --headless --clean \
        -u scripts/ci.vim \
        -c "TSInstallSync $lang" -c "q"
done
