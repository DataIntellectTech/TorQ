#!/bin/bash

#script to terminate a specified TorQ process (standard or custom)
#For now the exit codes are: 
#1:failed to terminate process
#2:process wasnot running
#3:process not found

#only argument is the process name
procname=$1

#the stack a TorQ process is in: its -stackid (torq.sh and launchprocess.sh always pass one), or, for a process started
#by hand without one, the KDBBASEPORT it was started with (on Linux, from /proc/<pid>/environ); empty if it has neither
#(fails if the process has exited in the meantime, a zombie included)
stackof()  {
    local stat args env
    read -r stat args <<< "$(ps -ww -o stat=,args= -p "$1")"
    case $stat in ""|Z*) return 1 ;; esac
    if [[ " $args " == *" -stackid "* ]]; then sed -n 's/.* -stackid \([^ ]*\).*/\1/p' <<< "$args"; return 0; fi
    if [ -e "/proc/$1" ]; then
        env=$(tr '\0' '\n' < "/proc/$1/environ" 2>/dev/null) || return 1
        sed -n 's/^KDBBASEPORT=//p' <<< "$env"
    fi
}

#fn to check if a process is running, returns a non-zero search result for success, returns null for failure
#(found by its torq.q command line, so it does not matter what the q binary is called, among this user's processes, by
#user id as USER is not always set; and only in this stack, as another stack of the same user can use the same names)
findproc()  {
    local pid s
    for pid in $(pgrep -u "$(id -u)" -f "torq\.q .*-procname $1( |$)"); do
        s=$(stackof "$pid") || continue
        if [ "$s" = "$KDBBASEPORT" ]; then echo "$pid"; fi
    done
}

#make sure process is running before attempting to kill it
if [[ -z $(findproc "$procname") ]]; then
    exit 2
else
    #search for PID based on process name
    pr_id=$(findproc "$procname")
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

