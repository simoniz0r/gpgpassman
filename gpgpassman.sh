#!/bin/bash
# A script that uses 'gpg' to encrypt and decrypt passwords stored in '~/.gpgpassman'.
# Dependencies: 'gpg', 'xclip', 'git' and 'wget' (optional; for updating gpgpassman), 'apg' (optional; for generationg passwords), 'zenity' (optional; for GUI)
# If you have 'zenity' installed, executing 'gpgpassman gui' will show a full GUI for all of the scripts options.
# Written by simonizor 3/22/2017 - http://www.simonizor.gq/linuxapps

GPMVER="1.4.2"
X="v1.4.2 - Moved all zenity GUI related things into the zenitymain function in order to clean up the main function."
# ^^Remember to update this every release and do not move their position!
SCRIPTNAME="$0"
GPMDIR="$(< ~/.config/gpgpassman/gpgpassman.conf)"
GPMINITDIR=~/.gpgpassman
GPMCONFDIR=~/.config/gpgpassman
SERVNAME="$2"
bold=$(tput bold)
normal=$(tput sgr0)

updatescript () {
cat >/tmp/updatescript.sh <<EOL
runupdate () {
    if [ "$SCRIPTNAME" = "/usr/bin/gpgpassman" ]; then
        git clone https://github.com/simoniz0r/gpgpassman.git /tmp/gpgpassman
        if [ -f "/tmp/gpgpassman/gpgpassman.sh" ]; then
            sudo rm -f /usr/bin/gpgpassman
            sudo mv /tmp/gpgpassman/gpgpassman.sh /usr/bin/gpgpassman
            rm -rf /tmp/gpgpassman
            sudo chmod +x /usr/bin/gpgpassman
        else
            read -p "Update Failed! Try again? Y/N " -n 1 -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                runupdate
            else
                echo "gpgpassman was not updated!"
                exit 0
            fi
        fi
    else
        git clone https://github.com/simoniz0r/gpgpassman.git /tmp/gpgpassman
        if [ -f "/tmp/gpgpassman/gpgpassman.sh" ]; then
            rm -f $SCRIPTNAME
            mv /tmp/gpgpassman/gpgpassman.sh $SCRIPTNAME
            rm -rf /tmp/gpgpassman
            chmod +x $SCRIPTNAME
        else
            read -p "Update Failed! Try again? Y/N " -n 1 -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                runupdate
            else
                echo "gpgpassman was not updated!"
                exit 0
            fi
        fi
    fi
    if [ -f $SCRIPTNAME ]; then
        echo "Update finished!"
        rm -f /tmp/updatescript.sh
    else
        read -p "Update Failed! Try again? Y/N " -n 1 -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            runupdate
        else
            echo "gpgpassman was not updated!"
            exit 0
        fi
    fi
}
runupdate
EOL
}

zenityupdatescript () {
cat >/tmp/zenityupdatescript.sh <<EOL
runupdate () {
    if [ "$SCRIPTNAME" = "/usr/bin/gpgpassman" ]; then
        git clone https://github.com/simoniz0r/gpgpassman.git /tmp/gpgpassman
        if [ -f "/tmp/gpgpassman/gpgpassman.sh" ]; then
            zenity --password --title=gpgpassman | sudo -S rm -f /usr/bin/gpgpassman || { zenity --error --title=gpgpassman --text="Incorrect password!" ; exec $SCRIPTNAME gui ; exit 0 ; }
            sudo  mv /tmp/gpgpassman/gpgpassman.sh /usr/bin/gpgpassman
            rm -rf /tmp/gpgpassman
            sudo  chmod +x /usr/bin/gpgpassman
            sudo -K
        else
            zenity --question --title=gpgpassman --text="Update Failed! Try again? "
            if [[ $? -eq 0 ]]; then
                runupdate
            else
                zenity --error --title=gpgpassman --text="gpgpassman was not updated!"
                exec $SCRIPTNAME gui
                exit 0
            fi
        fi
    else
        git clone https://github.com/simoniz0r/gpgpassman.git /tmp/gpgpassman
        if [ -f "/tmp/gpgpassman/gpgpassman.sh" ]; then
            rm -f $SCRIPTNAME
            mv /tmp/gpgpassman/gpgpassman.sh $SCRIPTNAME
            rm -rf /tmp/gpgpassman
            chmod +x $SCRIPTNAME
        else
            zenity --question --title=gpgpassman --text="Update Failed! Try again? "
            if [[ $? -eq 0 ]]; then
                runupdate
            else
                zenity --error --title=gpgpassman --text="gpgpassman was not updated!"
                exec $SCRIPTNAME gui
                exit 0
            fi
        fi
    fi
    if [ -f $SCRIPTNAME ]; then
        zenity --info --title=gpgpassman --text="Update finished!"
        rm -f /tmp/updatescript.sh
        exec $SCRIPTNAME gui
        exit 0
    else
        zenity --question --title=gpgpassman --text="Update Failed! Try again? "
            if [[ $? -eq 0 ]]; then
            runupdate
        else
            zenity --error --title=gpgpassman --text="gpgpassman was not updated!"
            exec $SCRIPTNAME gui
            exit 0
        fi
    fi
}
runupdate
EOL
}

