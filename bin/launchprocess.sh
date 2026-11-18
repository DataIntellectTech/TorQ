#!/bin/bash

#script to launch a specified TorQ process (standard or custom)
#For now the exit codes are: 
#1:process failed to start
#2:process had already been running

#all defaults have been assigned in the q wrspper script: cloudutils.q
#for each cmd line argument (-name followed by its value, which can be several words), assign it to the relevant variable
#and keep any other flag, with its value, for the start line
#(this used to split the whole line on '-', so a value with a '-' in it, such as a path, broke every argument after it)
extra_arg_arr=""
while [ $# -gt 0 ]; do
    key=${1#-}; shift; val=""
    while [ $# -gt 0 ] && [ "${1:0:1}" != "-" ]; do val="${val:+$val }$1"; shift; done
    case $key in
        procname ) procname=$val ;;
        proctype ) proctype=$val ;;
        U ) U_arg=$val ;;
        localtime ) localtime_arg=$val ;;
        qcmd ) qcmd_arg=$val ;;
        p ) p_arg=$val ;;
        * ) extra_arg_arr+=" -$key${val:+ $val}" ;;
    esac
done

#define the startline
sline="$qcmd_arg ${TORQHOME}/torq.q -stackid ${KDBBASEPORT} -proctype $proctype -procname $procname -U $U_arg -localtime $localtime_arg -p $p_arg $extra_arg_arr"

#fn to check if a process is running, returns a non-zero search result for success, returns null for failure
findproc()  {
    pgrep -lf "$1" -u "$USER" | grep -ow "$qcmd_arg"
}

#check process isn't already running before attempting to start it
if [[ -z $(findproc "$procname") ]]; then
    #run process in background and redirect input & output 
    eval "nohup $sline </dev/null >${KDBLOG}/torq${procname}.txt 2>&1 &"
    
    #check exit code of nohup $sline to make sure process is starting successfully
    temp_exit=$?
    if [ $temp_exit -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
else
    exit 2
fi

