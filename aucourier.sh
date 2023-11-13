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
printf "${yellow}Please select from the following options:${clear} \n1)Full Audit \n2)Audit Summary \n3)Audit Rules Report \n4)Add Auditing Rules \n5)View auditd Configuration \n6)Compress and Save Logs \n7)Remove Old Logs \n"
read audit_level

if [[ $audit_level = 1 ]]; then
    clear
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

    # Check for removable media//grep to remove fprintd
    echo -e "${green}Checking for the use of removable media... ${clear}"
    ausearch -i --start $start_date --end $end_date -k removable-media | grep -0 "/run/media"

    # Check for possible password tampering (requires audit rule 1 below)
    echo -e "${green}Zipping possible password changes... ${clear}"
    ausearch -i --start $start_date --end $end_date -k passwd_changes | gzip > PWChanges_"${filedate}".gz

    # Prints created and new directories/links etc
    echo -e "${green}Zipping created directories and links to file... ${clear}" 
    ausearch --start $start_date --end $end_date -k creation | gzip > CreationAudit_"${filedate}".gz

    # Prints commands to file for grep/audit
    echo -e "${green}Zipping executed commands to file... ${clear}"
    ausearch --start $start_date --end $end_date -k allcmds | gzip > CommandAudit_"${filedate}".gz

elif [[ $audit_level = 2 ]]; then
    # Clear Screen
    clear
    # Prompt user for date range
    echo -e "${yellow}***Welcome Auditor***${clear}"
    echo -e "${green}The date is: ${date}${clear}"
    echo "Enter the start date (MM/DD/YYYY): "
    read start_date
    echo "Enter the end date (MM/DD/YYYY): "
    read end_date
    
    aureport --input-logs --start $start_date --end $end_date 
    echo -e "${red}***Take note that the end time is 23:59:59!***${clear}" 

elif [[ $audit_level = 3 ]]; then
    # Call up the rules
    auditctl -l

elif [[ $audit_level = 4 ]]; then
    # Clear screen
    clear
    # Adds special audit rules to system. Add rule and use Reload Rule to load it perm. 
    printf "${yellow}Please select from the following options:${clear} \n1)Enable audit for password changes \n2)Enable audit for all commands \n3)Enable audit for removable media \nReload Rules \n"
    
    read rule

        if [[ $rule = 1 ]]; then 
            # Should not be needed if using NISPOM Rules 
            echo "-w /etc/shadow -p w -k passwd_changes" >> /etc/audit/rules.d/audit.rules

        elif [[ $rule = 2 ]]; then 
            # Audits commands
            echo "-a always,exit -F arch=b32 -S execve -F key=allcmds" >> /etc/audit/rules.d/audit.rules
            echo "-a always,exit -F arch=b64 -S execve -F key=allcmds" >> /etc/audit/rules.d/audit.rules

	    elif [[ $rule = 3 ]]; then
            # Audits removable media
            echo "-a always,exit -F arch=b64 -S mount -S umount2 -k removable-media" >> /etc/audit/rules.d/audit.rules
	
        elif [[ $rule == "Reload Rules" ]]; then
            # Puts rules into a perm state, check using rules report above (auditctl -l)
            augenrules --load

        else
            # Fails out of rules addition
            echo -e "${red}Invalid Choice. Please enter a number between 1 and 2.${clear}"
            sleep 3

	    fi

elif [[ $audit_level = 5 ]]; then
    # Clear Screen
    clear
    # Cats the audit conf
    cat /etc/audit/auditd.conf

elif [[ $audit_level = 6 ]]; then
    # Clear Screen
    clear
    # Copy and compress logfile
    cp /var/log/audit/audit.log /var/log/audit/${filedate}_audit.bak
    gzip /var/log/audit/${filedate}audit.bak

elif [[ $audit_level = 7 ]]; then
    # Clears logs if yes is typed
    printf "${red}WARNING THIS WILL REMOVE ALL LOGS NOT ARCHIVED, TYPE YES TO CONTINUE${clear}\n"
    read permission
    
        if [[ $permission = YES ]];then
            #truncate log to zero size
            truncate -s 0 /var/log/audit/audit.log
        else
            #fails out
            echo -e "${red}INVALID${clear}"
    
        fi

else
    # Fails out the program
    echo -e "${red}Invalid Choice. Please enter a number between 1 and 7.${clear}"
    sleep 3
fi
