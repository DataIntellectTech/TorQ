#!/bin/bash

#script to terminate a specified TorQ process (standard or custom)
#For now the exit codes are: 
#1:failed to terminate process
#2:process wasnot running
#3:process not found

#only argument is the process name
procname=$1

#fn to check if a process is running, returns a non-zero search result for success, returns null for failure
findproc()  {
    pgrep -lf "$1" -u "$USER" | grep -ow "q"
}

#make sure process is running before attempting to kill it
if [[ -z $(findproc "$procname") ]]; then
    exit 2
else
    #search for PID based on process name
    pr_id=$( ps -ef -u $USER | grep "$procname" | awk -v procname="$procname" '{if ($15 == procname)  print $2 }' )
    echo $procname
    echo $pr_id
    #only if this search returns a result do we kill the process
    if [[ $pr_id ]]; then
        kill "$pr_id"

        #check that process has been killed
        temp_exit=$?
        if [ $temp_exit -eq 0 ]; then
            exit 0
        else
            exit 1
        fi
    else
        exit 3
    fi
fi

