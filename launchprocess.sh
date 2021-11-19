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
	    g )
		g_arg=${sub_arg_arr[1]}
		;;
	    T )
		T_arg=${sub_arg_arr[1]}
		;;
	    w )
		w_arg=${sub_arg_arr[1]}
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
U_arg=${U_arg:=0}
localtime_arg=${localtime_arg:=0}
g_arg=${g_arg:=0}
T_arg=${T_arg:=0}
w_arg=${w_arg:=0}
qcmd_arg=${qcmd:="q"}
other_args=${other_args:=" "}

#may be able to just assume that all the relevant env vars are defined but just in case:
if [ "-bash" = $0 ]; then
  dirpath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  dirpath="$(cd "$(dirname "$0")" && pwd)"
fi

if [ -z $SETENV ]; then
  SETENV=${dirpath}/setenv.sh                                                                       # set environment if not predefined
fi

if [ -f $SETENV ]; then
    . $SETENV
else
    echo "Error1"
fi

#define the startline
sline="q ${TORQHOME}/torq.q -stackid ${KDBBASEPORT} -proctype "$proctype" -procname "$procname" -U "$U_arg" -localtime "$localtime_arg" -g "$g_arg" -T "$T_arg" -w "$w_arg" "


#fn to check if a process is running, returns a non-zero search result for success, returns null for failure
findproc()  {
    pgrep -lf "$1" -u $USER | grep -ow "q"
}


#check process isn't already running before attempting to start it
if [[ -z $(findproc "$procname") ]]; then
    echo "Starting " "$procname"
    #run process in background and redirect input & output 
    eval "nohup $sline </dev/null >${KDBLOG}/torq${1}.txt 2>&1 &"

    #after 3s check if the process is running
    sleep 3s
    if [ "$(findproc "$procname")" ]; then
        echo "Successfully started: " "$procname"
    else
        echo "Error: ""$procname" "failed to start"
        exit 2
    fi
else
    echo "Error: " "$procname" "already running"
    exit 3
fi