updatecheck () {
    echo "Checking for new version..."
    UPNOTES="$(wget -q "https://raw.githubusercontent.com/simoniz0r/gpgpassman/master/gpgpassman.sh" -O - | sed -n '9p' | tr -d 'X="')"
    VERTEST="$(wget -q "https://raw.githubusercontent.com/simoniz0r/gpgpassman/master/gpgpassman.sh" -O - | sed -n '8p' | tr -d 'GPMVER="')"
    if [[ $GPMVER < $VERTEST ]]; then
        if [ "$ZHEADLESS" != "1" ]; then
            echo "Installed version: $GPMVER -- Current version: $VERTEST"
            echo "A new version is available!"
            echo "$UPNOTES"
            read -p "Would you like to update? Y/N " -n 1 -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo
                echo "Creating update script..."
                updatescript
                chmod +x /tmp/updatescript.sh
                echo "Running update script..."
                exec /tmp/updatescript.sh
                exit 0
            else
                echo
                echo "gpgpassman was not updated."
            fi
        else
            zenity --question --title=gpgpassman --text="A new version is available; would you like to update?\n\n$UPNOTES"
            if [ $? -eq 0 ]; then
                zenityupdatescript
                chmod +x /tmp/zenityupdatescript.sh
                exec /tmp/zenityupdatescript.sh
                exit 0
            else
                zenity --warning --title=gpgpassman --text="gpgpassman was not updated!"
                zenitymain
            fi
        fi
    else
        if [ "$ZHEADLESS" = "1" ]; then
            zenity --info --title=gpgpassman --text="gpgpassman is up to date."
            zenitymain
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
    echo "Currently managed services: $(dir $GPMDIR)"
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
            if [ -z $SERVNAME ]; then
                SERVNAME=$(zenity --entry --title=gpgpassman --cancel-label="Main menu" --width=540 --height=460 --text="Add a new encrypted password.\n\nYou will be prompted for two different password inputs.\nThe first is the password that you use to login to the service.\nThe second is the password used for gpg encryption.\n\nYou will be prompted to overwrite already managed services.\n\n\n\n\n\n\n\n\n\n\nEnter the service name to encrypt a password for:")
                if [[ $? -eq 1 ]]; then
                    SERVNAME=""
                    zenitymain
                fi
            fi
            if [ -f "$GPMDIR/$SERVNAME/$SERVNAME.gpg" ];then
                zenity --question --title=gpgpassman --text="Password for $SERVNAME is already stored; overwrite (clipboard will also be cleared)?" --cancel-label=No --ok-label=Yes
                if [[ $? -eq 1 ]]; then
                    zenity --warning --title=gpgpassman --text="Password for $SERVNAME was not overwritten."
                    SERVNAME=""
                    zenitymain
                else
                    echo -n "$(gpg -d $GPMDIR/$SERVNAME/$SERVNAME.gpg)" | xclip -selection c -i
                    if [ "$(xclip -selection c -o)" = "" ]; then
                        zenity --error --title=gpgpassman --text="Wrong password or gpg failure!"
                        SERVNAME=""
                        zenitymain "Add"
                    fi
                    zenity --warning --title=gpgpassman --text="Stored password for $SERVNAME removed"
                    rm -f $GPMDIR/$SERVNAME/$SERVNAME.gpg
                fi
            fi
            if [ -z $SERVNAME ]; then
                zenity --error --title=gpgpassman --timeout=5 --text="No service name entered; try again."
                SERVNAME=""
                zenitymain "Add"
            fi
            PASSINPUT=$(zenity --entry --title=gpgpassman --hide-text --text="Enter your password for $SERVNAME:")
            if [[ $? -eq 1 ]]; then
                SERVNAME=""
                zenitymain
            fi
            PASSINPUT2=$(zenity --entry --title=gpgpassman --hide-text --text="Input password again for $SERVNAME:")
            if [[ $? -eq 1 ]]; then
                SERVNAME=""
                zenitymain
            fi
            if [ "$PASSINPUT" != "$PASSINPUT2" ]; then
                zenity --error --title=gpgpassman --text="Passwords to not match; try again!"
                SERVNAME=""
                zenitymain "Add"
            fi
            if [ ! -d "$GPMDIR" ]; then
                mkdir $GPMDIR
            fi
            if [ ! -d "$GPMDIR/$SERVNAME" ]; then
                mkdir $GPMDIR/$SERVNAME
            fi
            zenity --warning --title=gpgpassman --timeout=5 --text="Enter the password to be used for encryption/decryption:"
            echo "$PASSINPUT" | gpg -c -o $GPMDIR/$SERVNAME/$SERVNAME.gpg
            if [ -f "$GPMDIR/$SERVNAME/$SERVNAME.gpg" ]; then
                zenity --warning --title=gpgpassman --text="Password for $SERVNAME encrypted in $GPMDIR/$SERVNAME/$SERVNAME.gpg"
                SERVNAME=""
                zenitymain
            else
                zenity --error --title=gpgpassman --text="Failed to write encrypted file for $SERVNAME in $GPMDIR/$SERVNAME/$SERVNAME.gpg"
                SERVNAME=""
                zenitymain
            fi
            ;;
        Decrypt*)
            SERVNAME=$(zenity --file-selection --file-filter=*.gpg --title="gpgpassman -- Select the gpg file to decrypt" --filename=$GPMDIR/)
            if [[ $? -eq 1 ]]; then
                SERVNAME=""
                zenitymain
            fi
            echo -n "$(gpg -d $SERVNAME)" | xclip -selection c -i
            if [ "$(xclip -selection c -o)" = "" ]; then
                zenity --error --title=gpgpassman --text="Wrong password or gpg failure!"
                SERVNAME=""
                zenitymain "Decrypt"
            fi
            zenity --forms --title=gpgpassman --timeout=45 --text="Copied password to clipboard; clipboard will be cleared after 45 seconds..." --cancel-label="Clear now and return to main" --ok-label="Clear now and close"
            if [[ $? -eq 1 ]]; then
                echo -n "Password cleared from clipboard" | xclip -selection c -i
                SERVNAME=""
                zenitymain
            else
                echo -n "Password cleared from clipboard" | xclip -selection c -i
                SERVNAME=""
                zenitymain
            fi
            ;;
        Backup*)
            SERVNAME=$(zenity --file-selection --directory --title="gpgpassman -- Select a location to back up your passwords")
            if [[ $? -eq 1 ]]; then
                SERVNAME=""
                zenitymain
            fi
            if [ ! -d $SERVNAME ]; then
                mkdir $SERVNAME
                zenity --warning --title=gpgpassman --timeout=5 --text="$SERVNAME directory created for password backup."
            fi
            cp -r $GPMDIR/* $SERVNAME/ || { zenity --error --title=gpgpassman --text="Backup failed!" ; zenitymain ; }
            zenity --warning --title=gpgpassman --timeout=5 --text="Passwords have been backed up to $SERVNAME."
            SERVNAME=""
            zenitymain
            ;;
        Remove*)
            SERVNAME=$(zenity --entry --cancel-label="Main menu" --width=540 --height=460 --title=gpgpassman --text="Remove an encrypted password.\n\nThe password for the service name you enter will be deleted permanently!\nYou will be asked for the gpg encryption password before removal.\n\nPassword storage directory:\n$GPMDIR\n\nManaged services:\n$(dir $GPMDIR)\n\n\n\n\n\nEnter the service name to remove:")
            if [[ $? -eq 1 ]]; then
                SERVNAME=""
                zenitymain
            fi
            zenity --question --title=gpgpassman --text="Passwords cannot be recovered; are you sure you want to remove password for $SERVNAME?" --ok-label="Yes"
            if [[ $? -eq 1 ]]; then
                zenity --warning --title=gpgpassman --text="Password for $SERVNAME was not removed."
                SERVNAME=""
                zenitymain
            else
                echo -n "$(gpg -d $GPMDIR/$SERVNAME/$SERVNAME.gpg)" | xclip -selection c -i
                if [ "$(xclip -selection c -o)" = "" ]; then
                    zenity --error --title=gpgpassman --text="Wrong password or gpg failure!"
                    SERVNAME=""
                    zenitymain "Remove"
                fi
                echo -n "Password cleared from clipboard" | xclip -selection c -i
                rm -rf $GPMDIR/$SERVNAME
                zenity --warning --title=gpgpassman --text="Password for $SERVNAME was removed!"
                SERVNAME=""
                zenitymain
            fi
            ;;
        Change*)
            SERVNAME=$(zenity --file-selection --directory --title="gpgpassman -- Select a new password storage directory")
            if [[ $? -eq 1 ]]; then
                SERVNAME=""
                zenitymain
            fi
            zenity --question --title=gpgpassman --text="Only one directory can be managed by gpgpassman at a time; change password storage directory to $SERVNAME?" --ok-label="Yes"
            if [[ $? -eq 1 ]]; then
                SERVNAME=""
                zenitymain
            fi
            if [ ! -d $SERVNAME ]; then
                mkdir $SERVNAME || { zenity --error --title=gpgpassman --text="Could not create directory!" ; zenitymain ; }
                zenity --warning --title=gpgpassman --timeout=5 --text="$SERVNAME directory created for gpgpassman storage."
            fi
            echo "$SERVNAME" > $GPMCONFDIR/gpgpassman.conf
            zenity --warning --title=gpgpassman --timeout=5 --text="gpgpassman storage directory changed to $(< ~/.config/gpgpassman/gpgpassman.conf)"
            SERVNAME=""
            zenitymain
            ;;
        Generate*)
             programisinstalled "apg"
            if [ "$return" = "1" ]; then
                { echo "Passwords generated using 'apg -a 1 -m 30 -n 4':" ; apg -a 1 -m 30 -n 4 ; } | zenity --text-info --cancel-label=Exit --width=540 --height=460 --title=gpgpassman
                if [[ $? -eq 1 ]]; then
                    exit 0
                fi
                zenitymain
            else
                zenity --error --title=gpgpassman --text="apg is not installed; cannot generate passwords!"
                zenitymain
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
                    SERVNAME=""
                    zenitymain
                fi
            else
                zenity --error --title=gpgpassman --text="'wget' is not installed; cannot check for updates!"
                SERVNAME=""
                zenitymain
            fi
            ;;
        *)
            ZMAINCASE=$(zenity --list --cancel-label=Exit --width=540 --height=460 --title=gpgpassman --text="Welcome to gpgpassman v$GPMVER\n\ngpgpassman is a password manager that uses 'gpg' for encryption.\n\nPassword storage directory:\n$GPMDIR\n\nManaged passwords:\n$(dir $GPMDIR)\n\nWhat would you like to do?" --column="Cases" --hide-header "Add a new encrypted password" "Decrypt a stored password" "Backup your stored passwords" "Remove a stored password" "Change password storage directory" "Generate passwords using 'apg'" "Check for gpgpassman update")
            if [[ $? -eq 1 ]]; then
                exit 0
            fi
            ZHEADLESS="1"
            zenitymain "$ZMAINCASE"
            ;;
    esac
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
                echo "No service name entered; try again."
                SERVNAME=""
                main "add"
            fi
            echo "Input your password for $SERVNAME:"
            read -s PASSINPUT
            echo
            echo "Input password again for $SERVNAME:"
            read -s PASSINPUT2
            echo
            if [ "$PASSINPUT" != "$PASSINPUT2" ]; then
                echo "Passwords do not match; try again!"
                SERVNAME=""
                main "add"
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
                read -p "Input the service name for the password you want to remove: " SERVNAME
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
        gui)
            programisinstalled "zenity"
            if [ $return = "1" ]; then
                zenitymain
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
        exit*|Exit*)
            exit 0
            ;;
        *)
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
    esac
}

if [ ! -f "$GPMCONFDIR/gpgpassman.conf" ]; then
    echo "$GPMCONFDIR does not exist; creating..."
    mkdir $GPMCONFDIR
    mkdir $GPMINITDIR
    echo "$GPMINITDIR" > $GPMCONFDIR/gpgpassman.conf
    zenity --error --text="$GPMCONFDIR created and config file written; rung gpgpassman again." || echo "$GPMCONFDIR created and config file written; run gpgpassman again."
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
