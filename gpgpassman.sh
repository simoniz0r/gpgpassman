#!/bin/bash
# A script that uses 'gpg' to encrypt and decrypt passwords stored in '~/.gpgpassman'.
# Dependencies: 'gpg', 'xclip', 'git' and 'wget' (optional; for updating gpgpassman), 'apg' (optional; for generationg passwords), 'zenity' (optional; for GUI)
# If you have 'zenity' installed, executing 'gpgpassman gui' will show a full GUI for all of the scripts options.
# Written by simonizor 3/22/2017 - http://www.simonizor.gq/linuxapps -- License: GPLv2 Only


GPMVER="1.5.0"
X="Change: Remove self updating function.  tar-pkg is recommended for upgrading gpgpassman in the future."
# ^^Remember to update this every release and do not move their position!
SCRIPTNAME="$0"
GPMDIR="$(< ~/.config/gpgpassman/gpgpassman.conf)"
GPMINITDIR=~/.gpgpassman
GPMCONFDIR=~/.config/gpgpassman
SERVNAME="$2"
bold=$(tput bold)
normal=$(tput sgr0)

updatecheck () {
    echo "Checking for new version..."
    UPNOTES="$(wget -q "https://raw.githubusercontent.com/simoniz0r/gpgpassman/master/gpgpassman.sh" -O - | sed -n '9p' | tr -d 'X="')"
    VERTEST="$(wget -q "https://raw.githubusercontent.com/simoniz0r/gpgpassman/master/gpgpassman.sh" -O - | sed -n '8p' | tr -d 'GPMVER="')"
    if [[ $GPMVER < $VERTEST ]]; then
        if [ "$ZENITYGUI" != "1" ]; then
            echo "Installed version: $GPMVER -- Current version: $VERTEST"
            echo "A new version is available!"
            echo "$UPNOTES"
        else
            zenity --info --title=gpgpassman --text="A new version is available!\n\n$UPNOTES"
            zenitystart
        fi
    else
        if [ "$ZENITYGUI" = "1" ]; then
            zenity --info --title=gpgpassman --text="gpgpassman is up to date."
            zenitystart
        else
            echo "Installed version: $GPMVER -- Current version: $VERTEST"
            echo "$UPNOTES"
            echo "gpgpassman is up to date."
        fi
    fi
}

programisinstalled () {
  return=1
  type "$1" >/dev/null 2>&1 || { return=0; }
}

helpfunc () {
    echo
    echo "Currently managed services:"
    ls $GPMDIR | tr ' ' '\n'
    echo
    echo "Current password storage directory: $GPMDIR"
    echo
    echo "${bold}Usage:"
    echo "${bold}add${normal} - Add encrypted password file."
    echo "- Ex: 'gpgpassman add servicename'"
    echo "${bold}dec${normal} - Decrypt a stored password file using the service name and copy to clipboard for 45 seconds."
    echo "- Ex: 'gpgpassman dec servicename'"
    echo "${bold}bac${normal} - Backup your passwords to a new directory."
    echo "- Ex: 'gpgpassman bac /home/simonizor/passwordbackup'"
    echo "${bold}rem${normal} - Remove a stored password file using the service name."
    echo "- Ex: 'gpgpassman rem servicename'"
    echo "${bold}dir${normal} - Change default directory used by gpgpassman. Only passwords in the currently configured directory will be able to be managed."
    echo "- Ex: 'gpgpassman dir /path/to/directory'."
    echo "${bold}gen${normal} - Generate new passwords using 'apg'."
    echo "- Ex: 'gpgpassman gen'"
    echo "${bold}gui${normal} - If 'zenity' is installed, gpgpassman's GUI will be launched."
    echo "- Ex: 'gpgpassman gui'"
}

