#!/bin/bash
#Author: Daniel Elf
#Update: 05/06/2019
############# Description ############
#   For easy jumping from my 'jump' server to other VMs / Isilon clusters.
#   
#   Always tries to SSH as user root, modify as needed.
######################################
#Syntax: ./jump.sh   (but can be configured to run as 'shell' for a jump-user)
dbase=/data/git/JumpServer/database/jumpdb.sq3
logfile=/var/log/jumpserver.log
# vars that can be used to change font color
blue=$(tput setaf 6)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
red=$(tput setaf 1)
normal=$(tput sgr0) # default color


function listdevs(){
    #Does user exist and is enabled? 
    userexist=$(sqlite3 $dbase "select EXISTS (select * from users where username=\"$(whoami)\" COLLATE NOCASE AND enabled=1);")
    if [[ $userexist -ne 1 ]]; then
	    printf "\n${red}User ${blue}%s${red} does not exist in database or has been disabled. Access to jump server is denied. \n${yellow}This incident has been logged.${normal}\n\n" "$(whoami)"
	    printf "%s | IP %s Tried to run script as \"%s\" but user does not exist or is not enabled in DB\n" "$(date)" "$(echo "$SSH_CLIENT" | cut -d' ' -f 1)" "$(whoami)" >> $logfile
	    exit 1
    fi
    #Is user an admin account? If so read in all devices, else read all devices where admin_only=0
    isadmin=$(sqlite3 $dbase "select EXISTS (select * from users where username=\"$(whoami)\" COLLATE NOCASE AND admin=1);")
    if [[ $isadmin -eq 1 ]]; then
        readarray -t "devices" <<< $(sqlite3 -list -separator " | " $dbase "select os, comment, ip from devices where enabled=1 order by os desc;")
        printf "${green} >>> Admin user detected${normal}\n"
    else
        readarray -t "devices" <<< $(sqlite3 -list -separator " | " $dbase "select os, comment, ip from devices where enabled=1 and admin_only=0 order by os desc;")
    fi
    devselect
}

function devselect(){
    #Function functionality: Let user decide which device they want to "jump" to
    # Set terminal title bar:
    echo -ne "\033]0;Jump Server\007"
    clear
    printf "================================\n| ${yellow}Daniel's Awesome Jump Server${normal} |\n================================\n"
    printf "\n${yellow}Note: ${normal}Activity on this jump server is logged.\n" 
    printf "\n"
    if [[ $isadmin -eq 1 ]]; then
        printf "${green} >>> Admin user detected${normal}\n"
    fi
    COLUMNS=1
    PS3='Which device do you want to jump to?: '
    select opt in "${devices[@]}"
    do [[ -n $opt ]] || { echo "Invalid choice. Please try again." >&2; continue; }
        printf "\nVerifying connection to device... "
        #get dev IP
        sship=$(echo $opt | awk '{print $NF}')
        # Do a quick ping check to see if device is online before attempting to connect
	ping -W2 -c1 $sship >& /dev/null
        if [[ $? -ne "0" ]]; then
            printf "%s | IP %s (%s) Attempted connection to device %s, but device is DOWN\n" "$(date)" "$(echo "$SSH_CLIENT" | cut -d' ' -f 1)" "$(whoami)" "$sship" >> $logfile
            printf "[${red}Failed${normal}]\n"
            printf "${red}Error:${yellow} Looks like ${blue}%s${yellow} is not online :(\n\n${normal}Press Enter to return to jump server...\n\n" "$opt"
            read -s -p ""
        else
            printf "%s | IP %s (%s) Connected to device %s\n" "$(date)" "$(echo "$SSH_CLIENT" | cut -d' ' -f 1)" "$(whoami)" "$sship" >> $logfile
            #get ssh user
            sshuser=$(sqlite3 $dbase "select user from devices where ip=\"$sship\"")
            printf "[${green}OK${normal}]\nOff you go! SSH'ing to to target (${blue}%s${normal})!\n\n%s\n${yellow}'exit' or CTRL+D to return to jump server ${normal}\n%s\n\n" "$opt" "-----------------------" "-----------------------"
            echo -ne "\033]0;$opt\007"
            ssh $sshuser@$sship
            printf "%s | IP %s (%s) Disconnected from device %s\n" "$(date)" "$(echo "$SSH_CLIENT" | cut -d' ' -f 1)" "$(whoami)" "$sship" >> $logfile
        fi
	devselect
    done
}

printf "%s | IP %s (%s) Connected to the jump server\n" "$(date)" "$(echo "$SSH_CLIENT" | cut -d' ' -f 1)" "$(whoami)" >> $logfile
clear
listdevs
