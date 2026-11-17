#!/bin/bash

#script to launch a specified TorQ process (standard or custom)
#For now the exit codes are: 
#1:process failed to start
#2:process had already been running

#all defaults have been assigned in the q wrspper script: cloudutils.q
#for each cmd line argument, extract the argument and assign to relevant variable
cnt=0
extra_flag_cnt=0
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
	p )
	    p_arg=${sub_arg_arr[1]}
	    ;;
	* )
	    extra_flag_cnt=$(($extra_flag_cnt + 1))
      	    ;;
    esac
    fi
    cnt=$((cnt+1))	
done

#to deal with any number of extra flags and args, take the last (extra_flag_cnt) arguments from the arg_arr 
extra_arg_arr=" "
i=0
a=$((extra_flag_cnt * -1))
while [ $i -lt "$extra_flag_cnt" ]
do 
    extra_arg_arr+="-"${arg_arr[$(( $a+i ))]}
    i=$(($i + 1))
done

#define the startline
sline="$qcmd_arg ${TORQHOME}/torq.q -stackid ${KDBBASEPORT} -proctype $proctype -procname $procname -U $U_arg -localtime $localtime_arg -p $p_arg $extra_arg_arr"

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
#user id as USER is not always set). A process of that name stops the launch if it is in this stack, or in no stack, as
#it may be this stack's; one in another stack does not, as another stack of the same user can use the same names
findproc()  {
    local pid s
    for pid in $(pgrep -u "$(id -u)" -f "torq\.q .*-procname $1( |$)"); do
        s=$(stackof "$pid") || continue
        if [ "$s" = "$KDBBASEPORT" ] || [ -z "$s" ]; then echo "$pid"; fi
    done
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

