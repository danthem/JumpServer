#!/bin/bash
#Author: Daniel Elf
############# Description ############
#  For initial install / setup of jump server
######################################
blue=$(tput setaf 6)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
red=$(tput setaf 1)
normal=$(tput sgr0) # default color

printf "============================\n| ${yellow}Initial Jumpserver Setup${normal} |\n===========================\n" 
printf "Welcome!\n" 
sleep 0.5
printf "We will now go through the steps of initial setup of the jump server\n"
sleep 1
printf "Together we'll decide where to store the jump/cpanel scripts, where to put the database and where we want to save logs.\n"
sleep 1
printf "This script assumes that you have Internet access and write access to the path(s) chosen.\n"
printf "%s\n" "-----------------------"
sleep 3
printf "Let's start by making sure that we have ${blue}sqlite3${normal}... "
# Check for sqlite3 
which sqlite3 >& /dev/null
if [[ $? -ne 0 ]]; then
    printf "${red}Failed.${yellow} \n\nLooks like this system does not have sqlite3, please install it before proceeding with setup.\n${normal}Exiting.\n\n"
    exit 1
else
    printf "${green}Success.${normal}\n"
fi 
printf "Now let's check for ${blue}wget${normal}... "
# Check for wget
sleep 0.5
which wget >& /dev/null
if [[ $? -ne 0 ]]; then
    printf "${red}Failed.${yellow} \n\nLooks like this system does not have wget please install it before proceeding with setup.\n${normal}\nExiting.\n\n"
    exit 1
else
    printf "${green}Success.${normal}\n"
fi 
sleep 1
printf "\nGreat, looks like we have what we need to proceed!\n\n"
sleep 1
printf "Now we need to decide where to save ${blue}jump.sh${normal} and ${blue}cpanel.sh${normal}.\n"
printf "If the path does not exist, we will create it via mkdir -p.\n"
read -p "Please enter FULL path where to store scripts: " -e scriptpath
printf "Will store scripts in ${blue}%s${normal}\n" "$scriptpath"
mkdir -p "$scriptpath"
if [[ $? -ne 0 ]]; then
    printf "${red}Error${yellow}: Failed to mkdir -p ${blue}%s${normal}\n" "$scriptpath"
    printf "This likely means that you don't have write permissions here, fix this and try again.\n\nExiting.\n\n"
fi
printf "\nThe Jumpserver relies on a database to track devices and users.\nTime to decide where to save the database ${blue}jumpdb.sq3${normal}.\n"
read -p "Please enter FULL path where to store the database: " -e dbasepath
printf "Will store database in ${blue}%s${normal}\n" "$dbasepath"
mkdir -p "$dbasepath"
if [[ $? -ne 0 ]]; then
    printf "${red}Error${yellow}: Failed to mkdir -p ${blue}%s${normal}\n" "$dbasepath"
    printf "This likely means that you don't have write permissions here, fix this and try again.\n\nExiting.\n\n"
fi
printf "\nGreat! The Jumpserver does log multiple types of events.\nWhere do you want to store ${blue}jumpserver.log${normal}?\n"
printf "${yellow}Note:${normal} Only enter the directory path, do not include the \"jumpserver.log\" part.\n"
read -p "Please enter FULL path to the DIRECTORY where to save jumpserver.log: " -e logpath
printf "Will use ${blue}%s/jumpserver.log${normal} as log file\n" "$dbasepath"
mkdir -p "$logpath"
if [[ $? -ne 0 ]]; then
    printf "${red}Error${yellow}: Failed to mkdir -p ${blue}%s${normal}\n" "$logpath"
    printf "This likely means that you don't have write permissions here, fix this and try again.\n\nExiting.\n\n"
fi
touch ${logpath}/jumpserver.log
if [[ $? -ne 0 ]]; then
    printf "${red}Error${yellow}: Failed to create ${blue}%s/jumpserver.log${normal}\n" "$logpath"
    printf "This likely means that you don't have write permissions here, fix this and try again.\n\nExiting.\n\n"
