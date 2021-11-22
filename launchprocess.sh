#!/bin/bash
#script to launch a specified TorQ process (standard or custom)
#For now the exit codes are: 
#1:procname/proctype not provided
#2:process failed to start
#3:process had already been running

#for each cmd line argument, check if it is in the default set
cnt=0
IFS='-'
read -ra arg_arr <<< "$@"
if [ "${arg_arr[1]:0:8}" == "procname" ] && [ "${arg_arr[2]:0:8}" == "proctype" ]; then
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
else 
    echo "Error: First two parameters must be procname and proctype"
    exit 1
fi

#set default values
localtime_arg=${localtime_arg:=1}
qcmd_arg=${qcmd_arg:="q"}
other_args=${other_args:=" "}

#define the startline
sline="q ${TORQHOME}/torq.q -stackid ${KDBBASEPORT} -proctype $proctype -procname $procname -U $U_arg -localtime $localtime_arg "

#fn to check if a process is running, returns a non-zero search result for success, returns null for failure
findproc()  {
    pgrep -lf "$1" -u "$USER" | grep -ow "q"
}

#check process isn't already running before attempting to start it
if [[ -z $(findproc "$procname") ]]; then
    echo "Starting " "$procname"
    #run process in background and redirect input & output 
    eval "nohup $sline </dev/null >${KDBLOG}/torq${procname}.txt 2>&1 &"

    #check exit code of nohup $sline to make sure process is starting successfully
    temp=$?
    if [ $temp -eq 0 ]; then
        echo "Successfully started: " "$procname"
    else
        echo "Error: ""$procname" "failed to start"
        exit 2
    fi
else
    echo "Error: " "$procname" "already running"
    exit 3
fi


