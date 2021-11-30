#!/bin/bash

#script to launch a specified TorQ process (standard or custom)
#For now the exit codes are: 
#1:process failed to start
#2:process had already been running

#for each cmd line argument, check if it is in the default set
cnt=0
IFS='-'
read -ra arg_arr <<< "$@"
for arg in "${arg_arr[@]}"
do
    if [ "$cnt" -gt 0 ]; then
    IFS=' '
    read -ra sub_arg_arr <<< "$arg"
    case ${sub_arg_arr[0]} in 
        procname )
	    procname=${sub_arg_arr[1]}
	    ;;
	proctype )
            proctype=${sub_arg_arr[1]}
	    ;;
	U )
	    U_arg=${sub_arg_arr[1]}
	    ;;
	localtime )
	    localtime_arg=${sub_arg_arr[1]}
	    ;;
	qcmd )
	    qcmd_arg=${sub_arg_arr[1]}
	    ;;
	* )
	    other_args=${sub_arg_arr[1]}
      	    ;;
    esac
    fi
    cnt=$((cnt+1))	
done

#set default values
localtime_arg=${localtime_arg:=1}
QCMD=${qcmd_arg:="q"}
other_args=${other_args:=" "}

#define the startline
sline="q ${TORQHOME}/torq.q -stackid ${KDBBASEPORT} -proctype $proctype -procname $procname -U $U_arg -localtime $localtime_arg "

#fn to check if a process is running, returns a non-zero search result for success, returns null for failure
findproc()  {
    pgrep -lf "$1" -u "$USER" | grep -ow "q"
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