fi
printf "\n\nPerfect.. We now have all the paths:\n"
printf "*jump.sh: ${blue}%s/jump.sh${normal}\n*cpanel.sh: ${blue}%s/cpanel.sh${normal}\n*jumpdb.sq3: ${blue}%s/jumpdb.sq3${normal}\n*jumpserver.log: ${blue}%s/jumpserver.log${normal}\n" "$scriptpath" "$scriptpath" "$dbasepath" "$logpath"
sleep 2
printf "\nTime to download the scripts from github, we're using wget for this.\n"
printf "Downloading ${blue}jump.sh${normal}... "
wget --no-check-certificate -q https://raw.githubusercontent.com/danthem/JumpServer/master/jump.sh -P $scriptpath/ >& /dev/null
if [[ $? -ne 0 ]]; then
    printf "${red}ERROR:${yellow} Failed to download file, check Internet connection and try again.\n\nExiting.\n\n"
    exit 2
fi
printf "${green}Success.\n${normal}Downloading ${blue}cpanel.sh${normal}... "
wget --no-check-certificate -q https://raw.githubusercontent.com/danthem/JumpServer/master/cpanel.sh -P $scriptpath/ >& /dev/null
if [[ $? -ne 0 ]]; then
    printf "${red}ERROR:${yellow} Failed to download file, check Internet connection and try again.\n\nExiting.\n\n"
    exit 2
fi
printf "${green}Success.\n${normal}Downloading ${blue}jumpdb.sq3${normal}... "
wget --no-check-certificate -q https://github.com/danthem/JumpServer/raw/master/database/jumpdb.sq3 -P $dbasepath/ >& /dev/null
if [[ $? -ne 0 ]]; then
    printf "${red}ERROR:${yellow} Failed to download file, check Internet connection and try again.\n\nExiting.\n\n"
    exit 2
fi
printf "${green}Success.\n\n${normal}All required files downloaded successfully.\n"
sleep 0.5
printf "\nWe'll now try to chmod +x jump.sh and cpanel.sh..."
chmod +x $scriptpath/jump.sh $scriptpath/cpanel.sh
sleep 0.5
printf "Done. \n\nTime to update jump.sh and cpanel.sh to be aware of database and log location..."
sed -i "/dbase=/c\dbase=${dbasepath}/jumpdb.sq3" ${scriptpath}/jump.sh
sed -i "/dbase=/c\dbase=${dbasepath}/jumpdb.sq3" ${scriptpath}/cpanel.sh
sed -i "/logfile=/c\logfile=${logpath}/jumpserver.log" ${scriptpath}/jump.sh
sed -i "/logfile=/c\logfile=${logpath}/jumpserver.log" ${scriptpath}/cpanel.sh
sleep 0.5
printf "${green}Done!${normal}\n\n"
sleep 1
printf "Everything is sorted! \nNow you just need to create user(s) and add devices, you can do so from the control panel (${blue}%s/cpanel.sh${normal})\n" "$scriptpath"
printf "\nActually... One final thing. You're running this setup script as ${blue}%s${normal}, if you want we can add you as an admin user right away." "$(whoami)"
printf "\nOtherwise you can manually add user(s) later in the cpanel.sh\n"
read -p "Do you want to add yourself as an admin usr right now? (y/N): " -e autoadduser
if [[ $autoadduser == "1" || $autoadduser == "Y" || $autoadduser == "y" || $autoadduser == "yes" || $autoadduser == "Yes" ]]; then
    sqlite3 $dbasepath/jumpdb.sq3 "INSERT INTO users(username, comment, admin, enabled) VALUES('$(whoami)', 'Added via setup.sh', '1', '1');"
    printf "User ${blue}%s${normal} has been added as an admin user.\n\n" "$(whoami)"
else
    printf "Ok, not adding user ${blue}%s${normal} right now. You can manually add users through the cpanel.sh later.\n" "$(whoami)"
fi
printf "Actually.."
sleep 1
printf " wait.."
sleep 1
printf " one more thing!\n"
sleep 2
printf "I can launch the cpanel for you so that you can add new devices now!\n"
read -p "Do you want to launch the control panel? (y/N): " -e launchcpanel
if [[ $launchcpanel == "1" || $launchcpanel == "Y" || $launchcpanel == "y" || $launchcpanel == "yes" || $launchcpanel == "Yes" ]]; then
    printf "Ok! Off you go...\n\n"
    sleep 2
    bash ${scriptpath}/cpanel.sh
else
    printf "Alright! You can find the cpanel later at %s/cpanel.sh... For now, good bye!\n\n" "$scriptpath"
    sleep 1
fi
printf "\n==== ${yellow}End of Setup${normal} ====\n\n"
