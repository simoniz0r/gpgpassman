#!/bin/bash
# Code from https://github.com/Microsoft/vscode/issues/1884#issuecomment-230790242
# A quick and semi-dirty script that will append the color code of your choice to VSCode's CSS file to change the color of the status bar.
# Make a backup of your 'workbench.main.css' file before using this, and only use it once per update/install.

echo "Input the color you would like to change the status bar in hex format"
read -p "Color #" COLOR
GETDIR="$(readlink -f $(which code))"
DIR="${GETDIR::-9}"
    echo ".monaco-workbench>.part.statusbar{background-color:#$COLOR;}" | sudo tee -a "$DIR"/resources/app/out/vs/workbench/electron-browser/workbench.main.css
    echo "Status bar color changed to #$COLOR!"
    exit 1