zenitymain () {
    case $1 in
        Add*)
            SERVNAME=$(zenity --entry --title=gpgpassman --cancel-label="Main menu" --width=540 --height=460 --text="Add a new encrypted password.\n\nYou will be prompted for two different password inputs.\nThe first is the password that you use to login to the service.\nThe second is the password used for gpg encryption.\n\nYou will be prompted to overwrite already managed services.\n\n\n\n\n\n\n\n\n\n\nEnter the service name to encrypt a password for:")
            if [[ $? -eq 1 ]]; then
                exec "$SCRIPTNAME" gui
            fi
            if [ -f "$GPMDIR/$SERVNAME/$SERVNAME.gpg" ];then
                zenity --question --title=gpgpassman --text="Password for $SERVNAME is already stored; overwrite (clipboard will also be cleared)?" --cancel-label=No --ok-label=Yes
                if [[ $? -eq 1 ]]; then
                    zenity --warning --title=gpgpassman --text="Password for $SERVNAME was not overwritten."
                    exec "$SCRIPTNAME" gui
                else
                    echo -n "$(gpg -d $GPMDIR/$SERVNAME/$SERVNAME.gpg)" | xclip -selection c -i
                    if [ "$(xclip -selection c -o)" = "" ]; then
                        zenity --error --title=gpgpassman --text="Wrong password or gpg failure!"
                        exec "$SCRIPTNAME" gui
                    fi
                    zenity --warning --title=gpgpassman --text="Stored password for $SERVNAME removed"
                    rm -f $GPMDIR/$SERVNAME/$SERVNAME.gpg
                fi
            fi
            if [ -z $SERVNAME ]; then
                zenity --error --title=gpgpassman --timeout=5 --text="No service name entered; try again."
                exec "$SCRIPTNAME" gui
            fi
            PASSINPUT=$(zenity --entry --title=gpgpassman --hide-text --text="Enter your password for $SERVNAME:")
            if [[ $? -eq 1 ]]; then
                exec "$SCRIPTNAME" gui
            fi
            PASSINPUT2=$(zenity --entry --title=gpgpassman --hide-text --text="Input password again for $SERVNAME:")
            if [[ $? -eq 1 ]]; then
                exec "$SCRIPTNAME" gui
            fi
            if [ "$PASSINPUT" != "$PASSINPUT2" ]; then
                zenity --error --title=gpgpassman --text="Passwords to not match; try again!"
                exec "$SCRIPTNAME" gui
            fi
            if [ ! -d "$GPMDIR" ]; then
                mkdir $GPMDIR
            fi
            if [ ! -d "$GPMDIR/$SERVNAME" ]; then
                mkdir $GPMDIR/$SERVNAME
            fi
            zenity --warning --title=gpgpassman --timeout=5 --text="Enter the password to be used for encryption/decryption:"
            echo "$PASSINPUT" | gpg --no-tty -c -o $GPMDIR/$SERVNAME/$SERVNAME.gpg
            if [ -f "$GPMDIR/$SERVNAME/$SERVNAME.gpg" ]; then
                zenity --warning --title=gpgpassman --text="Password for $SERVNAME encrypted in $GPMDIR/$SERVNAME/$SERVNAME.gpg"
                exec "$SCRIPTNAME" gui
            else
                zenity --error --title=gpgpassman --text="Failed to write encrypted file for $SERVNAME in $GPMDIR/$SERVNAME/$SERVNAME.gpg"
                exec "$SCRIPTNAME" gui
            fi
            ;;
        Decrypt*)
            SERVNAME="$(ls $GPMDIR | tr ' ' '\n' | zenity --list --cancel-label="Main menu" --width=540 --height=460 --title=gpgpassman --text="Password storage directory:\n$GPMDIR\n\nSelect a password to decrypt:" --column="Cases" --hide-header)"
            if [[ $? -eq 1 ]]; then
                exec "$SCRIPTNAME" gui
            fi
            if [ -z "$SERVNAME" ]; then
                zenity --error --title=gpgpassman --timeout=5 --text="No service name entered; try again."
                exec "$SCRIPTNAME" gui
            fi
            echo -n "$(gpg --no-tty -d $GPMDIR/$SERVNAME/$SERVNAME.gpg)" | xclip -selection c -i
            if [ "$(xclip -selection c -o)" = "" ]; then
                zenity --error --title=gpgpassman --text="Wrong password or gpg failure!"
                exec "$SCRIPTNAME" gui
            fi
            zenity --forms --title=gpgpassman --timeout=45 --text="Copied password to clipboard; clipboard will be cleared after 45 seconds..." --cancel-label="Clear now and return to main" --ok-label="Clear now and close"
            if [[ $? -eq 0 ]]; then
                echo -n "Password cleared from clipboard" | xclip -selection c -i
                exit 0
            else
                echo -n "Password cleared from clipboard" | xclip -selection c -i
                exec "$SCRIPTNAME" gui
            fi
            ;;
        Backup*)
            SERVNAME=$(zenity --file-selection --directory --title="gpgpassman -- Select a location to back up your passwords")
            if [[ $? -eq 1 ]]; then
                exec "$SCRIPTNAME" gui
            fi
            if [ ! -d $SERVNAME ]; then
                mkdir $SERVNAME
                zenity --warning --title=gpgpassman --timeout=5 --text="$SERVNAME directory created for password backup."
            fi
            cp -r $GPMDIR/* $SERVNAME/ || { zenity --error --title=gpgpassman --text="Backup failed!" ; zenitymain ; }
            zenity --warning --title=gpgpassman --timeout=5 --text="Passwords have been backed up to $SERVNAME."
            exec "$SCRIPTNAME" gui
            ;;
        Remove*)
            SERVNAME=$(zenity --entry --cancel-label="Main menu" --width=540 --height=460 --title=gpgpassman --text="Remove an encrypted password.\n\nThe password for the service name you enter will be deleted permanently!\nYou will be asked for the gpg encryption password before removal.\n\nPassword storage directory:\n$GPMDIR\n\nManaged services:\n$(dir $GPMDIR)\n\n\n\n\n\nEnter the service name to remove:")
            if [[ $? -eq 1 ]]; then
                exec "$SCRIPTNAME" gui
            fi
            if [ -z $SERVNAME ]; then
                zenity --error --title=gpgpassman --timeout=5 --text="No service name entered; try again."
                exec "$SCRIPTNAME" gui
            fi
            zenity --question --title=gpgpassman --text="Passwords cannot be recovered; are you sure you want to remove password for $SERVNAME?" --ok-label="Yes"
            if [[ $? -eq 1 ]]; then
                zenity --warning --title=gpgpassman --text="Password for $SERVNAME was not removed."
                exec "$SCRIPTNAME" gui
            else
                echo -n "$(gpg --no-tty -d $GPMDIR/$SERVNAME/$SERVNAME.gpg)" | xclip -selection c -i
                if [ "$(xclip -selection c -o)" = "" ]; then
                    zenity --error --title=gpgpassman --text="Wrong password or gpg failure!"
                    exec "$SCRIPTNAME" gui
                fi
                echo -n "Password cleared from clipboard" | xclip -selection c -i
                rm -rf $GPMDIR/$SERVNAME
                zenity --warning --title=gpgpassman --text="Password for $SERVNAME was removed!"
                exec "$SCRIPTNAME" gui
            fi
            ;;
        Change*)
            SERVNAME=$(zenity --file-selection --directory --title="gpgpassman -- Select a new password storage directory")
            if [[ $? -eq 1 ]]; then
                exec "$SCRIPTNAME" gui
            fi
            zenity --question --title=gpgpassman --text="Only one directory can be managed by gpgpassman at a time; change password storage directory to $SERVNAME?" --ok-label="Yes"
            if [[ $? -eq 1 ]]; then
                exec "$SCRIPTNAME" gui
            fi
            if [ ! -d $SERVNAME ]; then
                mkdir $SERVNAME || { zenity --error --title=gpgpassman --text="Could not create directory!" ; zenitymain ; }
                zenity --warning --title=gpgpassman --timeout=5 --text="$SERVNAME directory created for gpgpassman storage."
            fi
            echo "$SERVNAME" > $GPMCONFDIR/gpgpassman.conf
            zenity --warning --title=gpgpassman --timeout=5 --text="gpgpassman storage directory changed to $(< ~/.config/gpgpassman/gpgpassman.conf)"
            exec "$SCRIPTNAME" gui
            ;;
        Generate*)
             programisinstalled "apg"
            if [ "$return" = "1" ]; then
                { echo "Passwords generated using 'apg -a 1 -m 30 -n 4':" ; apg -a 1 -m 30 -n 4 ; } | zenity --text-info --cancel-label=Exit --width=540 --height=460 --title=gpgpassman
                if [[ $? -eq 1 ]]; then
                    exit 0
                fi
                exec "$SCRIPTNAME" gui
            else
                zenity --error --title=gpgpassman --text="apg is not installed; cannot generate passwords!"
                exec "$SCRIPTNAME" gui
            fi
            ;;
        Check*)
            programisinstalled "wget"
            if [ "$return" = "1" ]; then
                programisinstalled "git"
                if [ "$return" = "1" ]; then
                    updatecheck
                else
                    zenity --error --title=gpgpassman --text="'git' is not installed; cannot download updates!"
                    exec "$SCRIPTNAME" gui
                fi
            else
                zenity --error --title=gpgpassman --text="'wget' is not installed; cannot check for updates!"
                exec "$SCRIPTNAME" gui
            fi
            ;;
        *)
            exit 0
            ;;
    esac
}

zenitystart () {
    ZMAINCASE=$(zenity --list --cancel-label=Exit --width=540 --height=460 --title=gpgpassman --text="Welcome to gpgpassman v$GPMVER\n\ngpgpassman is a password manager that uses 'gpg' for encryption.\n\nPassword storage directory:\n$GPMDIR\n\nManaged passwords:\n$(dir $GPMDIR)\n\nWhat would you like to do?" --column="Cases" --hide-header "Add a new encrypted password" "Decrypt a stored password" "Backup your stored passwords" "Remove a stored password" "Change password storage directory" "Generate passwords using 'apg'" "Check for gpgpassman update")
    if [[ $? -eq 1 ]]; then
        exit 0
    fi
    ZENITYGUI="1"
    zenitymain "$ZMAINCASE"
}

main () {
    case $1 in
        add*|Add*)
            if [ -z $SERVNAME ]; then
                read -p "Input the service name to encrypt a password for: " SERVNAME
            fi
            if [ -f "$GPMDIR/$SERVNAME/$SERVNAME.gpg" ];then
                read -p "Password for $SERVNAME is already stored; overwrite (clipboard will also be cleared)? Y/N"
                if [[ $REPLY =~ ^[Nn]$ ]]; then
                    echo "Password for $SERVNAME was not overwritten."
                    exit 1
                else
                    echo -n "$(gpg -d $GPMDIR/$SERVNAME/$SERVNAME.gpg)" | xclip -selection c -i
                    if [ "$(xclip -selection c -o)" = "" ]; then
                        echo "Wrong password or gpg failure!"
                        exit 1
                    fi
                    echo -n "Password cleared from clipboard" | xclip -selection c -i
                fi
            fi
            if [ -z $SERVNAME ]; then
                echo "No service name entered; exiting..."
                exit 1
            fi
            echo "Input your password for $SERVNAME:"
            read -s PASSINPUT
            echo
            echo "Input password again for $SERVNAME:"
            read -s PASSINPUT2
            echo
            if [ "$PASSINPUT" != "$PASSINPUT2" ]; then
                echo "Passwords do not match; exiting..."
                exit 1
            fi
            if [ ! -d "$GPMDIR" ]; then
                mkdir $GPMDIR
            fi
            if [ ! -d "$GPMDIR/$SERVNAME" ]; then
                mkdir $GPMDIR/$SERVNAME
            fi
            echo "$PASSINPUT" | gpg -c -o $GPMDIR/$SERVNAME/$SERVNAME.gpg
            if [ -f "$GPMDIR/$SERVNAME/$SERVNAME.gpg" ]; then
                echo "Password for $SERVNAME encrypted in $GPMDIR/$SERVNAME/$SERVNAME.gpg"
                exit 0
            else
                echo "Failed to write encrypted file for $SERVNAME in $GPMDIR/$SERVNAME/$SERVNAME.gpg"
                exit 1
            fi
            ;;
        dec*|Dec*)
            if [ -z "$SERVNAME" ]; then
                echo "Currently managed services:"
                ls $GPMDIR | tr ' ' '\n'
                echo
                echo "Current password storage directory: $GPMDIR"
                echo
                read -p "Enter the service name to decrypt password for: " SERVNAME
            fi
            if [ -f "$GPMDIR/$SERVNAME/$SERVNAME.gpg" ];then 
                echo "Decrypting password for $SERVNAME"
                sleep 0.5
                echo -n "$(gpg -d $GPMDIR/$SERVNAME/$SERVNAME.gpg)" | xclip -selection c -i
                if [ "$(xclip -selection c -o)" = "" ]; then
                    echo "Wrong password or gpg failure!"
                    exit 1
                fi
                echo "$SERVNAME password copied to clipboard; clipboard will be cleared after 45 seconds..."
                trap '{ echo ; echo "Keyboard interruppt; clearing password..." ; echo -n "Password cleared from clipboard" | xclip -selection c -i ; echo "Password cleard from clipboard." ; exit 0 ; }' INT
                sleep 45
                echo -n "Password cleared from clipboard" | xclip -selection c -i
                echo "Password cleard from clipboard."
                exit 0
            else
                echo "No password found for $SERVNAME"
                exit 1
            fi
            ;;
        bac*|Bac*)
            if [ -z $SERVNAME ]; then
                read -p "Input the full directory to backup your passwords to. Ex: '/home/simonizor/passwordbackup': " SERVNAME
            fi
            if [ "${SERVNAME: -1}" = "/" ]; then
                SERVNAME="${SERVNAME::-1}"
            fi
            if [[ "$SERVNAME" == /* ]]; then
                if [ ! -d $SERVNAME ]; then
                    mkdir $SERVNAME
                    echo "$SERVNAME directory created for password backup."
                fi
                cp -r $GPMDIR/* $SERVNAME/ || { echo "Backup failed!" ; exit 1 ; }
                echo "Passwords have been backed up to $SERVNAME."
                exit 0
            else
                echo "$SERVNAME is not a valid directory; use full directory path. Ex: 'gpgpassman bac /home/simonizor/passwordbackup'"
                helpfunc
                exit 1
            fi
            ;;
        rem*|Rem*)
            if [ -z "$SERVNAME" ]; then
                echo "Currently managed services:"
                ls $GPMDIR | tr ' ' '\n'
                echo
                echo "Current password storage directory: $GPMDIR"
                echo
                read -p "Input the service name for the password you want to remove: " SERVNAME
            fi
            if [ -z $SERVNAME ]; then
                echo "No service name entered; exiting..."
                exit 1
            fi
            if [ -f "$GPMDIR/$SERVNAME/$SERVNAME.gpg" ];then
                read -p "Passwords cannot be recovered; are you sure you want to remove the encrypted password for $SERVNAME? Y/N " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    echo -n "$(gpg -d $GPMDIR/$SERVNAME/$SERVNAME.gpg)" | xclip -selection c -i
                    if [ "$(xclip -selection c -o)" = "" ]; then
                        echo "Wrong password or gpg failure!"
                        exit 1
                    fi
                    echo -n "Password cleared from clipboard" | xclip -selection c -i
                    rm -rf $GPMDIR/$SERVNAME
                    echo "Password for $SERVNAME removed!"
                    exit 0
                else
                    echo "Password for $SERVNAME was not removed."
                    exit 1
                fi
            else
                echo "No password found for $SERVNAME"
                exit 1
            fi
            ;;
        dir*)
            if [ -z $SERVNAME ]; then
                read -p "Input the full directory to change password storage to. Ex: '/home/simonizor/mypasswords': " SERVNAME
            fi
            if [ "${SERVNAME: -1}" = "/" ]; then
                SERVNAME="${SERVNAME::-1}"
            fi
            if [[ "$SERVNAME" == /* ]]; then
                read -p "Only one directory can be managed by gpgpassman at a time; change password storage directory to $SERVNAME? Y/N " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    if [ ! -d $SERVNAME ]; then
                        mkdir $SERVNAME || { echo "Could not create directory!" ; exit 1 ; }
                        echo "$SERVNAME directory created for gpgpassman storage."
                    fi
                    echo "$SERVNAME" > $GPMCONFDIR/gpgpassman.conf
                    echo "gpgpassman storage directory changed to $(< ~/.config/gpgpassman/gpgpassman.conf)"
                    exit 0
                else
                    echo "gpgpassman storage directory was not changed."
                    exit 0
                fi
            else
                echo "$SERVNAME is not a valid directory; use full directory path. Ex: 'gpgpassman dir /home/simonizor/mypasswords'"
                helpfunc
                exit 1
            fi
            ;;
        gen*|Gen*)
            programisinstalled "apg"
            if [ "$return" = "1" ]; then
                echo "Passwords generated using 'apg -a 1 -m 30 -n 4':"
                apg -a 1 -m 30 -n 4
                echo
                read -p "Press ENTER to continue; terminal window will be cleared"
                tput reset
                exit 0
            else
                echo "apg is not installed!"
                exit 1
            fi
            ;;
        h*)
            echo "gpgpassman - http://www.simonizor.gq/linuxapps"
            echo "A script that uses 'gpg' to encrypt and decrypt passwords."
            helpfunc
            echo
            programisinstalled "wget"
            if [ $return = "1" ]; then
                programisinstalled "git"
                if [ $return = "1" ]; then
                    updatecheck
                fi
            fi
            exit 0
            ;;
        help)
            echo "gpgpassman - http://www.simonizor.gq/linuxapps"
            echo "A script that uses 'gpg' to encrypt and decrypt passwords."
            helpfunc
            echo
            programisinstalled "wget"
            if [ $return = "1" ]; then
                programisinstalled "git"
                if [ $return = "1" ]; then
                    updatecheck
                fi
            fi
            exit 0
            ;;
        exit*|Exit*)
            exit 0
            ;;
        *)
            programisinstalled "zenity"
            if [ $return = "1" ]; then
                zenitystart
            else
                echo "gpgpassman - http://www.simonizor.gq/linuxapps"
                echo "A script that uses 'gpg' to encrypt and decrypt passwords."
                echo "gpgpassman now has a GUI; install 'zenity' to check it out!"
                echo
                helpfunc
                echo
                exit 0
            fi
            ;;
    esac
}

if [ ! -f "$GPMCONFDIR/gpgpassman.conf" ]; then
    echo "$GPMCONFDIR does not exist; creating..."
    mkdir $GPMCONFDIR
    mkdir $GPMINITDIR
    echo "$GPMINITDIR" > $GPMCONFDIR/gpgpassman.conf
    zenity --error --text="$GPMCONFDIR created and config file written; run gpgpassman again." || echo "$GPMCONFDIR created and config file written; run gpgpassman again."
    exit 0
fi
programisinstalled "gpg"
if [ $return = "1" ]; then
    programisinstalled "xclip"
    if [ $return = "1" ]; then
        main "$1"
    else
        zenity --error --text="xclip is not installed!" || echo "xclip is not installed!"
        exit 1
    fi
else
    zenity --error --text="gpg is not installed!" || echo "gpg is not installed!"
    exit 1
fi
