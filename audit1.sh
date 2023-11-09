#!/bin/bash

# Set the color variable
green='\033[0;32m'
red='\033[0;31m'
yellow='\033[0;33m'

# Clear the color
clear='\033[0m'

# Stores the date
date=$(date)
filedate=$(date +"%m_%d_%Y")

# Clear screen
clear

# Takes user input to determine audit 
printf "${yellow}Please select from the following options:${clear} \n1)Full Audit \n2)Audit Summary \n3)Audit Rules Report \n4)Add auditing rules \n"
read audit_level

if [[ $audit_level = 1 ]]; then
    # Prompt the user for a date range
    echo -e "${yellow}***Welcome Auditor***${clear}"
    echo -e "${green}The date is: ${date}${clear}"
    echo "Enter the start date (MM/DD/YYYY): "
    read start_date
    echo "Enter the end date (MM/DD/YYYY): "
    read end_date

    # Sleeps the program for a natural feel
    sleep 2

    # Check for successful logins
    echo -e "${green}Checking for successful logins... ${clear}"
    ausearch -i --start $start_date --end $end_date -m USER_LOGIN --success yes
    
    # Check for failed logins
    echo -e "${green}Checking for ${red}failed logins... ${clear}"
    ausearch -i --start $start_date --end $end_date -m USER_LOGIN --success no

    # Check for successful escalations
    echo -e "${green}Checking for successful authentication... ${clear}"
    ausearch -i --start $start_date --end $end_date -m USER_AUTH --success yes

    # Check for failed escalations
    echo -e "${green}Checking for ${red}failed authentication... ${clear}"
    ausearch -i --start $start_date --end $end_date -m USER_AUTH --success no

    # Check for account lockouts
    echo -e "${green}Checking for account lockouts... ${clear}" 
    ausearch -i --start $start_date --end $end_date -m ACCT_LOCK --success yes
    
    # Check for added users
    echo -e "${green}Checking for added users... ${clear}"
    ausearch -i --start $start_date --end $end_date -m ADD_USER 
    
    # Check for deleted users
    echo -e "${green}Checking for ${red}deleted users... ${clear}"
    ausearch -i --start $start_date --end $end_date -m DEL_USER

    # Check for possible password tampering (requires audit rule 1 below)
    echo -e "${green}Checking for possible password changes... ${clear}"
    ausearch -i -k passwd_changes

    # Check for new directories/links etc
    echo -e "${green}Zipping created directories and links to file... ${clear}" 
    ausearch -k creation | gzip > CreationAudit_"${filedate}".gz

    # Prints commands to file for grep/audit
    echo -e "${green}Zipping executed commands to file... ${clear}"
    ausearch -k allcmds | gzip > CommandAudit_"${filedate}".gz

elif [[ $audit_level = 2 ]]; then
    # Prompt user for date range
    echo -e "${yellow}***Welcome Auditor***${clear}"
    echo -e "${green}The date is: ${date}${clear}"
    echo "Enter the start date (MM/DD/YYYY): "
    read start_date
    echo "Enter the end date (MM/DD/YYYY): "
    read end_date
    
    aureport --start $start_date --end $end_date 00:00:00
    echo -e "${red}***Take note that the end time is 00:00:00!***${clear}" 

elif [[ $audit_level = 3 ]]; then
    # Call up the rules
    auditctl -l

elif [[ $audit_level = 4 ]]; then
    # Clear screen
    clear
    # Adds special audit rules to system
    printf "${yellow}Please select from the following options:${clear} \n1)Enable audit for password changes \n2)Enable auditing for all commands \n"
    
    read rule

        if [[ $rule = 1 ]]; then 
            auditctl -w /etc/passwd -p wa -k passwd_changes

        elif [[ $rule = 2 ]]; then 
            auditctl -a always,exit -F arch=b32 -S execve -F key=allcmds
            auditctl -a always,exit -F arch=b64 -S execve -F key=allcmds
        
        else
            # Fails out of rules addition
            echo -e "${red}Invalid Choice. Please enter a number between 1 and 2.${clear}"
            sleep 3
            fi
    
else
    # Fails out the program
    echo -e "${red}Invalid Choice. Please enter a number between 1 and 3.${clear}"
    sleep 3
fi