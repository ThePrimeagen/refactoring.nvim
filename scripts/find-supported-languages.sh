#!/bin/bash

lang_files=(./lua/refactoring/treesitter/langs/*)
languages=()
for lang_file in "${lang_files[@]}"
do
    IFS='/' read -r -a lang_file_array <<< "$lang_file"
    IFS='.' read -r -a lang_array <<< "${lang_file_array[5]}"
    languages+=(${lang_array[0]})
done

for lang in "${languages[@]}"
do
    echo -e "\nInstalling $lang"
    nvim --headless --clean \
        -u scripts/ci.vim \
        -c "TSInstallSync $lang" -c "q"
done
