#!/bin/bash
#Auther Daniel Elf
#Description: This is a very basic addon for creating and managing users + devices for jump.sh jumpserver.
#Note: This is a very basic/simple script with little to no check of input data... It's assumed that you enter 'real' values
userip=$(echo "$SSH_CLIENT" | cut -d' ' -f 1)
logfile=/var/log/jumpserver.log
dbase=/data/git/JumpServer/database/jumpdb.sq3

function mainmenu(){
    clear
    printf "==== Control panel for administrating devices and users for the jumpserver ====\n"
    printf "\nSelect task:\n"
    COLUMNS=1
    PS3='Please enter your choice: '
    options=("List all devices" "Add a device" "Enable a device" "Disable a device" "List all users" "Add a user" "Delete a user" "Change Server Mode"  "Quit")
    select opt in "${options[@]}"; do
        case $opt in
        "List all devices")
            printf "\n\nListing all devices currently in database:\n"
            sqlite3 --header --column $dbase "select * from devices"
            read -p "Press enter to return to main menu "
            mainmenu
            ;;
        "Add a device")
            adddevice
            ;;
        "Enable a device")
            enadevice
            ;;
        "Disable a device")
            disdevice
            ;;
        "List all users")
            printf "\n\nListing all users currently in database:\n"
            sqlite3 --header --column $dbase "select * from users"
            read -p "Press enter to return to main menu "
            mainmenu
            ;;
        "Add a user")
            addusr
            ;;
        "Delete a user")
            delusr
            ;;
        "Change Server Mode")
            changemode
            ;;
        "Quit")
            exit 0
            ;;
        *) echo invalid option;;
    esac
    done
}

function adddevice() { 
#(id INTEGER PRIMARY KEY, ip TEXT NOT NULL UNIQUE, os TEXT NOT NULL, hostname TEXT NOT NULL UNIQUE, user TEXT NOT NULL, comment TEXT, admin_only INTEGER NOT NULL DEFAULT 0, enabled INTEGER NOT NULL DEFAULT 1);
    printf "\n== Adding a new device ==\n\nTo add a new device we will need the following details: IP, OS, Hostname, User, Comment, admin_only\n"
    for i in ip os hostname user comment; do 
        read -p "$i: " -e dev${i}
    done

    read -p "Is this device only for admin accounts? (1 or 0): " -e devadmin_only
    if [[ $devadmin_only -ne "1" ]]; then
        devadmin_only=0
    fi

sqlite3 $dbase "INSERT INTO devices(ip, os, hostname, user, comment, admin_only, enabled) VALUES('$devip', '$devos', '$devhostname', '$devuser', '$devcomment', '$devadmin_only', '1');"
if [[ $? -ne "0" ]]; then
    printf "Failed to add device (see error above). Press enter to return to main menu.\n\n"
else
    printf "Successfully added device! Press enter to return to main menu.\n\n"
fi
read -s
mainmenu
}

function enadevice() {
    printf "\n== ENABLE a device ==\nFirst we'll list all currently disabled devices.\n"
    sqlite3 --header --column $dbase "select * from devices where enabled=0"
    read -p "Enter ID of the device you want to ENABLE: " -e devid
    sqlite3 $dbase "UPDATE devices SET enabled=1 WHERE id=$devid"
    read -p "Device enabled. Press enter to return to main menu "
    mainmenu

}
function disdevice() {
    printf "\n== Disable a device ==\nFirst we'll list all currently enabled devices\n"
    sqlite3 --header --column $dbase "select * from devices where enabled=1"
    printf "\n"
    read -p "Enter ID of the device you want to DISABLE: " -e devid
    sqlite3 $dbase "UPDATE devices SET enabled=0 WHERE id=$devid"
    read -p "Device disabled. Press enter to return to main menu "
    mainmenu
}

function addusr() {
    printf "\n== Adding a new user ==\n" 
    for i in username comment; do 
        read -p "$i: " -e usr${i}
    done
    read -p "Is $usrusername an admin account? (1 or 0): " -e usradmin
    if [[ $usradmin -ne "1" ]]; then
        usradmin=0
    fi
    sqlite3 $dbase "INSERT INTO users(username, comment, admin, enabled) VALUES('$usrusername', '$usrcomment', '$usradmin', '1');"
    if [[ $? -ne "0" ]]; then
        printf "Failed to user device (see error above). Press enter to return to main menu.\n\n"
    else
        printf "Successfully added user! Press enter to return to main menu.\n\n"
    fi
read -s
mainmenu
}


function delusr() {
    printf "\n== Delete a user ==\n First we'll list all users, then just enter the username you want to delete\n"
    sqlite3 --header --column $dbase "SELECT * FROM users"
    printf "\n"
    read -p "Enter username of the user you want to DELETE: " -e usrusername
    if [[ ! -z $usrusername ]]; then
        sqlite3 $dbase "DELETE FROM users WHERE username=$usrusername"
        read -p "Device disabled. Press enter to return to main menu "
    else
        read -p "No username given. Press enter to return to main menu"
    fi
    mainmenu
}

function changemode(){
    clear
    printf "\n== See and modify the server mode ==\n"
    printf "Current mode: %s\n" "$(sqlite3 $dbase "select mode from serverstatus;")"
    COLUMNS=1
    PS3='Please enter your choice: '
    options=("Normal" "Maintenance" "Return to main menu")
    select opt in "${options[@]}"; do
        case $opt in
        "Normal")
            printf "Setting server mode to NORMAL.\n"
	        sqlite3 $dbase "update serverstatus set mode='Normal', reason='', who='$(whoami)', time='$(date "+%Y-%m-%d %H:%M:%S")' where id=1;"
            printf "%s | IP %s (%s) Changed server mode to NORMAL.\n" "$(date)" "$userip" "$(whoami)" >> $logfile
	        printf "Press enter to return to main menu\n"
	        read 
	        mainmenu
	        ;;
        "Maintenance")
           read -p "Enter maintenance reason: " -e maintreason
            sqlite3 $dbase "update serverstatus set mode='Maintenance', reason='$maintreason', who='$(whoami)', time='$(date "+%Y-%m-%d %H:%M:%S")' where id=1;"
            printf "Changed server mode to MAINTENACE, user access is now disabled.\n"
            printf "%s | IP %s (%s) Changed server mode to MAINTENANCE. Reason: %s\n" "$(date)" "$userip" "$(whoami)" "$maintreason" >> $logfile
            printf "Press enter to return to main menu\n"
            read
            mainmenu
	        ;;
        "Return to main menu")
            mainmenu
            ;;
        *) echo invalid option;;
    esac
    done
}



#Check and make sure that dbase and logfile exists. Else throw error and tell user to update locations.
if [[ ! -f $dbase || ! -f $logfile ]]; then
    printf "\n!! Error !! Database and/or logfile not found. Update variables in script to reflect actual locations.\n"
    printf "== Currently set paths ==\n dbase: %s \n logfile: %s\n\nExiting script.\n" "$dbase" $logfile
    exit 1
fi

printf "%s | IP %s (%s) Connected to the control panel\n" "$(date)" "$userip" "$(whoami)" >> $logfile
mainmenu
