#!/bin/bash
#Auther Daniel Elf
#Description: This is a somple addon for creating and managing users + devices for jump.sh jumpserver.
#Note: This is a very basic/simple script with little to no check of input data... It's assumed that you enter 'real' values
userip=$(echo "$SSH_CLIENT" | cut -d' ' -f 1)
logfile=/var/log/jumpserver.log
dbase=/data/git/JumpServer/database/jumpdb.sq3
blue=$(tput setaf 6)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
red=$(tput setaf 1)
normal=$(tput sgr0) # default color

function mainmenu(){
    clear
    printf "============================\n| ${yellow}Jumpserver Control Panel${normal} |\n============================\n" 
    printf "Current server mode: ${blue}%s${normal}\n" "$(sqlite3 $dbase "select mode from serverstatus;")"   
    printf "\nSelect task:\n"
    COLUMNS=1
    PS3='Please enter your choice: '
    options=("List all devices" "Add a device" "Enable a device" "Disable a device" "List all users" "Add a user" "Delete a user" "Change Server Mode"  "Quit")
    select opt in "${options[@]}"; do
        case $opt in
        "List all devices")
            printf "\n\n== ${yellow}All devices currently in database${normal} ==\n"
            printf "${blue}"
            sqlite3 --header --column $dbase "select * from devices"
            printf "${normal}\n"
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
            printf "\n\n== ${yellow}All users currently in database ${normal}==\n"
            printf "${blue}"
            sqlite3 --header --column $dbase "select * from users"
            printf "${normal}\n"
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
    printf "\n== ${yellow}Adding a new device${normal} ==\n\nTo add a new device we will need the following details: IP, OS, Hostname, User (to login with), Comment, admin_only\n"
    for i in ip os hostname user comment; do 
        read -p "$i: " -e dev${i}
    done

    read -p "Is this device only for admin accounts? (1 or 0): " -e devadmin_only
    if [[ $devadmin_only == "1" || $devadmin_only == "Y" || $devadmin_only == "y" || $devadmin_only == "yes" || $devadmin_only == "Yes" ]]; then
        devadmin_only=1
    else
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
    disdevices=$(sqlite3 $dbase 'select exists (select * from devices where enabled=0)')
    if [[ disdevices -ne 0 ]]; then
         printf "\n\n== ${yellow}ENABLE a device${normal} ==\nBelow are all currently disabled devices:\n"
         sqlite3 --header --column $dbase "select * from devices where enabled=0"
	 printf "\n"
    	 read -p "Enter ID of the device you want to ENABLE: " -e devid
	 sqlite3 $dbase "UPDATE devices SET enabled=1 WHERE id=$devid"
	 printf "Device has been enabled.\n"
    else
	printf "${red}\nError: ${yellow}There are no disabled devices at the moment, so there are no devices to enable.${normal}\n\n"
    fi  
    read -p "Press enter to return to main menu "
    mainmenu

}
function disdevice() {
    enadevices=$(sqlite3 $dbase 'select exists (select * from devices where enabled=1)')
    if [[ enadevices -ne 0 ]]; then
        printf "\n== ${yellow}DISABLE a device${normal} ==\Below are all currently enabled devices\n"
        sqlite3 --header --column $dbase "select * from devices where enabled=1"
        printf "\n"
        read -p "Enter ID of the device you want to DISABLE: " -e devid
        sqlite3 $dbase "UPDATE devices SET enabled=0 WHERE id=$devid"
    else
        printf "${red}\nError: ${yellow}There are no enabled devices at the moment, so there are no devices to disable.${normal}\n\n"
    fi
    read -p "Press enter to return to main menu "
    mainmenu
}

function addusr() {
    printf "\n== ${yellow}Adding a new user${normal} ==\n" 
    for i in username comment; do 
        read -p "$i: " -e usr${i}
    done
    read -p "Is $usrusername an admin account? (1 or 0): " -e usradmin
    if [[ $usradmin -ne "1" ]]; then
        usradmin=0
    fi
    sqlite3 $dbase "INSERT INTO users(username, comment, admin, enabled) VALUES('$usrusername', '$usrcomment', '$usradmin', '1');"
    if [[ $? -ne "0" ]]; then
        printf "${red}Failed to add user${normal} (see error above). Press enter to return to main menu.\n\n"
    else
        printf "${green}Successfully added user!${normal} Press enter to return to main menu.\n\n"
    fi
read -s
mainmenu
}


function delusr() {
    printf "\n== ${yellow}Delete a user${normal} ==\n Here are current users:\n"
    sqlite3 --header --column $dbase "SELECT * FROM users"
    printf "\n"
    read -p "Enter username of the user you want to DELETE (or blank for nobody): " -e usrusername
    if [[ ! -z $usrusername ]]; then
        sqlite3 $dbase "DELETE FROM users WHERE username=$usrusername" 2> /dev/zero
        if [[ $? -eq 0 ]]; then
            read -p "${green}User has been deleted${normal}. Press enter to return to main menu "
        else
            printf "${red}Failed to delete user ${blue}%s${normal}, check username and try again.\n" "$usrusername"
            read -p "Press enter to return to main menu "
        fi
    else
        read -p "No username given. Press enter to return to main menu"
    fi
    mainmenu
}

function changemode(){
    clear
    printf "== ${yellow}See and modify the server mode${normal} ==\n"
    printf "Current mode: ${blue}%s${normal}\n" "$(sqlite3 $dbase "select mode from serverstatus;")"
    COLUMNS=1
    PS3='Please enter your choice: '
    options=("Normal" "Maintenance" "Return to main menu")
    select opt in "${options[@]}"; do
        case $opt in
        "Normal")
            printf "${yellow}Setting server mode to ${green}NORMAL${normal}.\n"
	        sqlite3 $dbase "update serverstatus set mode='Normal', reason='', who='$(whoami)', time='$(date "+%Y-%m-%d %H:%M:%S")' where id=1;"
            printf "%s | IP %s (%s) Changed server mode to NORMAL.\n" "$(date)" "$userip" "$(whoami)" >> $logfile
	        printf "Press enter to return to main menu\n"
	        read 
	        mainmenu
	        ;;
        "Maintenance")
            read -p "Enter maintenance reason: " -e maintreason
            while [[ -z $maintreason ]]; do
                printf "${red}Error:${yellow} You have to enter a maintenance reason.${normal}\n"
                read -p "Enter maintenance reason: " -e maintreason
            done
            sqlite3 $dbase "update serverstatus set mode='Maintenance', reason='$maintreason', who='$(whoami)', time='$(date "+%Y-%m-%d %H:%M:%S")' where id=1;"
            printf "${yellow}Changed server mode to ${red}MAINTENACE${yellow}, user access is now disabled.${normal}\n"
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
